package com.example.typgraphyeditor

import android.media.*
import android.opengl.*
import android.view.Surface
import java.io.File
import java.nio.ByteBuffer

class VideoExporter(
    private val fileDescriptor: java.io.FileDescriptor,
    private val width: Int,
    private val height: Int,
    private val bitrate: Int = 5000000,
    private val frameRate: Int = 30,
    private val clips: List<SubtitleClip>,
    private val durationMs: Long,
    private val assetManager: android.content.res.AssetManager,
    private val audioPath: String? = null,
    private val backgroundColor: Int = 0xFF000000.toInt()
) {
    private var encoder: MediaCodec? = null
    private var inputSurface: Surface? = null
    private var muxer: MediaMuxer? = null
    private var trackIndex = -1
    private var audioTrackIndex = -1
    private var isMuxerStarted = false
    
    private var audioExtractor: MediaExtractor? = null
    private var eglDisplay: EGLDisplay? = EGL14.EGL_NO_DISPLAY
    private var eglContext: EGLContext? = EGL14.EGL_NO_CONTEXT
    private var eglSurface: EGLSurface? = EGL14.EGL_NO_SURFACE
    
    private var subtitleRenderer: SubtitleRenderer? = null

    fun export(onProgress: (Float) -> Unit) {
        prepareEncoder()
        prepareGL()
        
        subtitleRenderer = SubtitleRenderer(width, height)
        subtitleRenderer?.init()

        val totalFrames = (durationMs / 1000.0 * frameRate).toInt()
        
        for (i in 0 until totalFrames) {
            val presentationTimeNs = i * 1000000000L / frameRate
            val currentTimeMs = i * 1000L / frameRate
            
            drawFrame(currentTimeMs)
            
            EGLExt.eglPresentationTimeANDROID(eglDisplay, eglSurface, presentationTimeNs)
            EGL14.eglSwapBuffers(eglDisplay, eglSurface)
            
            drainEncoder(false)
            onProgress(i.toFloat() / totalFrames)
        }

        drainEncoder(true)

        // After video is encoding is complete, mux audio
        muxAudio()
        
        release()
    }

    private fun prepareEncoder() {
        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height)
        format.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
        format.setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
        format.setInteger(MediaFormat.KEY_FRAME_RATE, frameRate)
        format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)

        encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        encoder?.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        inputSurface = encoder?.createInputSurface()
        encoder?.start()

        muxer = MediaMuxer(fileDescriptor, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
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
        GLES20.glViewport(0, 0, width, height)
        
        val r = (backgroundColor shr 16 and 0xFF) / 255f
        val g = (backgroundColor shr 8 and 0xFF) / 255f
        val b = (backgroundColor and 0xFF) / 255f
        val a = (backgroundColor shr 24 and 0xFF) / 255f

        GLES20.glClearColor(r, g, b, a)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
        
        val activeClips = clips.filter { clip: SubtitleClip -> currentTimeMs in clip.startTime..clip.endTime }
        for (clip in activeClips) {
            val animState = AnimationEvaluator.evaluate(clip, currentTimeMs)
            subtitleRenderer?.drawTextClip(clip, animState, assetManager)
        }
    }

    private fun drainEncoder(endOfStream: Boolean) {
        if (endOfStream) {
            encoder?.signalEndOfInputStream()
        }

        val bufferInfo = MediaCodec.BufferInfo()
        while (true) {
            val outputBufferIndex = encoder?.dequeueOutputBuffer(bufferInfo, 10000) ?: -1
            if (outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                if (!endOfStream) break
            } else if (outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                val newFormat = encoder?.outputFormat
                trackIndex = muxer?.addTrack(newFormat!!) ?: -1
                
                // Add audio track if available
                if (audioPath != null) {
                    android.util.Log.d("VideoExporter", "Adding audio track from: $audioPath")
                    audioExtractor = MediaExtractor()
                    try {
                        audioExtractor?.setDataSource(audioPath)
                        for (i in 0 until (audioExtractor?.trackCount ?: 0)) {
                            val format = audioExtractor?.getTrackFormat(i)
                            val mime = format?.getString(MediaFormat.KEY_MIME)
                            if (mime?.startsWith("audio/") == true) {
                                audioExtractor?.selectTrack(i)
                                audioTrackIndex = muxer?.addTrack(format) ?: -1
                                android.util.Log.d("VideoExporter", "Audio track added at index: $audioTrackIndex")
                                break
                            }
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("VideoExporter", "Failed to add audio track", e)
                    }
                }
                
                muxer?.start()
                isMuxerStarted = true
            } else if (outputBufferIndex >= 0) {
                val encodedData = encoder?.getOutputBuffer(outputBufferIndex)
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                    bufferInfo.size = 0
                }

                if (bufferInfo.size != 0 && isMuxerStarted) {
                    encodedData?.position(bufferInfo.offset)
                    encodedData?.limit(bufferInfo.offset + bufferInfo.size)
                    muxer?.writeSampleData(trackIndex, encodedData!!, bufferInfo)
                }

                encoder?.releaseOutputBuffer(outputBufferIndex, false)
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
            }
        }
    }

    private fun muxAudio() {
        if (audioExtractor == null || audioTrackIndex == -1 || !isMuxerStarted) {
            android.util.Log.w("VideoExporter", "Skipping audio muxing. Extractor: $audioExtractor, Track: $audioTrackIndex, MuxerStarted: $isMuxerStarted")
            return
        }

        android.util.Log.d("VideoExporter", "Starting audio muxing loop")
        val bufferInfo = MediaCodec.BufferInfo()
        val bufferSize = 256 * 1024
        val byteBuffer = ByteBuffer.allocate(bufferSize)
        var samplesMuxed = 0

        while (true) {
            byteBuffer.clear()
            bufferInfo.offset = 0
            bufferInfo.size = audioExtractor?.readSampleData(byteBuffer, 0) ?: -1
            if (bufferInfo.size < 0) break

            bufferInfo.presentationTimeUs = audioExtractor?.sampleTime ?: 0L
            if (bufferInfo.presentationTimeUs > durationMs * 1000) break
            
            bufferInfo.flags = audioExtractor?.sampleFlags ?: 0
            
            byteBuffer.position(0)
            byteBuffer.limit(bufferInfo.size)
            
            muxer?.writeSampleData(audioTrackIndex, byteBuffer, bufferInfo)
            audioExtractor?.advance()
            samplesMuxed++
        }
        android.util.Log.d("VideoExporter", "Audio muxing finished. Samples muxed: $samplesMuxed")
    }

    private fun release() {
        audioExtractor?.release()
        encoder?.stop()
        encoder?.release()
        try {
            muxer?.stop()
            muxer?.release()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        EGL14.eglMakeCurrent(eglDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
        EGL14.eglDestroySurface(eglDisplay, eglSurface)
        EGL14.eglDestroyContext(eglDisplay, eglContext)
        EGL14.eglTerminate(eglDisplay)
        
        inputSurface?.release()
    }
}
