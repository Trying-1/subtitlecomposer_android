package com.typography

import android.util.Log
import java.io.File

class VideoFrameDecoder {
    private var nativeHandle: Long = 0
    private var lastPath: String? = null
    private var lastFrameTime = -1L
    private var imageWidth: Int = 0
    private var imageHeight: Int = 0

    fun getWidth() = imageWidth
    fun getHeight() = imageHeight

    // Native methods
    private external fun nativeInit(path: String): Long
    private external fun nativeGetWidth(handle: Long): Int
    private external fun nativeGetHeight(handle: Long): Int
    private external fun nativeUpdateTexture(handle: Long, timeMs: Long, textureId: Int, width: Int, height: Int): Boolean
    private external fun nativeRelease(handle: Long)

    companion object {
        init {
            System.loadLibrary("native-lib")
        }
    }

    fun setPath(path: String?) {
        if (path == lastPath) return
        
        release()
        lastPath = path
        lastFrameTime = -1L
        
        if (path == null || !File(path).exists()) return

        try {
            nativeHandle = nativeInit(path)
            if (nativeHandle != 0L) {
                imageWidth = nativeGetWidth(nativeHandle)
                imageHeight = nativeGetHeight(nativeHandle)
            } else {
                Log.e("VideoFrameDecoder", "Native init failed for $path")
            }
        } catch (e: Exception) {
            Log.e("VideoFrameDecoder", "Error in nativeInit: ${e.message}")
        }
    }

    fun updateTexture(timeMs: Long, textureId: Int, targetW: Int = imageWidth, targetH: Int = imageHeight): Boolean {
        if (nativeHandle == 0L || textureId == -1) return false
        
        // Basic optimization: don't update if time hasn't changed much
        if (Math.abs(timeMs - lastFrameTime) < 15) {
            return true
        }

        return try {
            val success = nativeUpdateTexture(nativeHandle, timeMs, textureId, targetW, targetH)
            if (success) {
                lastFrameTime = timeMs
            }
            success
        } catch (e: Exception) {
            Log.e("VideoFrameDecoder", "Error in nativeUpdateTexture: ${e.message}")
            false
        }
    }

    fun release() {
        if (nativeHandle != 0L) {
            try {
                nativeRelease(nativeHandle)
            } catch (e: Exception) {}
            nativeHandle = 0L
        }
        lastFrameTime = -1L
    }
}
