package com.typography

import ai.onnxruntime.*
import android.content.res.AssetManager
import java.nio.FloatBuffer
import kotlin.math.sqrt

class VADEngine(assetManager: AssetManager) {
    private var env: OrtEnvironment? = null
    private var session: OrtSession? = null

    init {
        try {
            env = OrtEnvironment.getEnvironment()
            // Flutter assets are located in "flutter_assets/" prefix when accessed via AssetManager
            val modelBytes = assetManager.open("flutter_assets/assets/silero/silero_vad.onnx").use { it.readBytes() }
            if (modelBytes.isNotEmpty()) {
                session = env?.createSession(modelBytes)
            }
        } catch (e: Exception) {
            android.util.Log.w("VADEngine", "Silero VAD model not found or failed to load. Falling back to heuristic VAD. Error: ${e.message}")
        }
    }

    fun getSpeechSegments(pcm: FloatArray): List<Map<String, Any>> {
        if (pcm.isEmpty()) return emptyList()

        // If Silero is available, use it
        val ortSession = session
        val ortEnv = env
        if (ortSession != null && ortEnv != null) {
            try {
                return getSpeechSegmentsSilero(ortEnv, ortSession, pcm)
            } catch (e: Exception) {
                android.util.Log.e("VADEngine", "Silero VAD execution failed: ${e.message}")
            }
        }

        // Fallback to Heuristic RMS-based VAD
        return getSpeechSegmentsHeuristic(pcm)
    }

    private fun getSpeechSegmentsSilero(env: OrtEnvironment, session: OrtSession, pcm: FloatArray): List<Map<String, Any>> {
        val segments = mutableListOf<Map<String, Any>>()
        val windowSizeSamples = 1536
        val threshold = 0.4f
        val minSpeechDurationMs = 250
        val minSilenceDurationMs = 100
        
        var isSpeech = false
        var speechStartMs = 0L
        var silenceStartMs = 0L

        val stateShape = longArrayOf(2, 1, 64)
        var h = FloatArray(128) { 0f }
        var c = FloatArray(128) { 0f }

        val srTensor = OnnxTensor.createTensor(env, longArrayOf(16000))

        for (i in 0 until pcm.size - windowSizeSamples step windowSizeSamples) {
            val chunk = pcm.sliceArray(i until i + windowSizeSamples)
            val chunkTensor = OnnxTensor.createTensor(env, FloatBuffer.wrap(chunk), longArrayOf(1, windowSizeSamples.toLong()))
            val hTensor = OnnxTensor.createTensor(env, FloatBuffer.wrap(h), stateShape)
            val cTensor = OnnxTensor.createTensor(env, FloatBuffer.wrap(c), stateShape)

            val inputs = mapOf(
                "input" to chunkTensor,
                "sr" to srTensor,
                "h" to hTensor,
                "c" to cTensor
            )

            val results = session.run(inputs)
            val outputValue = (results.get(0).value as Array<FloatArray>)[0][0]
            
            h = flatten3D(results.get(1).value as Array<Array<FloatArray>>)
            c = flatten3D(results.get(2).value as Array<Array<FloatArray>>)

            val currentMs = (i.toLong() * 1000) / 16000

            if (outputValue >= threshold) {
                if (!isSpeech) {
                    isSpeech = true
                    speechStartMs = currentMs
                }
                silenceStartMs = 0
            } else {
                if (isSpeech) {
                    if (silenceStartMs == 0L) silenceStartMs = currentMs
                    if (currentMs - silenceStartMs > minSilenceDurationMs) {
                        if (currentMs - speechStartMs > minSpeechDurationMs) {
                            segments.add(mapOf("start" to speechStartMs.toDouble(), "end" to currentMs.toDouble()))
                        }
                        isSpeech = false
                        silenceStartMs = 0
                    }
                }
            }

            chunkTensor.close()
            hTensor.close()
            cTensor.close()
            results.close()
        }

        if (isSpeech) {
            val endMs = (pcm.size.toLong() * 1000) / 16000
            segments.add(mapOf("start" to speechStartMs.toDouble(), "end" to endMs.toDouble()))
        }

        srTensor.close()
        return segments
    }

    private fun getSpeechSegmentsHeuristic(pcm: FloatArray): List<Map<String, Any>> {
        val segments = mutableListOf<Map<String, Any>>()
        val windowSizeMs = 50
        val windowSizeSamples = (16000 * windowSizeMs) / 1000
        val threshold = 0.015f // RMS threshold for speech
        
        var isSpeech = false
        var speechStartMs = 0L
        
        for (i in 0 until pcm.size - windowSizeSamples step windowSizeSamples) {
            var sumSq = 0f
            for (j in i until i + windowSizeSamples) {
                sumSq += pcm[j] * pcm[j]
            }
            val rms = sqrt(sumSq / windowSizeSamples)
            val currentMs = (i.toLong() * 1000) / 16000

            if (rms > threshold) {
                if (!isSpeech) {
                    isSpeech = true
                    speechStartMs = currentMs
                }
            } else {
                if (isSpeech) {
                    segments.add(mapOf("start" to speechStartMs.toDouble(), "end" to currentMs.toDouble()))
                    isSpeech = false
                }
            }
        }

        if (isSpeech) {
            val endMs = (pcm.size.toLong() * 1000) / 16000
            segments.add(mapOf("start" to speechStartMs.toDouble(), "end" to endMs.toDouble()))
        }

        return segments
    }

    private fun flatten3D(arr: Array<Array<FloatArray>>): FloatArray {
        val result = FloatArray(128)
        var idx = 0
        for (i in arr) {
            for (j in i) {
                for (k in j) {
                    result[idx++] = k
                }
            }
        }
        return result
    }

    fun close() {
        session?.close()
        // env?.close() // Environment should be handled carefully if shared
    }
}
