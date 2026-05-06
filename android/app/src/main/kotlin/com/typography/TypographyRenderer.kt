package com.typography

import android.graphics.*
import android.opengl.*
import io.flutter.view.TextureRegistry

class TypographyRenderer(
    private val surfaceTexture: android.graphics.SurfaceTexture,
    private val width: Int,
    private val height: Int,
    private val assetManager: android.content.res.AssetManager
) : Runnable {
    private var eglDisplay: EGLDisplay? = null
    private var eglContext: EGLContext? = null
    private var eglSurface: EGLSurface? = null
    private var running = true
    private var thread: Thread? = null
    
    private val clips = mutableListOf<SubtitleClip>()
    private var currentTimeMs = 0L
    private var subtitleRenderer: SubtitleRenderer? = null
    private var backgroundRenderer: BackgroundRenderer? = null
    private var bgColor: Int = 0xFFFFFFFF.toInt()
    private var backgroundImagePath: String? = null
    private var bgScale: Float = 1f
    private var bgRotation: Float = 0f
    private var bgX: Float = 0f
    private var bgY: Float = 0f
    private var bgFillMode: Int = 0
    private var aspectRatio: Double = 16.0 / 9.0
    private var currentWidth: Int = width
    private var currentHeight: Int = height
    private var sizeChanged = false
    private var isDirty = true
    private var lastRenderedTime = -1L
    private var isPlaying = false
    private var playbackStartTime = 0L
    private var playbackOffsetTime = 0L

    init {
        surfaceTexture.setDefaultBufferSize(width, height)
    }

    fun setClips(newClips: List<SubtitleClip>) {
        synchronized(clips) {
            clips.clear()
            clips.addAll(newClips)
        }
        isDirty = true
    }

    fun updateSettings(
        ratio: Double, 
        backgroundColor: Int, 
        imagePath: String? = null, 
        width: Int? = null, 
        height: Int? = null,
        bgScale: Float? = null,
        bgRotation: Float? = null,
        bgX: Float? = null,
        bgY: Float? = null,
        bgFillMode: Int? = null
    ) {
        this.aspectRatio = ratio
        this.bgColor = backgroundColor
        this.backgroundImagePath = imagePath
        if (bgScale != null) this.bgScale = bgScale
        if (bgRotation != null) this.bgRotation = bgRotation
        if (bgX != null) this.bgX = bgX
        if (bgY != null) this.bgY = bgY
        if (bgFillMode != null) this.bgFillMode = bgFillMode
        isDirty = true
        
        if (width != null && height != null && (width != currentWidth || height != currentHeight)) {
            currentWidth = width
            currentHeight = height
            sizeChanged = true
        }
    }

    fun start() {
        thread = Thread(this)
        thread?.start()
    }

    fun stop() {
        running = false
        try {
            thread?.join()
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
    }

    override fun run() {
        initGL()
        while (running) {
            val startTime = System.currentTimeMillis()
            drawFrame()
            val endTime = System.currentTimeMillis()
            val elapsed = endTime - startTime
            val sleepTime = (16L - elapsed).coerceAtLeast(1L)
            try {
                Thread.sleep(sleepTime)
            } catch (e: InterruptedException) {
                break
            }
        }
        releaseGL()
    }

    private fun initGL() {
        eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        val version = IntArray(2)
        EGL14.eglInitialize(eglDisplay, version, 0, version, 1)

        val configAttribs = intArrayOf(
            EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
            EGL14.EGL_RED_SIZE, 8,
            EGL14.EGL_GREEN_SIZE, 8,
            EGL14.EGL_BLUE_SIZE, 8,
            EGL14.EGL_ALPHA_SIZE, 8,
            EGL14.EGL_DEPTH_SIZE, 16,
            EGL14.EGL_STENCIL_SIZE, 8,
            EGL14.EGL_NONE
        )
        val configs = arrayOfNulls<EGLConfig>(1)
        val numConfigs = IntArray(1)
        EGL14.eglChooseConfig(eglDisplay, configAttribs, 0, configs, 0, configs.size, numConfigs, 0)
        val config = configs[0]

        val contextAttribs = intArrayOf(
            EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
            EGL14.EGL_NONE
        )
        eglContext = EGL14.eglCreateContext(eglDisplay, config, EGL14.EGL_NO_CONTEXT, contextAttribs, 0)

        val surfaceAttribs = intArrayOf(EGL14.EGL_NONE)
        eglSurface = EGL14.eglCreateWindowSurface(eglDisplay, config, surfaceTexture, surfaceAttribs, 0)

        EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
        
        subtitleRenderer = SubtitleRenderer(width, height)
        subtitleRenderer?.init()
        
        backgroundRenderer = BackgroundRenderer()
        backgroundRenderer?.init()
    }

    fun seekTo(timeMs: Long) {
        if (this.currentTimeMs != timeMs) {
            this.currentTimeMs = timeMs
            if (isPlaying) {
                playbackStartTime = System.currentTimeMillis()
                playbackOffsetTime = timeMs
            }
            isDirty = true
        }
    }

    fun setPlaying(playing: Boolean) {
        if (this.isPlaying != playing) {
            this.isPlaying = playing
            if (playing) {
                playbackStartTime = System.currentTimeMillis()
                playbackOffsetTime = currentTimeMs
            }
            isDirty = true
        }
    }

    private fun drawFrame() {
        if (isPlaying) {
            val elapsed = System.currentTimeMillis() - playbackStartTime
            currentTimeMs = playbackOffsetTime + elapsed
            isDirty = true
        }

        if (!isDirty && currentTimeMs == lastRenderedTime && !sizeChanged) {
            return
        }
        lastRenderedTime = currentTimeMs
        isDirty = false
        if (sizeChanged) {
            surfaceTexture.setDefaultBufferSize(currentWidth, currentHeight)
            sizeChanged = false
        }

        // Calculate aspect-ratio corrected viewport (Letterboxing)
        val surfaceAspect = currentWidth.toFloat() / currentHeight.toFloat()
        val targetAspect = aspectRatio.toFloat()
        
        val viewportWidth: Int
        val viewportHeight: Int
        val viewportX: Int
        val viewportY: Int
        
        if (surfaceAspect > targetAspect) {
            // Surface is wider than target (Pillarbox)
            viewportHeight = currentHeight
            viewportWidth = (currentHeight * targetAspect).toInt()
            viewportX = (currentWidth - viewportWidth) / 2
            viewportY = 0
        } else {
            // Surface is taller than target (Letterbox)
            viewportWidth = currentWidth
            viewportHeight = (currentWidth / targetAspect).toInt()
            viewportX = 0
            viewportY = (currentHeight - viewportHeight) / 2
        }

        // 1. Clear the WHOLE surface with bg color
        GLES20.glViewport(0, 0, currentWidth, currentHeight)
        
        val r = (bgColor shr 16 and 0xFF) / 255f
        val g = (bgColor shr 8 and 0xFF) / 255f
        val b = (bgColor and 0xFF) / 255f
        val a = (bgColor shr 24 and 0xFF) / 255f
        
        GLES20.glClearColor(r, g, b, a)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)

        // 2. Setup the logical viewport for content
        GLES20.glViewport(viewportX, viewportY, viewportWidth, viewportHeight)
        
        // Clearing again within viewport (optional if scissoring is used, but safe)
        GLES20.glClearColor(r, g, b, a)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        backgroundRenderer?.setImage(backgroundImagePath)
        backgroundRenderer?.updateFrame(currentTimeMs)
        // Background renderer should use viewport dimensions for its transform logic
        backgroundRenderer?.setTransform(bgScale, bgRotation, bgX, bgY, bgFillMode, viewportWidth, viewportHeight)
        backgroundRenderer?.draw()

        // Ensure subtitleRenderer knows the correct dimensions for its ortho projection
        subtitleRenderer?.updateSize(viewportWidth, viewportHeight)

        renderSubtitles()

        EGL14.eglSwapBuffers(eglDisplay, eglSurface)
    }

    private fun renderSubtitles() {
        val currentClips = synchronized(clips) {
            clips.toList()
        }
        
        val activeClips = currentClips.filter { clip: SubtitleClip -> currentTimeMs in clip.startTime..clip.endTime }

        for (clip in activeClips) {
            val animState = AnimationEvaluator.evaluate(clip, currentTimeMs)
            if (clip.isText) {
                subtitleRenderer?.drawTextClip(clip, animState, assetManager)
            } else {
                subtitleRenderer?.drawImageClip(clip, animState, currentTimeMs)
            }
        }
    }

    private fun releaseGL() {
        if (eglDisplay != EGL14.EGL_NO_DISPLAY) {
            EGL14.eglMakeCurrent(eglDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
            EGL14.eglDestroySurface(eglDisplay, eglSurface)
            EGL14.eglDestroyContext(eglDisplay, eglContext)
            EGL14.eglTerminate(eglDisplay)
        }
    }
}
