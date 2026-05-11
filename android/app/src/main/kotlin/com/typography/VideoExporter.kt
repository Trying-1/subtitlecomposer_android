package com.typography

import android.media.*
import android.opengl.*
import android.util.Log
import android.view.Surface
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

class VideoExporter(
    private val outputPath: String,
    private val width: Int,
    private val height: Int,
    private val bitrate: Int = 10000000, // 10Mbps for high quality
    private val frameRate: Int = 30,
    private val clips: List<SubtitleClip>,
    private val durationMs: Long,
    private val assetManager: android.content.res.AssetManager,
    private val backgroundColor: Int = 0xFFFFFFFF.toInt(),
    private val backgroundImagePath: String? = null,
    private val bgScale: Float = 1f,
    private val bgRotation: Float = 0f,
    private val bgX: Float = 0f,
    private val bgY: Float = 0f,
    private val bgFillMode: Int = 0,
    private val aspectRatio: Double = 16.0 / 9.0
) {
    private var encoder: MediaCodec? = null
    private var inputSurface: Surface? = null
    private var muxer: MediaMuxer? = null
    private var trackIndex = -1
    private val isMuxerStarted = AtomicBoolean(false)
    private val isEncoderDone = AtomicBoolean(false)
    
    private var eglDisplay: EGLDisplay? = EGL14.EGL_NO_DISPLAY
    private var eglContext: EGLContext? = EGL14.EGL_NO_CONTEXT
    private var eglSurface: EGLSurface? = EGL14.EGL_NO_SURFACE
    
    private var subtitleRenderer: SubtitleRenderer? = null
    private var backgroundRenderer: BackgroundRenderer? = null

    fun export(onProgress: (Float) -> Unit) {
        try {
            prepareEncoder()
            prepareGL()
            
            subtitleRenderer = SubtitleRenderer(width, height)
            subtitleRenderer?.init()

            backgroundRenderer = BackgroundRenderer()
            backgroundRenderer?.init()
            backgroundRenderer?.setImage(backgroundImagePath)

            val totalFrames = (durationMs / 1000.0 * frameRate).toInt()
            
            for (i in 0 until totalFrames) {
                val presentationTimeNs = i * 1000000000L / frameRate
                val currentTimeMs = (i * 1000L / frameRate)
                
                drawFrame(currentTimeMs)
                
                EGLExt.eglPresentationTimeANDROID(eglDisplay, eglSurface, presentationTimeNs)
                EGL14.eglSwapBuffers(eglDisplay, eglSurface)
                
                onProgress(i.toFloat() / totalFrames)
            }

            // Signal End of Stream
            encoder?.signalEndOfInputStream()
            
            // Wait for encoder to finish processing all frames
            var waitCount = 0
            while (!isEncoderDone.get() && waitCount < 100) {
                Thread.sleep(50)
                waitCount++
            }
            
        } catch (e: Exception) {
            Log.e("VideoExporter", "Export failed: ${e.message}")
        } finally {
            release()
        }
    }

    private fun prepareEncoder() {
        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height)
        
        // High Profile & VBR for Pro Quality
        format.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
        format.setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
        format.setInteger(MediaFormat.KEY_BITRATE_MODE, MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR)
        format.setInteger(MediaFormat.KEY_FRAME_RATE, frameRate)
        format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1) // Keyframe every second for social media compatibility
        
        // Attempt to set High Profile
        format.setInteger(MediaFormat.KEY_PROFILE, MediaCodecInfo.CodecProfileLevel.AVCProfileHigh)
        format.setInteger(MediaFormat.KEY_LEVEL, MediaCodecInfo.CodecProfileLevel.AVCLevel4)

        encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        
        // Use ASYNC mode for maximum performance
        encoder?.setCallback(object : MediaCodec.Callback() {
            override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {}

            override fun onOutputBufferAvailable(codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo) {
                if (index < 0) return
                
                val encodedData = codec.getOutputBuffer(index) ?: return
                if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                    info.size = 0
                }

                if (info.size != 0 && isMuxerStarted.get()) {
                    encodedData.position(info.offset)
                    encodedData.limit(info.offset + info.size)
                    muxer?.writeSampleData(trackIndex, encodedData, info)
                }

                codec.releaseOutputBuffer(index, false)
                
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    isEncoderDone.set(true)
                }
            }

            override fun onError(codec: MediaCodec, e: MediaCodec.CodecException) {
                Log.e("VideoExporter", "Encoder error: ${e.message}")
            }

            override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) {
                if (isMuxerStarted.get()) return
                trackIndex = muxer?.addTrack(format) ?: -1
                muxer?.start()
                isMuxerStarted.set(true)
            }
        })

        encoder?.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        inputSurface = encoder?.createInputSurface()
        encoder?.start()

        muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    }

    private fun prepareGL() {
        eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        val version = IntArray(2)
        EGL14.eglInitialize(eglDisplay, version, 0, version, 1)

        val configAttribs = intArrayOf(
            EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
            EGL14.EGL_RED_SIZE, 8,
            EGL14.EGL_GREEN_SIZE, 8,
            EGL14.EGL_BLUE_SIZE, 8,
            EGL14.EGL_ALPHA_SIZE, 8,
            0x3142, 1, // EGL_RECORDABLE_ANDROID hint
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
        eglSurface = EGL14.eglCreateWindowSurface(eglDisplay, config, inputSurface, surfaceAttribs, 0)

        EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)
    }

    private fun drawFrame(currentTimeMs: Long) {
        // Calculate aspect-ratio corrected viewport (Letterboxing)
        val surfaceAspect = width.toFloat() / height.toFloat()
        val targetAspect = aspectRatio.toFloat()
        
        val viewportWidth: Int
        val viewportHeight: Int
        val viewportX: Int
        val viewportY: Int
        
        if (surfaceAspect > targetAspect) {
            // Surface is wider than target (Pillarbox)
            viewportHeight = height
            viewportWidth = (height * targetAspect).toInt()
            viewportX = (width - viewportWidth) / 2
            viewportY = 0
        } else {
            // Surface is taller than target (Letterbox)
            viewportWidth = width
            viewportHeight = (width / targetAspect).toInt()
            viewportX = 0
            viewportY = (height - viewportHeight) / 2
        }

        // 1. Clear the WHOLE frame with black (or bg color)
        GLES20.glViewport(0, 0, width, height)
        GLES20.glClearColor(0f, 0f, 0f, 1f) 
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        // 2. Setup the logical viewport for content
        GLES20.glViewport(viewportX, viewportY, viewportWidth, viewportHeight)
        
        val r = (backgroundColor shr 16 and 0xFF) / 255f
        val g = (backgroundColor shr 8 and 0xFF) / 255f
        val b = (backgroundColor and 0xFF) / 255f
        val a = (backgroundColor shr 24 and 0xFF) / 255f

        GLES20.glClearColor(r, g, b, a)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        
        backgroundRenderer?.updateFrame(currentTimeMs, 10000L)
        backgroundRenderer?.setTransform(bgScale, bgRotation, bgX, bgY, bgFillMode, viewportWidth, viewportHeight)
        backgroundRenderer?.draw()
        
        subtitleRenderer?.updateSize(viewportWidth, viewportHeight)
        
        val activeClips = clips.filter { it.startTime <= currentTimeMs && it.endTime >= currentTimeMs }
            .sortedWith(compareBy(
                { if (it.isBackground) 0 else 1 },
                { if (it.isText) 1 else 0 }
            ))
        for (clip in activeClips) {
            val animState = AnimationEvaluator.evaluate(clip, currentTimeMs)
            if (clip.isText) {
                subtitleRenderer?.drawTextClip(clip, animState, assetManager)
            } else {
                subtitleRenderer?.drawImageClip(clip, animState, currentTimeMs, 10000L)
            }
        }
    }

    private fun release() {
        try {
            encoder?.stop()
        } catch (e: Exception) {}
        encoder?.release()
        
        try {
            if (isMuxerStarted.get()) {
                muxer?.stop()
            }
        } catch (e: Exception) {}
        muxer?.release()
        
        if (eglDisplay != EGL14.EGL_NO_DISPLAY) {
            EGL14.eglMakeCurrent(eglDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
            EGL14.eglDestroySurface(eglDisplay, eglSurface)
            EGL14.eglDestroyContext(eglDisplay, eglContext)
            EGL14.eglTerminate(eglDisplay)
        }
        
        inputSurface?.release()
        subtitleRenderer?.clearCache()
    }
}
