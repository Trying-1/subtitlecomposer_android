package com.example.typgraphyeditor

import android.graphics.*
import android.opengl.*
import android.graphics.BitmapFactory
import android.util.Log

class SubtitleRenderer(private var width: Int, private var height: Int) {
    private val gifCache = mutableMapOf<String, GifData>()
    private val hwVideoDecoderCache = mutableMapOf<String, HardwareVideoDecoder>()
    private val textureCache = mutableMapOf<String, Int>()
    private val dimensionCache = mutableMapOf<String, Pair<Int, Int>>()
    
    // Text Texture Caching
    private val textTextureCache = mutableMapOf<String, CachedTextTexture>()
    private val prevPositionMap = mutableMapOf<String, PointF>()

    class GifData(
        val movie: android.graphics.Movie,
        val bitmap: Bitmap,
        val canvas: android.graphics.Canvas
    )

    class CachedTextTexture(
        val textureId: Int,
        val width: Int,
        val height: Int,
        var lastUsed: Long
    )

    fun updateSize(newWidth: Int, newHeight: Int) {
        width = newWidth
        height = newHeight
    }
    
    private var program: Int = 0
    private var programOES: Int = 0
    
    private var vPositionLoc: Int = 0
    private var vTexCoordLoc: Int = 0
    private var uMVPMatrixLoc: Int = 0
    private var sTextureLoc: Int = 0
    private var vColorLoc: Int = 0
    private var uBlurVectorLoc: Int = 0

    private val vertexShaderCode = """
        attribute vec4 vPosition;
        attribute vec2 vTexCoord;
        uniform mat4 uMVPMatrix;
        varying vec2 fTexCoord;
        void main() {
            gl_Position = uMVPMatrix * vPosition;
            fTexCoord = vTexCoord;
        }
    """.trimIndent()

    // Fragment shader with Motion Blur support
    private val fragmentShaderCode = """
        precision mediump float;
        varying vec2 fTexCoord;
        uniform sampler2D sTexture;
        uniform vec4 vColor;
        uniform vec2 uBlurVector;
        void main() {
            if (length(uBlurVector) < 0.001) {
                vec4 texColor = texture2D(sTexture, fTexCoord);
                if (texColor.a < 0.01) discard;
                gl_FragColor = texColor * vColor;
            } else {
                vec4 accum = vec4(0.0);
                float samples = 5.0;
                for (float i = 0.0; i < 5.0; i += 1.0) {
                    float offset = (i / (samples - 1.0)) - 0.5;
                    accum += texture2D(sTexture, fTexCoord + uBlurVector * offset);
                }
                vec4 texColor = accum / samples;
                if (texColor.a < 0.01) discard;
                gl_FragColor = texColor * vColor;
            }
        }
    """.trimIndent()

    private val fragmentShaderOESCode = """
        #extension GL_OES_EGL_image_external : require
        precision mediump float;
        varying vec2 fTexCoord;
        uniform samplerExternalOES sTexture;
        uniform vec4 vColor;
        void main() {
            vec4 texColor = texture2D(sTexture, fTexCoord);
            if (texColor.a < 0.01) discard;
            gl_FragColor = texColor * vColor;
        }
    """.trimIndent()

