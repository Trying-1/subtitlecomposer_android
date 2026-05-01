package com.typography

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

    private var isReleased = false
    private val bufferPool = java.util.concurrent.ConcurrentLinkedQueue<Pair<Int, MediaCodec.BufferInfo>>()
    private val lock = Any()
    private var isDecoding = false
    
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
            
            val tex = IntArray(1)
            GLES20.glGenTextures(1, tex, 0)
            textureId = tex[0]
            GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            
            surfaceTexture = SurfaceTexture(textureId)
            surface = Surface(surfaceTexture)
            
            codec = MediaCodec.createDecoderByType(mime)
            codec?.configure(format, surface, null, 0)
            codec?.start()
            
            startDecodingThread()
            return true
        } catch (e: Exception) {
            Log.e("HardwareVideoDecoder", "Init failed: ${e.message}")
            return false
        }
    }

    private fun startDecodingThread() {
        if (isDecoding) return
        isDecoding = true
        Thread({
            while (!isReleased) {
                try {
                    synchronized(lock) {
                        pumpDecoder()
                    }
                    Thread.sleep(5) // Don't burn the CPU
                } catch (e: Exception) {
                    if (!isReleased) Log.e("HardwareVideoDecoder", "Decoding error: ${e.message}")
                }
            }
        }, "VideoDecoderWorker").start()
    }

    private fun pumpDecoder() {
        val codec = codec ?: return
        val extractor = extractor ?: return
        
        // 1. Feed Input
        val inputIndex = codec.dequeueInputBuffer(0)
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

        // 2. Collect Output to Pool
        // We hold up to 10 frames in the buffer pool for instant scrubbing
        if (bufferPool.size < 10) {
            val info = MediaCodec.BufferInfo()
            val outputIndex = codec.dequeueOutputBuffer(info, 1000L)
            if (outputIndex >= 0) {
                bufferPool.add(Pair(outputIndex, info))
            }
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
        if (isReleased) return false
        val targetUs = timeMs * 1000
        
        // Use a threshold that accounts for the -1 initial state
        val delta = if (lastRenderedTimeUs == -1L) Long.MAX_VALUE else targetUs - lastRenderedTimeUs
        
        if (Math.abs(delta) < 8000) return true

        synchronized(lock) {
            try {
                // If seeking (moving backwards or jumping way forward)
                if (lastRenderedTimeUs == -1L || delta < -33000 || delta > 500000) {
                    extractor?.seekTo(targetUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
                    codec?.flush()
                    while (bufferPool.isNotEmpty()) {
                        val (index, _) = bufferPool.poll()!!
                        codec?.releaseOutputBuffer(index, false)
                    }
                    lastRenderedTimeUs = -1
                    
                    // Force a synchronous pump to get the FIRST frame after seek
                    // This prevents the "black background" during seeking
                    var seekFound = false
                    var retry = 0
                    while (retry++ < 30 && !seekFound) {
                        pumpDecoder()
                        if (bufferPool.isNotEmpty()) {
                            val (index, info) = bufferPool.poll()!!
                            codec?.releaseOutputBuffer(index, true)
                            surfaceTexture?.updateTexImage()
                            lastRenderedTimeUs = info.presentationTimeUs
                            seekFound = true
                        } else {
                            Thread.sleep(2)
                        }
                    }
                    return seekFound
                }

                // Normal Playback: Pick the best frame from our pool
                var bestIndex = -1
                var bestInfo: MediaCodec.BufferInfo? = null
                
                val iterator = bufferPool.iterator()
                while (iterator.hasNext()) {
                    val (index, info) = iterator.next()
                    if (info.presentationTimeUs <= targetUs + 8000) {
                        if (bestIndex != -1) codec?.releaseOutputBuffer(bestIndex, false)
                        bestIndex = index
                        bestInfo = info
                        iterator.remove()
                    } else break
                }

                if (bestIndex != -1 && bestInfo != null) {
                    codec?.releaseOutputBuffer(bestIndex, true)
                    surfaceTexture?.updateTexImage()
                    lastRenderedTimeUs = bestInfo.presentationTimeUs
                    return true
                }
                
                return true // Keep previous frame if pool is temporarily empty
            } catch (e: Exception) {
                Log.e("HardwareVideoDecoder", "Update failed: ${e.message}")
                return false
            }
        }
    }

    fun getTextureId() = textureId
    fun getWidth() = width
    fun getHeight() = height
    fun getDurationMs() = durationMs

    fun release() {
        synchronized(lock) {
            isReleased = true
            try {
                // Release all pooled buffers
                while (bufferPool.isNotEmpty()) {
                    val (index, _) = bufferPool.poll()!!
                    codec?.releaseOutputBuffer(index, false)
                }
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
}
