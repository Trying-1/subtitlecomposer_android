package com.example.typgraphyeditor

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLUtils
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

class BackgroundRenderer {
    private var program: Int = 0
    private var programOES: Int = 0
    
    private var textureId: Int = -1
    private var lastImagePath: String? = null
    
    private var vPositionLoc: Int = 0
    private var vTexCoordLoc: Int = 0
    private var uMVPMatrixLoc: Int = 0
    private var sTextureLoc: Int = 0
    
    private var vPositionOESLoc: Int = 0
    private var vTexCoordOESLoc: Int = 0
    private var uMVPMatrixOESLoc: Int = 0
    private var sTextureOESLoc: Int = 0
    
    private var imageWidth: Int = 0
    private var imageHeight: Int = 0
    
    private var scale: Float = 1f
    private var rotation: Float = 0f
    private var bgX: Float = 0f
    private var bgY: Float = 0f
    private var fillMode: Int = 0 // 0: cover, 1: fit, 2: center
    private var canvasWidth: Int = 1080
    private var canvasHeight: Int = 1920

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

    private val fragmentShaderCode = """
        precision mediump float;
        varying vec2 fTexCoord;
        uniform sampler2D sTexture;
        void main() {
            gl_FragColor = texture2D(sTexture, fTexCoord);
        }
    """.trimIndent()

    private val fragmentShaderOESCode = """
        #extension GL_OES_EGL_image_external : require
        precision mediump float;
        varying vec2 fTexCoord;
        uniform samplerExternalOES sTexture;
        void main() {
            gl_FragColor = texture2D(sTexture, fTexCoord);
        }
    """.trimIndent()

    private var vertexBuffer: FloatBuffer? = null
    private var texCoordBuffer: FloatBuffer? = null

    init {
        val vertices = floatArrayOf(
            -1f,  1f, 0f,
            -1f, -1f, 0f,
             1f,  1f, 0f,
             1f, -1f, 0f
        )
        vertexBuffer = ByteBuffer.allocateDirect(vertices.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply { put(vertices); position(0) }

        val texCoords = floatArrayOf(
            0f, 0f,
            0f, 1f,
            1f, 0f,
            1f, 1f
        )
        texCoordBuffer = ByteBuffer.allocateDirect(texCoords.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply { put(texCoords); position(0) }
    }

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
        
        vPositionOESLoc = GLES20.glGetAttribLocation(programOES, "vPosition")
        vTexCoordOESLoc = GLES20.glGetAttribLocation(programOES, "vTexCoord")
        uMVPMatrixOESLoc = GLES20.glGetUniformLocation(programOES, "uMVPMatrix")
        sTextureOESLoc = GLES20.glGetUniformLocation(programOES, "sTexture")
    }

    private var currentActiveProgram: Int = -1
    private fun useProgram(isOES: Boolean) {
        val p = if (isOES) programOES else program
        if (p != currentActiveProgram) {
            GLES20.glUseProgram(p)
            currentActiveProgram = p
        }
    }
    
    private fun getVPPos(isOES: Boolean) = if (isOES) vPositionOESLoc else vPositionLoc
    private fun getVTexPos(isOES: Boolean) = if (isOES) vTexCoordOESLoc else vTexCoordLoc
    private fun getUMVPPos(isOES: Boolean) = if (isOES) uMVPMatrixOESLoc else uMVPMatrixLoc
    private fun getSTexPos(isOES: Boolean) = if (isOES) sTextureOESLoc else sTextureLoc

    private var movie: android.graphics.Movie? = null
    private var movieBitmap: Bitmap? = null
    private var movieCanvas: android.graphics.Canvas? = null
    private var isGif: Boolean = false
    private var videoDecoder: HardwareVideoDecoder? = null
    private var isVideo: Boolean = false

    fun setImage(path: String?) {
        if (path == lastImagePath) return
        lastImagePath = path

        movie = null
        isGif = false
        isVideo = false
        videoDecoder?.release()
        videoDecoder = null

        if (textureId != -1) {
            GLES20.glDeleteTextures(1, intArrayOf(textureId), 0)
            textureId = -1
        }

        if (path == null) return

        val file = File(path)
        if (!file.exists()) return

        val lowerPath = path.lowercase()
        if (lowerPath.endsWith(".gif")) {
            try {
                movie = android.graphics.Movie.decodeFile(path)
                if (movie != null) {
                    isGif = true
                    imageWidth = movie!!.width()
                    imageHeight = movie!!.height()
                    if (imageWidth <= 0) imageWidth = 720
                    if (imageHeight <= 0) imageHeight = 1280
                    
                    movieBitmap = Bitmap.createBitmap(imageWidth, imageHeight, Bitmap.Config.ARGB_8888)
                    movieCanvas = android.graphics.Canvas(movieBitmap!!)
                    
                    setupTexture()
                    return
                }
            } catch (e: Exception) {
                android.util.Log.e("BackgroundRenderer", "Error loading GIF: ${e.message}")
            }
        } else if (lowerPath.endsWith(".mp4") || lowerPath.endsWith(".mov") || lowerPath.endsWith(".mkv") || lowerPath.endsWith(".webm")) {
            videoDecoder = HardwareVideoDecoder()
            if (videoDecoder?.init(path) == true) {
                isVideo = true
                textureId = videoDecoder!!.getTextureId()
                imageWidth = videoDecoder!!.getWidth()
                imageHeight = videoDecoder!!.getHeight()
                videoDecoder?.updateFrame(0)
                return
            } else {
                videoDecoder = null
            }
        }

        val bitmap = BitmapFactory.decodeFile(path) ?: return
        imageWidth = bitmap.width
        imageHeight = bitmap.height
        
        setupTexture()
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
        bitmap.recycle()
    }

    private fun setupTexture() {
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        textureId = textures[0]

        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
    }

    fun setTransform(scale: Float, rotation: Float, bgX: Float, bgY: Float, fillMode: Int, canvasWidth: Int, canvasHeight: Int) {
        this.scale = scale
        this.rotation = rotation
        this.bgX = bgX
        this.bgY = bgY
        this.fillMode = fillMode
        this.canvasWidth = canvasWidth
        this.canvasHeight = canvasHeight
    }

    fun updateFrame(currentTimeMs: Long, timeoutUs: Long = 0) {
        if (isGif) {
            val m = movie ?: return
            val bmp = movieBitmap ?: return
            val canvas = movieCanvas ?: return
            
            val duration = m.duration()
            val time = if (duration > 0) (currentTimeMs % duration).toInt() else 0
            m.setTime(time)
            
            bmp.eraseColor(android.graphics.Color.TRANSPARENT)
            m.draw(canvas, 0f, 0f)
            
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bmp, 0)
        } else if (isVideo) {
            videoDecoder?.updateFrame(currentTimeMs, timeoutUs)
        }
    }

