package com.typography

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.typography/bridge"
    private var renderer: TypographyRenderer? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null

    companion object {
        init {
            System.loadLibrary("native-lib")
        }
    }

    private external fun muxVideoAudio(
        videoPath: String, 
        audioPath: String, 
        outputPath: String, 
        paths: Array<String>,
        starts: LongArray,
        ends: LongArray,
        vols: FloatArray
    ): Int
    private external fun extractAudio(videoPath: String, outputPath: String): Int
    
    private external fun initWhisper(modelPath: String): Long
    private external fun transcribeWhisper(contextPtr: Long, audioPath: String, initialPrompt: String, language: String): String
    private external fun freeWhisper(contextPtr: Long)
    
    // Native Audio Engine
    private external fun initAudioEngine()
    private external fun releaseAudioEngine()
    private external fun startAudioEngine()
    private external fun stopAudioEngine()
    private external fun seekAudioEngine(timeMs: Long)
    private external fun setMainAudio(path: String)
    private external fun setMainAudioVolume(volume: Float)
    private external fun getAudioPosition(): Long
    private external fun setAudioClips(ids: Array<String>, paths: Array<String>, starts: LongArray, ends: LongArray, vols: FloatArray)
    
    private external fun decodeAudioToPcm(audioPath: String): FloatArray?

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(com.typography.videoplayer.SimpleVideoPlayerPlugin())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initRenderer" -> {
                    val width = (call.argument<Number>("width"))?.toInt() ?: 1280
                    val height = (call.argument<Number>("height"))?.toInt() ?: 720
                    
                    textureEntry = flutterEngine.renderer.createSurfaceTexture()
                    val surfaceTexture = textureEntry?.surfaceTexture()
                    
                    if (surfaceTexture != null) {
                        renderer = TypographyRenderer(surfaceTexture, width, height, assets)
                        renderer?.start()
                        result.success(textureEntry?.id())
                    } else {
                        result.error("ERROR", "Failed to create SurfaceTexture", null)
                    }
                }
                "updateClips" -> {
                    val clipsRaw = call.argument<List<Map<String, Any>>>("clips") ?: emptyList()
                    val clips = parseClips(clipsRaw)
                    renderer?.setClips(clips)
                    result.success(null)
                }
                "updateProjectSettings" -> {
                    val ratio = (call.argument<Number>("aspectRatio"))?.toDouble() ?: (16.0/9.0)
                    val bgColor = (call.argument<Number>("backgroundColor"))?.toInt() ?: 0xFFFFFFFF.toInt()
                    val imagePath = call.argument<String>("backgroundImagePath")
                    val width = (call.argument<Number>("width"))?.toInt()
                    val height = (call.argument<Number>("height"))?.toInt()
                    val bgScale = (call.argument<Number>("bgScale"))?.toFloat()
                    val bgRotation = (call.argument<Number>("bgRotation"))?.toFloat()
                    val bgX = (call.argument<Number>("bgX"))?.toFloat()
                    val bgY = (call.argument<Number>("bgY"))?.toFloat()
                    val bgFillMode = (call.argument<Number>("bgFillMode"))?.toInt()
                    renderer?.updateSettings(ratio, bgColor, imagePath, width, height, bgScale, bgRotation, bgX, bgY, bgFillMode)
                    result.success(null)
                }
                "setPlaying" -> {
                    val playing = call.argument<Boolean>("playing") ?: false
                    renderer?.setPlaying(playing)
                    result.success(null)
                }
                "seekTo" -> {
                    val timeMs = (call.argument<Number>("timeMs"))?.toLong() ?: 0L
                    renderer?.seekTo(timeMs)
                    result.success(null)
                }
                "setTotalDuration" -> {
                    val duration = (call.argument<Number>("duration"))?.toLong() ?: 5000L
                    renderer?.setTotalDuration(duration)
                    result.success(null)
                }
                "exportVideo" -> {
                    val width = (call.argument<Number>("width"))?.toInt() ?: 1280
                    val height = (call.argument<Number>("height"))?.toInt() ?: 720
                    val durationMs = (call.argument<Number>("durationMs"))?.toLong() ?: 0L
                    val clipsRaw = call.argument<List<Map<String, Any>>>("clips") ?: emptyList()
                    val audioPath = call.argument<String>("audioPath")
                    val audioTracks = call.argument<List<Map<String, Any>>>("audioTracks") ?: emptyList()
                    val clips = parseClips(clipsRaw)

                    Thread {
                        try {
                            val tempSilentFile = File(cacheDir, "temp_silent_${System.currentTimeMillis()}.mp4")
                            val tempMuxedFile = File(cacheDir, "temp_muxed_${System.currentTimeMillis()}.mp4")
                            
                            val fileName = "TypographyExport_${System.currentTimeMillis()}.mp4"
                            val values = android.content.ContentValues().apply {
                                put(android.provider.MediaStore.Video.Media.DISPLAY_NAME, fileName)
                                put(android.provider.MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                                put(android.provider.MediaStore.Video.Media.RELATIVE_PATH, "Movies/TypographyEditor")
                                put(android.provider.MediaStore.Video.Media.IS_PENDING, 1)
                            }

                            val resolver = contentResolver
                            val collection = android.provider.MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                            val itemUri = resolver.insert(collection, values)

                            if (itemUri != null) {
                                val bgColor = (call.argument<Number>("backgroundColor"))?.toInt() ?: 0xFFFFFFFF.toInt()
                                val imagePath = call.argument<String>("backgroundImagePath")
                                val bgScale = (call.argument<Number>("bgScale"))?.toFloat() ?: 1f
                                val bgRotation = (call.argument<Number>("bgRotation"))?.toFloat() ?: 0f
                                val bgX = (call.argument<Number>("bgX"))?.toFloat() ?: 0f
                                val bgY = (call.argument<Number>("bgY"))?.toFloat() ?: 0f
                                val bgFillMode = (call.argument<Number>("bgFillMode"))?.toInt() ?: 0
                                val aspectRatio = (call.argument<Number>("aspectRatio"))?.toDouble() ?: (16.0 / 9.0)
                                val exporter = VideoExporter(tempSilentFile.absolutePath, width, height, clips = clips, durationMs = durationMs, assetManager = assets, backgroundColor = bgColor, backgroundImagePath = imagePath, bgScale = bgScale, bgRotation = bgRotation, bgX = bgX, bgY = bgY, bgFillMode = bgFillMode, aspectRatio = aspectRatio)
                                
                                exporter.export { progress ->
                                    // Optional: Send progress back
                                }

                                val finalSourcePath: String
                                if (audioPath != null || audioTracks.isNotEmpty()) {
                                    val paths = mutableListOf<String>()
                                    val starts = mutableListOf<Long>()
                                    val ends = mutableListOf<Long>()
                                    val vols = mutableListOf<Float>()

                                    for (track in audioTracks) {
                                        val clips = track["audioClips"] as? List<Map<String, Any>> ?: continue
                                        for (clip in clips) {
                                            paths.add(clip["audioPath"] as? String ?: "")
                                            starts.add((clip["startTime"] as? Number)?.toLong() ?: 0L)
                                            ends.add((clip["endTime"] as? Number)?.toLong() ?: 0L)
                                            vols.add((clip["volume"] as? Number)?.toFloat() ?: 1.0f)
                                        }
                                    }

                                    android.util.Log.d("MainActivity", "Starting FFmpeg multi-mux: V=${tempSilentFile.path}, A=$audioPath, Clips=${paths.size}")
                                    val ret = muxVideoAudio(
                                        tempSilentFile.absolutePath, 
                                        audioPath ?: "", 
                                        tempMuxedFile.absolutePath, 
                                        paths.toTypedArray(),
                                        starts.toLongArray(),
                                        ends.toLongArray(),
                                        vols.toFloatArray()
                                    )
                                    if (ret == 0) {
                                        finalSourcePath = tempMuxedFile.absolutePath
                                    } else {
                                        android.util.Log.e("MainActivity", "FFmpeg mux failed with code $ret, falling back to silent video")
                                        finalSourcePath = tempSilentFile.absolutePath
                                    }
                                } else {
                                    finalSourcePath = tempSilentFile.absolutePath
                                }

                                // Copy to MediaStore
                                val outStream = resolver.openOutputStream(itemUri)
                                if (outStream != null) {
                                    outStream.use { os ->
                                        File(finalSourcePath).inputStream().use { isStream ->
                                            isStream.copyTo(os)
                                        }
                                    }
                                }

                                // Cleanup temp files
                                tempSilentFile.delete()
                                tempMuxedFile.delete()

                                values.clear()
                                values.put(android.provider.MediaStore.Video.Media.IS_PENDING, 0)
                                resolver.update(itemUri, values, null, null)
                                
                                android.media.MediaScannerConnection.scanFile(this@MainActivity, arrayOf(itemUri.toString()), null, null)
                                
                                runOnUiThread { result.success(itemUri.toString()) }
                            } else {
                                runOnUiThread { result.error("URI_ERROR", "Failed to create MediaStore entry", null) }
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                            runOnUiThread { result.error("EXPORT_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "extractAudio" -> {
                    val videoPath = call.argument<String>("videoPath") ?: ""
                    val outputPath = call.argument<String>("outputPath") ?: ""
                    
                    Thread {
                        try {
                            val ret = extractAudio(videoPath, outputPath)
                            if (ret == 0) {
                                runOnUiThread { result.success(null) }
                            } else {
                                runOnUiThread { result.error("EXTRACT_ERROR", "FFmpeg extraction failed with code $ret", null) }
                            }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("EXTRACT_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "getSpeechSegments" -> {
                    val audioPath = call.argument<String>("audioPath") ?: ""
                    Thread {
                        try {
                                val pcm = decodeAudioToPcm(audioPath)
                                if (pcm != null) {
                                    try {
                                        val vad = VADEngine(assets)
                                        val segments = vad.getSpeechSegments(pcm)
                                        vad.close()
                                        runOnUiThread { result.success(segments) }
                                    } catch (e: Exception) {
                                        android.util.Log.e("MainActivity", "VAD Error: ${e.message}")
                                        runOnUiThread { result.error("VAD_ERROR", e.message, null) }
                                    }
                                } else {
                                    runOnUiThread { result.error("DECODE_ERROR", "Failed to decode audio", null) }
                                }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("VAD_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "disposeRenderer" -> {
                    renderer?.stop()
                    textureEntry?.release()
                    renderer = null
                    textureEntry = null
                    result.success(null)
                }
                "registerFont" -> {
                    val family = call.argument<String>("family")
                    val path = call.argument<String>("path")
                    if (family != null && path != null) {
                        FontManager.registerCustomFont(family, path)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Family or path missing", null)
                    }
                }
                "initWhisper" -> {
                    val modelPath = call.argument<String>("modelPath") ?: ""
                    Thread {
                        val ptr = initWhisper(modelPath)
                        runOnUiThread { result.success(ptr) }
                    }.start()
                }
                "transcribeWhisper" -> {
                    val ptr = (call.argument<Number>("contextPtr"))?.toLong() ?: 0L
                    val audioPath = call.argument<String>("audioPath") ?: ""
                    val prompt = call.argument<String>("initialPrompt") ?: ""
                    val language = call.argument<String>("language") ?: "auto"
                    Thread {
                        val json = transcribeWhisper(ptr, audioPath, prompt, language)
                        runOnUiThread { result.success(json) }
                    }.start()
                }
                "freeWhisper" -> {
                    val ptr = (call.argument<Number>("contextPtr"))?.toLong() ?: 0L
                    freeWhisper(ptr)
                    result.success(null)
                }
                "openVideoFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    if (path.isNotEmpty()) {
                        try {
                            val uri = if (path.startsWith("content://")) {
                                android.net.Uri.parse(path)
                            } else {
                                val file = java.io.File(path)
                                androidx.core.content.FileProvider.getUriForFile(
                                    this,
                                    "$packageName.fileprovider",
                                    file
                                )
                            }
                            val intent = android.content.Intent(android.content.Intent.ACTION_VIEW)
                            intent.setDataAndType(uri, "video/*")
                            intent.addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_ERROR", e.message, null)
                        }
                    } else {
                        result.error("PATH_EMPTY", "Path is empty", null)
                    }
                }
                "getVideoDuration" -> {
                    val path = call.argument<String>("path") ?: ""
                    if (path.isEmpty()) {
                        result.success(0)
                        return@setMethodCallHandler
                    }
                    try {
                        val retriever = android.media.MediaMetadataRetriever()
                        retriever.setDataSource(path)
                        val duration = retriever.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_DURATION)
                        retriever.release()
                        result.success(duration?.toInt() ?: 0)
                    } catch (e: Exception) {
                        result.success(0)
                    }
                }
                "getAssetResolution" -> {
                    val path = call.argument<String>("path") ?: ""
                    if (path.isEmpty()) {
                        result.success(mapOf("width" to 0, "height" to 0))
                        return@setMethodCallHandler
                    }
                    val lowerPath = path.lowercase()
                    if (lowerPath.endsWith(".mp4") || lowerPath.endsWith(".mov") || lowerPath.endsWith(".m4v") || lowerPath.endsWith(".3gp")) {
                        val retriever = android.media.MediaMetadataRetriever()
                        try {
                            retriever.setDataSource(path)
                            val width = retriever.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
                            val height = retriever.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 0
                            val rotation = retriever.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toInt() ?: 0
                            
                            // Adjust for rotation
                            if (rotation == 90 || rotation == 270) {
                                result.success(mapOf("width" to height, "height" to width))
                            } else {
                                result.success(mapOf("width" to width, "height" to height))
                            }
                        } catch (e: Exception) {
                            result.success(mapOf("width" to 0, "height" to 0))
                        } finally {
                            retriever.release()
                        }
                    } else {
                        try {
                            val options = android.graphics.BitmapFactory.Options().apply { inJustDecodeBounds = true }
                            android.graphics.BitmapFactory.decodeFile(path, options)
                            result.success(mapOf("width" to options.outWidth, "height" to options.outHeight))
                        } catch (e: Exception) {
                            result.success(mapOf("width" to 0, "height" to 0))
                        }
                    }
                }
                "getAssetThumbnail" -> {
                    val path = call.argument<String>("path") ?: ""
                    if (path.isEmpty()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        val lowerPath = path.lowercase()
                        var bitmap: android.graphics.Bitmap? = null
                        if (lowerPath.endsWith(".mp4") || lowerPath.endsWith(".mov") || lowerPath.endsWith(".m4v") || lowerPath.endsWith(".3gp")) {
                            val retriever = android.media.MediaMetadataRetriever()
                            try {
                                retriever.setDataSource(path)
                                bitmap = retriever.getFrameAtTime(0, android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                            } catch (e: Exception) {
                                e.printStackTrace()
                            } finally {
                                retriever.release()
                            }
                        } else {
                            try {
                                bitmap = android.graphics.BitmapFactory.decodeFile(path)
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                        }
                        
                        if (bitmap != null) {
                            val stream = java.io.ByteArrayOutputStream()
                            // scale down slightly if very large
                            val maxDim = 800
                            if (bitmap.width > maxDim || bitmap.height > maxDim) {
                                val ratio = Math.min(maxDim.toFloat() / bitmap.width, maxDim.toFloat() / bitmap.height)
                                bitmap = android.graphics.Bitmap.createScaledBitmap(bitmap, (bitmap.width * ratio).toInt(), (bitmap.height * ratio).toInt(), true)
                            }
                            bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, stream)
                            runOnUiThread { result.success(stream.toByteArray()) }
                        } else {
                            runOnUiThread { result.success(null) }
                        }
                    }.start()
                }
                "initAudioEngine" -> {
                    initAudioEngine()
                    result.success(null)
                }
                "releaseAudioEngine" -> {
                    releaseAudioEngine()
                    result.success(null)
                }
                "startAudioEngine" -> {
                    startAudioEngine()
                    result.success(null)
                }
                "stopAudioEngine" -> {
                    stopAudioEngine()
                    result.success(null)
                }
                "seekAudioEngine" -> {
                    val timeMs = (call.argument<Number>("timeMs"))?.toLong() ?: 0L
                    seekAudioEngine(timeMs)
                    result.success(null)
                }
                "setMainAudio" -> {
                    val path = call.argument<String>("path") ?: ""
                    setMainAudio(path)
                    result.success(null)
                }
                "setMainAudioVolume" -> {
                    val volume = (call.argument<Number>("volume"))?.toFloat() ?: 1.0f
                    setMainAudioVolume(volume)
                    result.success(null)
                }
                "getAudioPosition" -> {
                    result.success(getAudioPosition())
                }
                "setAudioClips" -> {
                    val ids = (call.argument<List<String>>("ids"))?.toTypedArray() ?: emptyArray()
                    val paths = (call.argument<List<String>>("paths"))?.toTypedArray() ?: emptyArray()
                    val starts = (call.argument<List<Long>>("starts"))?.toLongArray() ?: LongArray(0)
                    val ends = (call.argument<List<Long>>("ends"))?.toLongArray() ?: LongArray(0)
                    val vols = (call.argument<List<Double>>("vols"))?.map { it.toFloat() }?.toFloatArray() ?: FloatArray(0)
                    setAudioClips(ids, paths, starts, ends, vols)
                    result.success(null)
                }
                "saveImageToGallery" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = "TypographyExport_${System.currentTimeMillis()}.png"
                    
                    if (bytes != null) {
                        Thread {
                            try {
                                val resolver = contentResolver
                                val collection = android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                                var itemUri: android.net.Uri? = null
                                
                                try {
                                    val values = android.content.ContentValues().apply {
                                        put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, fileName)
                                        put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
                                        put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, "Movies/TypographyEditor")
                                        put(android.provider.MediaStore.Images.Media.IS_PENDING, 1)
                                    }
                                    itemUri = resolver.insert(collection, values)
                                } catch (e: Exception) {
                                    val values = android.content.ContentValues().apply {
                                        put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, fileName)
                                        put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
                                        put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, "Pictures/TypographyEditor")
                                        put(android.provider.MediaStore.Images.Media.IS_PENDING, 1)
                                    }
                                    itemUri = resolver.insert(collection, values)
                                }

                                if (itemUri != null) {
                                    val outStream = resolver.openOutputStream(itemUri)
                                    if (outStream != null) {
                                        outStream.use { os ->
                                            os.write(bytes)
                                        }
                                    }
                                    
                                    val updateValues = android.content.ContentValues().apply {
                                        put(android.provider.MediaStore.Images.Media.IS_PENDING, 0)
                                    }
                                    resolver.update(itemUri, updateValues, null, null)

                                    android.media.MediaScannerConnection.scanFile(this@MainActivity, arrayOf(itemUri.toString()), null, null)
                                    
                                    runOnUiThread { result.success(itemUri.toString()) }
                                } else {
                                    runOnUiThread { result.error("URI_ERROR", "Failed to create MediaStore entry", null) }
                                }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("SAVE_ERROR", e.message, null) }
                            }
                        }.start()
                    } else {
                        result.error("INVALID_ARGS", "Bytes array is null", null)
                    }
                }
                "scanFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    if (path.isNotEmpty()) {
                        android.media.MediaScannerConnection.scanFile(this@MainActivity, arrayOf(path), null) { _, uri ->
                            runOnUiThread { result.success(uri?.toString()) }
                        }
                    } else {
                        result.error("INVALID_PATH", "Path is empty", null)
                    }
                }
                "decodeAudioToPcm" -> {
                    val path = call.argument<String>("audioPath") ?: ""
                    Thread {
                        val pcm = decodeAudioToPcm(path)
                        runOnUiThread { result.success(pcm) }
                    }.start()
                }
                "checkStoragePermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                        result.success(android.os.Environment.isExternalStorageManager())
                    } else {
                        val readPerm = androidx.core.content.ContextCompat.checkSelfPermission(
                            this,
                            android.Manifest.permission.READ_EXTERNAL_STORAGE
                        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                        result.success(readPerm)
                    }
                }
                "requestStoragePermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                        try {
                            val intent = android.content.Intent(android.provider.Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                            intent.data = android.net.Uri.parse("package:" + packageName)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val intent = android.content.Intent(android.provider.Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                                startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("PERMISSION_ERROR", e2.message, null)
                            }
                        }
                    } else {
                        androidx.core.app.ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                android.Manifest.permission.READ_EXTERNAL_STORAGE,
                                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
                            ),
                            1234
                        )
                        result.success(true)
                    }
                }
                "isStoragePermissionDeclared" -> {
                    val declared = try {
                        val packageInfo = packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.GET_PERMISSIONS)
                        packageInfo.requestedPermissions?.contains(android.Manifest.permission.MANAGE_EXTERNAL_STORAGE) == true
                    } catch (e: Exception) {
                        false
                    }
                    result.success(declared)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun parseClips(clipsRaw: List<Map<String, Any>>): List<SubtitleClip> {
        return clipsRaw.map {
            SubtitleClip(
                id = it["id"] as String,
                text = it["text"] as? String ?: "",
                startTime = (it["startTime"] as Number).toLong(),
                endTime = (it["endTime"] as Number).toLong(),
                x = (it["x"] as Number).toFloat(),
                y = (it["y"] as Number).toFloat(),
                fontSize = (it["fontSize"] as? Number)?.toFloat() ?: 50f,
                color = (it["color"] as? Number)?.toInt() ?: 0xFF000000.toInt(),
                strokeColor = (it["strokeColor"] as? Number)?.toInt() ?: 0xFF000000.toInt(),
                strokeWidth = (it["strokeWidth"] as? Number)?.toFloat() ?: 0f,
                shadowColor = (it["shadowColor"] as? Number)?.toInt() ?: 0x00000000,
                shadowBlur = (it["shadowBlur"] as? Number)?.toFloat() ?: 0f,
                shadowOffsetX = (it["shadowOffsetX"] as? Number)?.toFloat() ?: 0f,
                shadowOffsetY = (it["shadowOffsetY"] as? Number)?.toFloat() ?: 0f,
                backgroundColor = (it["backgroundColor"] as? Number)?.toInt() ?: 0x00000000,
                backgroundRadius = (it["backgroundRadius"] as? Number)?.toFloat() ?: 0f,
                letterSpacing = (it["letterSpacing"] as? Number)?.toFloat() ?: 0f,
                rotation = (it["rotation"] as? Number)?.toFloat() ?: 0f,
                scale = (it["scale"] as? Number)?.toFloat() ?: 1f,
                opacity = (it["opacity"] as? Number)?.toFloat() ?: 1f,
                textOpacity = (it["textOpacity"] as? Number)?.toFloat() ?: 1f,
                isShadowEnabled = it["isShadowEnabled"] as? Boolean ?: false,
                isBackgroundEnabled = it["isBackgroundEnabled"] as? Boolean ?: false,
                isStrokeEnabled = it["isStrokeEnabled"] as? Boolean ?: false,
                isGlowEnabled = it["isGlowEnabled"] as? Boolean ?: false,
                isBendingEnabled = it["isBendingEnabled"] as? Boolean ?: false,
                isReflectionEnabled = it["isReflectionEnabled"] as? Boolean ?: false,
                glowColor = (it["glowColor"] as? Number)?.toInt() ?: 0xFFFF0000.toInt(),
                glowSize = (it["glowSize"] as? Number)?.toFloat() ?: 0f,
                bendingAmount = (it["bendingAmount"] as? Number)?.toFloat() ?: 0f,
                reflectionOffset = (it["reflectionOffset"] as? Number)?.toFloat() ?: 0f,
                reflectionOpacity = (it["reflectionOpacity"] as? Number)?.toFloat() ?: 0.5f,
                reflectionColor = (it["reflectionColor"] as? Number)?.toInt() ?: 0xFFFFFFFF.toInt(),
                fontFamily = it["fontFamily"] as? String ?: "Poppins",
                entranceAnimation = ClipAnimation.fromMap(it["entranceAnimation"] as? Map<String, Any>),
                exitAnimation = ClipAnimation.fromMap(it["exitAnimation"] as? Map<String, Any>),
                loopAnimation = ClipAnimation.fromMap(it["loopAnimation"] as? Map<String, Any>),
                blendMode = CustomBlendMode.fromIndex((it["blendMode"] as? Number)?.toInt() ?: 0),
                keyframes = (it["keyframes"] as? List<Map<String, Any>>)?.mapNotNull { k -> Keyframe.fromMap(k) } ?: emptyList(),
                imagePath = it["imagePath"] as? String,
                isText = it["isText"] as? Boolean ?: (it["imagePath"] == null),
                isBackground = it["isBackground"] as? Boolean ?: false,
                fillMode = (it["fillMode"] as? Number)?.toInt() ?: 0,
                isGradientEnabled = it["isGradientEnabled"] as? Boolean ?: false,
                gradientColor1 = (it["gradientColor1"] as? Number)?.toLong()?.toInt() ?: 0xFFFFFFFF.toInt(),
                gradientColor2 = (it["gradientColor2"] as? Number)?.toLong()?.toInt() ?: 0xFF000000.toInt(),
                gradientAngle = (it["gradientAngle"] as? Number)?.toFloat() ?: 0f,
                brightness = (it["brightness"] as? Number)?.toFloat() ?: 1.0f,
                saturation = (it["saturation"] as? Number)?.toFloat() ?: 1.0f,
                contrast = (it["contrast"] as? Number)?.toFloat() ?: 1.0f,
                blur = (it["blur"] as? Number)?.toFloat() ?: 0.0f,
                isChromaKeyEnabled = it["isChromaKeyEnabled"] as? Boolean ?: false,
                chromaKeyColor = (it["chromaKeyColor"] as? Number)?.toInt() ?: 0xFF00FF00.toInt(),
                chromaKeySimilarity = (it["chromaKeySimilarity"] as? Number)?.toFloat() ?: 0.1f,
                chromaKeySmoothness = (it["chromaKeySmoothness"] as? Number)?.toFloat() ?: 0.05f
            )
        }
    }

    override fun onDestroy() {
        renderer?.stop()
        textureEntry?.release()
        super.onDestroy()
    }
}