    fun init() {
        val vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexShaderCode)
        val fragmentShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentShaderCode)
        program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertexShader)
        GLES20.glAttachShader(program, fragmentShader)
        GLES20.glLinkProgram(program)
        
        val fragmentShaderOES = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentShaderOESCode)
        programOES = GLES20.glCreateProgram()
        GLES20.glAttachShader(programOES, vertexShader)
        GLES20.glAttachShader(programOES, fragmentShaderOES)
        GLES20.glLinkProgram(programOES)
        
        vPositionLoc = GLES20.glGetAttribLocation(program, "vPosition")
        vTexCoordLoc = GLES20.glGetAttribLocation(program, "vTexCoord")
        uMVPMatrixLoc = GLES20.glGetUniformLocation(program, "uMVPMatrix")
        sTextureLoc = GLES20.glGetUniformLocation(program, "sTexture")
        vColorLoc = GLES20.glGetUniformLocation(program, "vColor")
        uBlurVectorLoc = GLES20.glGetUniformLocation(program, "uBlurVector")
        
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
    }

    private fun useProgram(isOES: Boolean) {
        val p = if (isOES) programOES else program
        GLES20.glUseProgram(p)
        vPositionLoc = GLES20.glGetAttribLocation(p, "vPosition")
        vTexCoordLoc = GLES20.glGetAttribLocation(p, "vTexCoord")
        uMVPMatrixLoc = GLES20.glGetUniformLocation(p, "uMVPMatrix")
        sTextureLoc = GLES20.glGetUniformLocation(p, "sTexture")
        vColorLoc = GLES20.glGetUniformLocation(p, "vColor")
        uBlurVectorLoc = GLES20.glGetUniformLocation(p, "uBlurVector")
    }

    private fun loadShader(type: Int, shaderCode: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, shaderCode)
        GLES20.glCompileShader(shader)
        return shader
    }

    fun drawTextClip(
        clip: SubtitleClip,
        animState: AnimatedTextState = AnimatedTextState(),
        assetManager: android.content.res.AssetManager? = null
    ) {
        if (animState.opacity <= 0f) return

        val displayText = if (animState.typewriterProgress < 1f) {
            val charCount = (clip.text.length * animState.typewriterProgress).toInt().coerceAtLeast(0)
            clip.text.substring(0, charCount)
        } else {
            clip.text
        }
        if (displayText.isEmpty()) return

        // Create Cache Key - MUST include all visual properties to invalidate cache when they change
        val cacheKey = "${clip.id}_${displayText}_${clip.fontSize}_${clip.color}_${clip.fontFamily}_" +
                "${clip.strokeWidth}_${clip.strokeColor}_${clip.textOpacity}_" +
                "${clip.isShadowEnabled}_${clip.shadowBlur}_${clip.shadowColor}_${clip.shadowOffsetX}_${clip.shadowOffsetY}_" +
                "${clip.isBackgroundEnabled}_${clip.backgroundColor}_${clip.backgroundRadius}"
        
        val cached = textTextureCache[cacheKey]
        val textureId: Int
        val bmpWidth: Int
        val bmpHeight: Int

        if (cached != null) {
            textureId = cached.textureId
            bmpWidth = cached.width
            bmpHeight = cached.height
            cached.lastUsed = System.currentTimeMillis()
        } else {
            val paint = Paint().apply {
                isAntiAlias = true
                textSize = clip.fontSize
                color = Color.WHITE
                textAlign = Paint.Align.CENTER
                letterSpacing = clip.letterSpacing / clip.fontSize
                if (assetManager != null) {
                    typeface = FontManager.getTypeface(assetManager, clip.fontFamily)
                }
            }

            val bounds = Rect()
            paint.getTextBounds(displayText, 0, displayText.length, bounds)
            
            val hPadding = (clip.shadowBlur + Math.abs(clip.shadowOffsetX) + 30f).coerceAtLeast(30f)
            val vPadding = (clip.shadowBlur + Math.abs(clip.shadowOffsetY) + 30f).coerceAtLeast(30f)

            bmpWidth = (bounds.width() + hPadding * 2).toInt()
            bmpHeight = (bounds.height() + vPadding * 2).toInt()
            
            if (bmpWidth <= 0 || bmpHeight <= 0) return

            val bitmap = Bitmap.createBitmap(bmpWidth, bmpHeight, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)

            if (clip.isBackgroundEnabled && Color.alpha(clip.backgroundColor) > 0) {
                val bgPaint = Paint().apply {
                    isAntiAlias = true
                    color = clip.backgroundColor
                    style = Paint.Style.FILL
                }
                val rect = RectF(hPadding - 15f, vPadding - 5f, hPadding + bounds.width() + 15f, vPadding + bounds.height() + 5f)
                canvas.drawRoundRect(rect, clip.backgroundRadius, clip.backgroundRadius, bgPaint)
            }

            if (clip.isShadowEnabled && Color.alpha(clip.shadowColor) > 0) {
                // Android's setShadowLayer requires a radius > 0 to show anything.
                // We use 0.1f as a minimum for "hard" shadows.
                val radius = if (clip.shadowBlur <= 0f) 0.1f else clip.shadowBlur
                paint.setShadowLayer(radius, clip.shadowOffsetX, clip.shadowOffsetY, clip.shadowColor)
            }

            val textCenterX = bmpWidth / 2f
            val textBaselineY = (bmpHeight / 2f) - ((bounds.top + bounds.bottom) / 2f)

            if (clip.strokeWidth > 0f) {
                paint.style = Paint.Style.STROKE
                paint.strokeWidth = clip.strokeWidth
                paint.strokeJoin = Paint.Join.ROUND
                paint.strokeCap = Paint.Cap.ROUND
                paint.color = clip.strokeColor
                canvas.drawText(displayText, textCenterX, textBaselineY, paint)
                
                paint.style = Paint.Style.FILL
                val fillAlpha = (Color.alpha(clip.color) * clip.textOpacity).toInt()
                paint.color = Color.argb(fillAlpha, Color.red(clip.color), Color.green(clip.color), Color.blue(clip.color))
                canvas.drawText(displayText, textCenterX, textBaselineY, paint)
            } else {
                paint.style = Paint.Style.FILL
                val fillAlpha = (Color.alpha(clip.color) * clip.textOpacity).toInt()
                paint.color = Color.argb(fillAlpha, Color.red(clip.color), Color.green(clip.color), Color.blue(clip.color))
                canvas.drawText(displayText, textCenterX, textBaselineY, paint)
            }

            val textures = IntArray(1)
            GLES20.glGenTextures(1, textures, 0)
            textureId = textures[0]
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
            
            bitmap.recycle()
            textTextureCache[cacheKey] = CachedTextTexture(textureId, bmpWidth, bmpHeight, System.currentTimeMillis())
        }

        // Calculate Motion Blur Vector
        val finalX = (clip.x + animState.offsetX)
        val finalY = (clip.y + animState.offsetY)
        val prevPos = prevPositionMap[clip.id]
        val blurX: Float
        val blurY: Float
        
        if (prevPos != null) {
            // Intensity of blur based on screen distance
            val sensitivity = 0.5f 
            blurX = (finalX - prevPos.x) * sensitivity
            blurY = (finalY - prevPos.y) * sensitivity
        } else {
            blurX = 0f
            blurY = 0f
        }
        prevPositionMap[clip.id] = PointF(finalX, finalY)

        useProgram(false)

        val aspect = width.toFloat() / height.toFloat()
        val mvpMatrix = FloatArray(16)
        val projection = FloatArray(16)
        android.opengl.Matrix.orthoM(projection, 0, -aspect, aspect, -1f, 1f, -1f, 1f)
        
        val model = FloatArray(16)
        android.opengl.Matrix.setIdentityM(model, 0)
        
        val glX = (finalX * 2 - 1) * aspect
        val glY = -(finalY * 2 - 1)
        android.opengl.Matrix.translateM(model, 0, glX, glY, 0f)
        
        val totalRotation = clip.rotation + animState.rotation
        if (totalRotation != 0f) {
            android.opengl.Matrix.rotateM(model, 0, totalRotation, 0f, 0f, 1f)
        }
        
        val finalScale = clip.scale * animState.scale
        val logW = (bmpWidth.toFloat() / height) * 2 * finalScale * animState.scaleX
        val logH = (bmpHeight.toFloat() / height) * 2 * finalScale * animState.scaleY
        android.opengl.Matrix.scaleM(model, 0, logW, logH, 1f)
        
        android.opengl.Matrix.multiplyMM(mvpMatrix, 0, projection, 0, model, 0)
        GLES20.glUniformMatrix4fv(uMVPMatrixLoc, 1, false, mvpMatrix, 0)
        
        // Pass Motion Blur Vector
        GLES20.glUniform2f(uBlurVectorLoc, blurX, blurY)

        val vertices = floatArrayOf(
            -0.5f,  0.5f, 0f, 0f, 0f,
            -0.5f, -0.5f, 0f, 0f, 1f,
             0.5f,  0.5f, 0f, 1f, 0f,
             0.5f, -0.5f, 0f, 1f, 1f
        )
        val vertexBuffer = java.nio.ByteBuffer.allocateDirect(vertices.size * 4)
            .order(java.nio.ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(vertices)
        vertexBuffer.position(0)

        GLES20.glVertexAttribPointer(vPositionLoc, 3, GLES20.GL_FLOAT, false, 5 * 4, vertexBuffer)
        GLES20.glEnableVertexAttribArray(vPositionLoc)
        vertexBuffer.position(3)
        GLES20.glVertexAttribPointer(vTexCoordLoc, 2, GLES20.GL_FLOAT, false, 5 * 4, vertexBuffer)
        GLES20.glEnableVertexAttribArray(vTexCoordLoc)

        val a = ((clip.color shr 24 and 0xFF) / 255f) * clip.opacity * animState.opacity
        GLES20.glUniform4f(vColorLoc, 1f, 1f, 1f, a)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glUniform1i(sTextureLoc, 0)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        
        // Don't delete texture here, it's cached!
    }

    fun drawImageClip(
        clip: SubtitleClip,
        animState: AnimatedTextState = AnimatedTextState(),
        currentTimeMs: Long = 0L
    ) {
        val path = clip.imagePath ?: return
        if (animState.opacity <= 0f) return

        val lowerPath = path.lowercase()
        var textureId = -1
        var bmpWidth = 1280
        var bmpHeight = 720
        var isCached = false
        var isOES = false

        if (lowerPath.endsWith(".gif")) {
            val gif = gifCache.getOrPut(path) {
                val movie = android.graphics.Movie.decodeFile(path) ?: return
                val w = if (movie.width() > 0) movie.width() else 512
                val h = if (movie.height() > 0) movie.height() else 512
                val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                val canvas = android.graphics.Canvas(bmp)
                GifData(movie, bmp, canvas)
            }
            
            val duration = gif.movie.duration()
            val time = if (duration > 0) (currentTimeMs % duration).toInt() else 0
            gif.movie.setTime(time)
            gif.bitmap.eraseColor(Color.TRANSPARENT)
            gif.movie.draw(gif.canvas, 0f, 0f)
            
            val tex = IntArray(1)
            GLES20.glGenTextures(1, tex, 0)
            textureId = tex[0]
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, gif.bitmap, 0)
            bmpWidth = gif.bitmap.width
            bmpHeight = gif.bitmap.height
            isCached = false
        } else if (lowerPath.endsWith(".mp4") || lowerPath.endsWith(".mov") || lowerPath.endsWith(".mkv") || lowerPath.endsWith(".webm")) {
            val decoder = hwVideoDecoderCache.getOrPut(path) {
                HardwareVideoDecoder().apply { init(path) }
            }
            
            val rawTime = (currentTimeMs - clip.startTime).coerceAtLeast(0)
            val duration = decoder.getDurationMs()
            val clipTime = if (duration > 0) rawTime % duration else rawTime
            decoder.updateFrame(clipTime)
            
            textureId = decoder.getTextureId()
            bmpWidth = decoder.getWidth()
            bmpHeight = decoder.getHeight()
            isCached = true
            isOES = true
        } else {
            textureId = textureCache.getOrPut(path) {
                val bitmap = BitmapFactory.decodeFile(path) ?: return@getOrPut 0
                val tex = IntArray(1)
                GLES20.glGenTextures(1, tex, 0)
                GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, tex[0])
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
                GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
                GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
                dimensionCache[path] = Pair(bitmap.width, bitmap.height)
                bitmap.recycle()
                tex[0]
            }
            val dims = dimensionCache[path] ?: Pair(1280, 720)
            bmpWidth = dims.first
            bmpHeight = dims.second
            isCached = true
            isOES = false
        }

        if (textureId <= 0) return

        useProgram(isOES)
        if (!isOES) {
            GLES20.glUniform2f(uBlurVectorLoc, 0f, 0f) // No blur for images/gifs yet
        }

        val aspect = width.toFloat() / height.toFloat()
        val mvpMatrix = FloatArray(16)
        val projection = FloatArray(16)
        android.opengl.Matrix.orthoM(projection, 0, -aspect, aspect, -1f, 1f, -1f, 1f)
        
        val model = FloatArray(16)
        android.opengl.Matrix.setIdentityM(model, 0)
        
        val glX = ((clip.x + animState.offsetX) * 2 - 1) * aspect
        val glY = -((clip.y + animState.offsetY) * 2 - 1)
        android.opengl.Matrix.translateM(model, 0, glX, glY, 0f)
        
        val totalRotation = clip.rotation + animState.rotation
        if (totalRotation != 0f) {
            android.opengl.Matrix.rotateM(model, 0, totalRotation, 0f, 0f, 1f)
        }
        
        val finalScale = clip.scale * animState.scale
        val imgAspect = bmpWidth.toFloat() / bmpHeight.toFloat().coerceAtLeast(1f)
        
        val logW = (2f * imgAspect) * finalScale * animState.scaleX
        val logH = 2f * finalScale * animState.scaleY
        android.opengl.Matrix.scaleM(model, 0, logW, logH, 1f)
        
        android.opengl.Matrix.multiplyMM(mvpMatrix, 0, projection, 0, model, 0)
        GLES20.glUniformMatrix4fv(uMVPMatrixLoc, 1, false, mvpMatrix, 0)

        val vertices = floatArrayOf(
            -0.5f,  0.5f, 0f, 0f, 0f,
            -0.5f, -0.5f, 0f, 0f, 1f,
             0.5f,  0.5f, 0f, 1f, 0f,
             0.5f, -0.5f, 0f, 1f, 1f
        )
        val vertexBuffer = java.nio.ByteBuffer.allocateDirect(vertices.size * 4)
            .order(java.nio.ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(vertices)
        vertexBuffer.position(0)

        GLES20.glVertexAttribPointer(vPositionLoc, 3, GLES20.GL_FLOAT, false, 5 * 4, vertexBuffer)
        GLES20.glEnableVertexAttribArray(vPositionLoc)
        vertexBuffer.position(3)
        GLES20.glVertexAttribPointer(vTexCoordLoc, 2, GLES20.GL_FLOAT, false, 5 * 4, vertexBuffer)
        GLES20.glEnableVertexAttribArray(vTexCoordLoc)

        val a = clip.opacity * animState.opacity
        GLES20.glUniform4f(vColorLoc, 1f, 1f, 1f, a)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(if (isOES) android.opengl.GLES11Ext.GL_TEXTURE_EXTERNAL_OES else GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glUniform1i(sTextureLoc, 0)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        if (!isCached) {
            GLES20.glDeleteTextures(1, intArrayOf(textureId), 0)
        }
    }

    fun clearCache() {
        gifCache.forEach { (_, gif) -> gif.bitmap.recycle() }
        gifCache.clear()
        hwVideoDecoderCache.forEach { (_, decoder) -> decoder.release() }
        hwVideoDecoderCache.clear()
        textureCache.forEach { (_, id) -> GLES20.glDeleteTextures(1, intArrayOf(id), 0) }
        textureCache.clear()
        textTextureCache.forEach { (_, cached) -> GLES20.glDeleteTextures(1, intArrayOf(cached.textureId), 0) }
        textTextureCache.clear()
    }
}
