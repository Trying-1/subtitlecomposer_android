package com.example.typgraphyeditor

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
    private var bgColor: Int = 0xFF000000.toInt()
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

    init {
        surfaceTexture.setDefaultBufferSize(width, height)
    }

    fun setClips(newClips: List<SubtitleClip>) {
        synchronized(clips) {
            clips.clear()
            clips.addAll(newClips)
        }
    }

    fun seekTo(timeMs: Long) {
        currentTimeMs = timeMs
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
            drawFrame()
            try {
                Thread.sleep(16) // ~60fps
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

    private fun drawFrame() {
        if (sizeChanged) {
            surfaceTexture.setDefaultBufferSize(currentWidth, currentHeight)
            subtitleRenderer?.updateSize(currentWidth, currentHeight)
            // Force a viewport reset to full surface for the clear
            GLES20.glViewport(0, 0, currentWidth, currentHeight)
            sizeChanged = false
        }

        val r = (bgColor shr 16 and 0xFF) / 255f
        val g = (bgColor shr 8 and 0xFF) / 255f
        val b = (bgColor and 0xFF) / 255f
        val a = (bgColor shr 24 and 0xFF) / 255f
        
        android.util.Log.d("TypographyRenderer", "Clearing with: $r, $g, $b, $a at ${currentWidth}x${currentHeight}")

        GLES20.glClearColor(r, g, b, a)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)

        backgroundRenderer?.setImage(backgroundImagePath)
        backgroundRenderer?.setTransform(bgScale, bgRotation, bgX, bgY, bgFillMode, currentWidth, currentHeight)
        backgroundRenderer?.draw()

        GLES20.glViewport(0, 0, currentWidth, currentHeight)

        renderSubtitles()

        EGL14.eglSwapBuffers(eglDisplay, eglSurface)
    }

    private fun renderSubtitles() {
        val activeClips = synchronized(clips) {
            clips.filter { clip: SubtitleClip -> currentTimeMs in clip.startTime..clip.endTime }
        }

        for (clip in activeClips) {
            val animState = AnimationEvaluator.evaluate(clip, currentTimeMs)
            subtitleRenderer?.drawTextClip(clip, animState, assetManager)
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
