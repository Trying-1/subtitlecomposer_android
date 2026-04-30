package com.example.typgraphyeditor

import android.graphics.SurfaceTexture
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.util.Log
import android.view.Surface

class HardwareVideoDecoder {
    private var extractor: MediaExtractor? = null
    private var codec: MediaCodec? = null
    private var surfaceTexture: SurfaceTexture? = null
    private var surface: Surface? = null
    private var textureId: Int = -1
    
    private var width: Int = 0
    private var height: Int = 0
    private var durationMs: Long = 0
    private var lastRenderedTimeUs: Long = -1
    
    fun init(path: String): Boolean {
        try {
            extractor = MediaExtractor()
            extractor?.setDataSource(path)
            
            val trackIndex = selectVideoTrack(extractor!!)
            if (trackIndex < 0) return false
            
            extractor?.selectTrack(trackIndex)
            val format = extractor?.getTrackFormat(trackIndex)!!
            width = format.getInteger(MediaFormat.KEY_WIDTH)
            height = format.getInteger(MediaFormat.KEY_HEIGHT)
            durationMs = if (format.containsKey(MediaFormat.KEY_DURATION)) format.getLong(MediaFormat.KEY_DURATION) / 1000 else 0
            
            val mime = format.getString(MediaFormat.KEY_MIME)!!
            codec = MediaCodec.createDecoderByType(mime)
            
            // Create OES Texture
            val tex = IntArray(1)
            GLES20.glGenTextures(1, tex, 0)
            textureId = tex[0]
            GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
            
            surfaceTexture = SurfaceTexture(textureId)
            surface = Surface(surfaceTexture)
            
            codec?.configure(format, surface, null, 0)
            codec?.start()
            
            return true
        } catch (e: Exception) {
            Log.e("HardwareVideoDecoder", "Init failed: ${e.message}")
            return false
        }
    }

    private fun selectVideoTrack(extractor: MediaExtractor): Int {
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("video/") == true) return i
        }
        return -1
    }

    fun updateFrame(timeMs: Long, timeoutUs: Long = 0): Boolean {
        val codec = codec ?: return false
        val extractor = extractor ?: return false
        val targetUs = timeMs * 1000
        
        if (Math.abs(targetUs - lastRenderedTimeUs) < 8000) return true

        try {
            var isSeek = false
            if (targetUs < lastRenderedTimeUs - 33000 || targetUs - lastRenderedTimeUs > 250000) {
                extractor.seekTo(targetUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
                codec.flush()
                lastRenderedTimeUs = -1
                isSeek = true
            }

            val info = MediaCodec.BufferInfo()
            var found = false
            
            // Pro-logic: Adaptive timeout
            // If we are seeking or exporting, we wait longer. 
            // If we are just playing, we use a tiny 1ms (1000us) safety margin.
            val effectiveTimeout = when {
                timeoutUs > 0 -> timeoutUs
                isSeek || lastRenderedTimeUs == -1L -> 30000L // 30ms warm-up for first frame
                else -> 1000L // 1ms safety margin for smooth preview
            }
            
            var retries = if (effectiveTimeout > 10000L) 50 else 5
            
            while (retries-- > 0 && !found) {
                val inputIndex = codec.dequeueInputBuffer(0) // Feeding input is fast, keep it 0
                if (inputIndex >= 0) {
                    val inputBuffer = codec.getInputBuffer(inputIndex)!!
                    val sampleSize = extractor.readSampleData(inputBuffer, 0)
                    if (sampleSize < 0) {
                        codec.queueInputBuffer(inputIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                    } else {
                        codec.queueInputBuffer(inputIndex, 0, sampleSize, extractor.sampleTime, 0)
                        extractor.advance()
                    }
                }

                val outputIndex = codec.dequeueOutputBuffer(info, effectiveTimeout)
                if (outputIndex >= 0) {
                    if (info.presentationTimeUs >= targetUs) {
                        codec.releaseOutputBuffer(outputIndex, true)
                        lastRenderedTimeUs = info.presentationTimeUs
                        found = true
                    } else {
                        codec.releaseOutputBuffer(outputIndex, false)
                    }
                } else if (outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER && effectiveTimeout < 5000L) {
                    break 
                }
            }
            
            if (found) {
                surfaceTexture?.updateTexImage()
            }
            return true 
        } catch (e: Exception) {
            Log.e("HardwareVideoDecoder", "Update failed: ${e.message}")
            return false
        }
    }

    fun getTextureId() = textureId
    fun getWidth() = width
    fun getHeight() = height
    fun getDurationMs() = durationMs

    fun release() {
        try {
            codec?.stop()
            codec?.release()
            extractor?.release()
            surface?.release()
            surfaceTexture?.release()
            if (textureId != -1) {
                GLES20.glDeleteTextures(1, intArrayOf(textureId), 0)
            }
        } catch (e: Exception) {}
        codec = null
        extractor = null
        textureId = -1
    }
}