    fun draw() {
        if (textureId == -1) return

        useProgram(isVideo)

        val mvpMatrix = FloatArray(16)
        android.opengl.Matrix.setIdentityM(mvpMatrix, 0)
        
        if (canvasWidth > 0 && canvasHeight > 0) {
            val aspect = canvasWidth.toFloat() / canvasHeight
            
            val projection = FloatArray(16)
            android.opengl.Matrix.orthoM(projection, 0, -aspect, aspect, -1f, 1f, -1f, 1f)
            
            val model = FloatArray(16)
            android.opengl.Matrix.setIdentityM(model, 0)
            
            android.opengl.Matrix.translateM(model, 0, bgX * aspect, bgY, 0f)
            
            if (rotation != 0f) {
                android.opengl.Matrix.rotateM(model, 0, rotation, 0f, 0f, 1f)
            }
            
            if (imageWidth > 0 && imageHeight > 0) {
                val imgRatio = imageWidth.toFloat() / imageHeight
                
                var baseScaleX = 1f
                var baseScaleY = 1f
                
                when (fillMode) {
                    0 -> { // Cover
                        if (imgRatio > aspect) {
                            baseScaleX = imgRatio
                            baseScaleY = 1f
                        } else {
                            baseScaleX = aspect
                            baseScaleY = aspect / imgRatio
                        }
                    }
                    1 -> { // Fit
                        if (imgRatio > aspect) {
                            baseScaleX = aspect
                            baseScaleY = aspect / imgRatio
                        } else {
                            baseScaleX = imgRatio
                            baseScaleY = 1f
                        }
                    }
                    2 -> { // Center
                        val baselineHeight = 1080f
                        baseScaleX = imageWidth.toFloat() / baselineHeight
                        baseScaleY = imageHeight.toFloat() / baselineHeight
                    }
                }
                android.opengl.Matrix.scaleM(model, 0, baseScaleX * scale, baseScaleY * scale, 1f)
            } else {
                android.opengl.Matrix.scaleM(model, 0, scale, scale, 1f)
            }
            
            android.opengl.Matrix.multiplyMM(mvpMatrix, 0, projection, 0, model, 0)
        }

        GLES20.glUniformMatrix4fv(getUMVPPos(isVideo), 1, false, mvpMatrix, 0)

        GLES20.glEnableVertexAttribArray(getVPPos(isVideo))
        GLES20.glVertexAttribPointer(getVPPos(isVideo), 3, GLES20.GL_FLOAT, false, 12, vertexBuffer)

        GLES20.glEnableVertexAttribArray(getVTexPos(isVideo))
        GLES20.glVertexAttribPointer(getVTexPos(isVideo), 2, GLES20.GL_FLOAT, false, 8, texCoordBuffer)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(if (isVideo) GLES11Ext.GL_TEXTURE_EXTERNAL_OES else GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glUniform1i(getSTexPos(isVideo), 0)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(vPositionLoc)
        GLES20.glDisableVertexAttribArray(vTexCoordLoc)
    }

    private fun loadShader(type: Int, shaderCode: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, shaderCode)
        GLES20.glCompileShader(shader)
        return shader
    }
}
