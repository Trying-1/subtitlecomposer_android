package com.example.typgraphyeditor

import android.graphics.*
import android.opengl.*

class SubtitleRenderer(private var width: Int, private var height: Int) {
    fun updateSize(newWidth: Int, newHeight: Int) {
        width = newWidth
        height = newHeight
    }
    private var program: Int = 0
    private var vPositionLoc: Int = 0
    private var vTexCoordLoc: Int = 0
    private var sTextureLoc: Int = 0
    private var vColorLoc: Int = 0

    private val vertexShaderCode = """
        attribute vec4 vPosition;
        attribute vec2 vTexCoord;
        varying vec2 fTexCoord;
        void main() {
            gl_Position = vPosition;
            fTexCoord = vTexCoord;
        }
    """.trimIndent()

    private val fragmentShaderCode = """
        precision mediump float;
        varying vec2 fTexCoord;
        uniform sampler2D sTexture;
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
        
        vPositionLoc = GLES20.glGetAttribLocation(program, "vPosition")
        vTexCoordLoc = GLES20.glGetAttribLocation(program, "vTexCoord")
        sTextureLoc = GLES20.glGetUniformLocation(program, "sTexture")
        vColorLoc = GLES20.glGetUniformLocation(program, "vColor")
        
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
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
        // If fully invisible, skip
        if (animState.opacity <= 0f) return

        val paint = Paint().apply {
            isAntiAlias = true
            textSize = clip.fontSize
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            letterSpacing = clip.letterSpacing / clip.fontSize // Android uses em-based
            
            if (assetManager != null) {
                typeface = FontManager.getTypeface(assetManager, clip.fontFamily)
            }
        }

        // Apply typewriter: only show partial text
        val displayText = if (animState.typewriterProgress < 1f) {
            val charCount = (clip.text.length * animState.typewriterProgress).toInt().coerceAtLeast(0)
            clip.text.substring(0, charCount)
        } else {
            clip.text
        }

        if (displayText.isEmpty()) return

        val bounds = Rect()
        paint.getTextBounds(displayText, 0, displayText.length, bounds)
        
        // Dynamic padding for shadow and background
        val hPadding = (clip.shadowBlur + Math.abs(clip.shadowOffsetX) + 30f).coerceAtLeast(30f)
        val vPadding = (clip.shadowBlur + Math.abs(clip.shadowOffsetY) + 30f).coerceAtLeast(30f)

        val bmpWidth = (bounds.width() + hPadding * 2).toInt()
        val bmpHeight = (bounds.height() + vPadding * 2).toInt()
        
        if (bmpWidth <= 0 || bmpHeight <= 0) return

        val bitmap = Bitmap.createBitmap(bmpWidth, bmpHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)

        // Draw Background if enabled
        if (clip.isBackgroundEnabled && Color.alpha(clip.backgroundColor) > 0) {
            val bgPaint = Paint().apply {
                isAntiAlias = true
                color = clip.backgroundColor
                style = Paint.Style.FILL
            }
            // Baseline-independent background box
            val rect = RectF(
                hPadding - 15f, 
                vPadding - 5f, 
                hPadding + bounds.width() + 15f, 
                vPadding + bounds.height() + 5f
            )
            canvas.drawRoundRect(rect, clip.backgroundRadius, clip.backgroundRadius, bgPaint)
        }

        // Apply Shadow if enabled
        if (clip.isShadowEnabled && Color.alpha(clip.shadowColor) > 0 && clip.shadowBlur > 0) {
            paint.setShadowLayer(clip.shadowBlur, clip.shadowOffsetX, clip.shadowOffsetY, clip.shadowColor)
        }

        val textCenterX = bmpWidth / 2f
        // Vertical centering: bitmap center adjusted by text bounds center
        val textBaselineY = (bmpHeight / 2f) - ((bounds.top + bounds.bottom) / 2f)

        if (clip.strokeWidth > 0f) {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = clip.strokeWidth
            paint.strokeJoin = Paint.Join.ROUND
            
            // Draw Stroke
            paint.color = clip.strokeColor
            canvas.drawText(displayText, textCenterX, textBaselineY, paint)
            
            // Draw Fill
            paint.style = Paint.Style.FILL
            paint.color = clip.color
            canvas.drawText(displayText, textCenterX, textBaselineY, paint)
        } else {
            paint.style = Paint.Style.FILL
            paint.color = clip.color
            canvas.drawText(displayText, textCenterX, textBaselineY, paint)
        }


        val textureId = IntArray(1)
        GLES20.glGenTextures(1, textureId, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId[0])
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
        
        bitmap.recycle()

        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        
        GLES20.glUseProgram(program)

        // Compute position with animation offsets
        val finalScale = clip.scale * animState.scale
        val totalRotation = clip.rotation + animState.rotation
        
        val glX = ((clip.x + animState.offsetX) * 2 - 1)
        val glY = -((clip.y + animState.offsetY) * 2 - 1)
        
        // Ratio adjustment for OpenGL coordinates (-1 to 1) 
        val aspect = width.toFloat() / height.toFloat()
        val w = (bmpWidth.toFloat() / width) * 2 * finalScale
        val h = (bmpHeight.toFloat() / height) * 2 * finalScale

        // Original unrotated vertices
        val p1 = Pair(glX - w/2, glY + h/2)
        val p2 = Pair(glX - w/2, glY - h/2)
        val p3 = Pair(glX + w/2, glY + h/2)
        val p4 = Pair(glX + w/2, glY - h/2)

        // Apply rotation to vertices
        val r1 = rotatePoint(p1.first, p1.second, glX, glY, -totalRotation)
        val r2 = rotatePoint(p2.first, p2.second, glX, glY, -totalRotation)
        val r3 = rotatePoint(p3.first, p3.second, glX, glY, -totalRotation)
        val r4 = rotatePoint(p4.first, p4.second, glX, glY, -totalRotation)

        val vertices = floatArrayOf(
            r1.first, r1.second, 0f, 0f, 0f,
            r2.first, r2.second, 0f, 0f, 1f,
            r3.first, r3.second, 0f, 1f, 0f,
            r4.first, r4.second, 0f, 1f, 1f
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

        // Apply only opacity via shader, keep canvas colors
        val a = ((clip.color shr 24 and 0xFF) / 255f) * clip.opacity * animState.opacity
        GLES20.glUniform4f(vColorLoc, 1f, 1f, 1f, a)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId[0])
        GLES20.glUniform1i(sTextureLoc, 0)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDeleteTextures(1, textureId, 0)
    }

    private fun rotatePoint(x: Float, y: Float, cx: Float, cy: Float, angleDeg: Float): Pair<Float, Float> {
        val rad = Math.toRadians(angleDeg.toDouble()).toFloat()
        val s = Math.sin(rad.toDouble()).toFloat()
        val c = Math.cos(rad.toDouble()).toFloat()
        val dx = x - cx
        val dy = y - cy
        return Pair(dx * c - dy * s + cx, dx * s + dy * c + cy)
    }
}
