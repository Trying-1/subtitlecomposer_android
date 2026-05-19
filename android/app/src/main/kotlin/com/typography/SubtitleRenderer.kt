package com.typography

import android.graphics.*
import android.opengl.*
import android.graphics.BitmapFactory
import android.util.Log

class SubtitleRenderer(private var width: Int, private var height: Int) {
    private val gifCache = mutableMapOf<String, GifData>()
    private val hwVideoDecoderCache = mutableMapOf<String, HardwareVideoDecoder>()
    private val textureCache = mutableMapOf<String, Int>()
    private val dimensionCache = mutableMapOf<String, Pair<Int, Int>>()
    
    private val textTextureCache = mutableMapOf<String, CachedTextTexture>()
    private val prevPositionMap = mutableMapOf<String, PointF>()
    
    private val vertexBuffer: java.nio.FloatBuffer
    private val bendingVertexBuffer: java.nio.FloatBuffer
    private val bendingVertexCount: Int
    
    init {
        val vertices = floatArrayOf(
            -0.5f,  0.5f, 0f, 0f, 0f,
            -0.5f, -0.5f, 0f, 0f, 1f,
             0.5f,  0.5f, 0f, 1f, 0f,
             0.5f, -0.5f, 0f, 1f, 1f
        )
        vertexBuffer = java.nio.ByteBuffer.allocateDirect(vertices.size * 4)
            .order(java.nio.ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(vertices)
        vertexBuffer.position(0)

        // Bending grid: 30 segments along X
        val segments = 30
        bendingVertexCount = (segments + 1) * 2
        val bVertices = FloatArray(bendingVertexCount * 5)
        var bIdx = 0
        for (i in 0..segments) {
            val u = i.toFloat() / segments
            val x = u - 0.5f
            
            // Top vertex (v=0)
            bVertices[bIdx++] = x
            bVertices[bIdx++] = 0.5f
            bVertices[bIdx++] = 0f
            bVertices[bIdx++] = u
            bVertices[bIdx++] = 0f
            
            // Bottom vertex (v=1)
            bVertices[bIdx++] = x
            bVertices[bIdx++] = -0.5f
            bVertices[bIdx++] = 0f
            bVertices[bIdx++] = u
            bVertices[bIdx++] = 1f
        }
        bendingVertexBuffer = java.nio.ByteBuffer.allocateDirect(bVertices.size * 4)
            .order(java.nio.ByteOrder.nativeOrder())
            .asFloatBuffer()
            .put(bVertices)
        bendingVertexBuffer.position(0)
    }

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
    private var uEffectModeLoc: Int = 0
    private var uEffectColorLoc: Int = 0
    private var uTexelSizeLoc: Int = 0
    private var uStrokeWidthLoc: Int = 0
    private var uShadowBlurLoc: Int = 0
    private var uGlowSizeLoc: Int = 0
    private var uBendingAmountLoc: Int = 0
    private var uReflectionOffsetLoc: Int = 0
    private var uReflectionOpacityLoc: Int = 0
    private var uReflectionColorLoc: Int = 0
    private var uGradientEnabledLoc: Int = 0
    private var uGradientColor1Loc: Int = 0
    private var uGradientColor2Loc: Int = 0
    private var uGradientAngleLoc: Int = 0
    
    private var vPositionOESLoc: Int = 0
    private var vTexCoordOESLoc: Int = 0
    private var uMVPMatrixOESLoc: Int = 0
    private var sTextureOESLoc: Int = 0
    private var vColorOESLoc: Int = 0
    private var uEffectModeOESLoc: Int = 0
    private var uEffectColorOESLoc: Int = 0
    private var uTexelSizeOESLoc: Int = 0
    private var uStrokeWidthOESLoc: Int = 0
    private var uShadowBlurOESLoc: Int = 0
    private var uGlowSizeOESLoc: Int = 0
    private var uBendingAmountOESLoc: Int = 0
    private var uReflectionOffsetOESLoc: Int = 0
    private var uReflectionOpacityOESLoc: Int = 0
    private var uReflectionColorOESLoc: Int = 0
    private var uGradientEnabledOESLoc: Int = 0
    private var uGradientColor1OESLoc: Int = 0
    private var uGradientColor2OESLoc: Int = 0
    private var uGradientAngleOESLoc: Int = 0
    
    private var uWipeProgressLoc: Int = 0
    private var uWipeTypeLoc: Int = 0
    private var uWipeIntensityLoc: Int = 0
    private var uCharCountLoc: Int = 0
    
    private var uWipeTypeOESLoc: Int = 0
    private var uWipeProgressOESLoc: Int = 0
    private var uWipeIntensityOESLoc: Int = 0
    private var uCharCountOESLoc: Int = 0

    private val vertexShaderCode = """
        precision highp float;
        attribute vec4 vPosition;
        attribute vec2 vTexCoord;
        uniform mat4 uMVPMatrix;
        uniform float uBendingAmount;
        uniform mediump float uWipeProgress;
        uniform mediump float uCharCount;
        uniform mediump int uWipeType;
        varying vec2 fTexCoord;
        varying vec2 fTypewriterCoord;
        void main() {
            vec4 pos = vPosition;
            if (uBendingAmount > 0.001 || uBendingAmount < -0.001) {
                float x = vTexCoord.x - 0.5;
                pos.y += uBendingAmount * x * x;
            }
            if (uWipeType == 5) {
                float stagger = 0.5;
                float localT = clamp((uWipeProgress - (1.0 - vTexCoord.x) * stagger) / (1.0 - stagger), 0.0, 1.0);
                pos.y -= 0.4 * (1.0 - localT);
            }
            if (uWipeType == 7) { // Staggered Slide Up (Quantized)
                float stagger = 0.6;
                // Quantize X into blocks to simulate characters
                float blocks = max(uCharCount, 1.0);
                float qx = floor(vTexCoord.x * blocks) / blocks;
                float localT = clamp((uWipeProgress - (1.0 - qx) * stagger) / (1.0 - stagger), 0.0, 1.0);
                pos.y -= 0.4 * (1.0 - localT);
            }
            if (uWipeType == 8) { // Staggered Slide From Top
                float stagger = 0.6;
                float blocks = max(uCharCount, 1.0);
                float qx = floor(vTexCoord.x * blocks) / blocks;
                float localT = clamp((uWipeProgress - (1.0 - qx) * stagger) / (1.0 - stagger), 0.0, 1.0);
                pos.y -= 2.0 * (1.0 - localT); 
            }
            if (uWipeType == 9) { // Staggered Slide From Bottom
                float stagger = 0.6;
                float blocks = max(uCharCount, 1.0);
                float qx = floor(vTexCoord.x * blocks) / blocks;
                float localT = clamp((uWipeProgress - (qx) * stagger) / (1.0 - stagger), 0.0, 1.0);
                pos.y += 2.0 * (1.0 - localT); 
            }
            gl_Position = uMVPMatrix * pos;
            fTexCoord = vTexCoord;
            fTypewriterCoord = vTexCoord;
        }
    """.trimIndent()

    private val fragmentShaderCode = """
        precision mediump float;
        varying vec2 fTexCoord;
        varying vec2 fTypewriterCoord;
        uniform sampler2D sTexture;
        uniform vec4 vColor;
        uniform vec2 uBlurVector;
        
        uniform int uEffectMode; 
        uniform vec4 uEffectColor;
        uniform vec2 uTexelSize;
        uniform float uStrokeWidth;
        uniform float uShadowBlur;
        uniform float uGlowSize;
        uniform float uWipeProgress;
        uniform int uWipeType;
        uniform float uCharCount;
        uniform float uWipeIntensity;
        uniform float uReflectionOpacity;
        uniform vec4 uReflectionColor;
        
        uniform int uGradientEnabled;
        uniform vec4 uGradientColor1;
        uniform vec4 uGradientColor2;
        uniform float uGradientAngle;

        void main() {
            vec2 uv = fTexCoord;
            float alphaMod = 1.0;
            if (uWipeType == 1) { // Linear Wipe Right
                float softness = 0.15;
                alphaMod = 1.0 - smoothstep(uWipeProgress - softness, uWipeProgress, uv.x);
            } else if (uWipeType == 2) { // Radial Wipe
                float softness = 0.2;
                float dist = distance(uv, vec2(0.5, 0.5)) * 2.0; 
                alphaMod = 1.0 - smoothstep(uWipeProgress - softness, uWipeProgress, dist);
            } else if (uWipeType == 3) { // Wavy Bend
                float waveFreq = 8.0;
                float waveAmp = 0.04 * uWipeIntensity; // Using intensity
                float phase = uWipeProgress * 6.2832;
                uv.y += sin(uv.x * waveFreq + phase) * waveAmp;
                uv.x += cos(uv.y * waveFreq * 0.7 + phase * 1.3) * waveAmp * 0.5;
            } else if (uWipeType == 4) { // Ripple
                float dist = distance(uv, vec2(0.5, 0.5));
                float wave = sin(dist * 25.0 - uWipeProgress * 6.2832);
                uv += (uv - 0.5) * wave * 0.04 * uWipeIntensity; // Using intensity
            } else if (uWipeType == 5 || uWipeType == 7) { // Slide Up Staggered (Fade)
                float stagger = (uWipeType == 7) ? 0.6 : 0.5;
                float blocks = max(uCharCount, 1.0);
                float qx = (uWipeType == 7) ? floor(uv.x * blocks) / blocks : uv.x;
                float localT = clamp((uWipeProgress - (1.0 - qx) * stagger) / (1.0 - stagger), 0.0, 1.0);
                alphaMod *= localT;
            } else if (uWipeType == 8 || uWipeType == 9) { // Staggered Edge Slide (Fade)
                float stagger = 0.6;
                float blocks = max(uCharCount, 1.0);
                float qx = floor(uv.x * blocks) / blocks;
                float localT = clamp((uWipeProgress - (1.0 - qx) * stagger) / (1.0 - stagger), 0.0, 1.0);
                alphaMod *= localT;
            } else if (uWipeType == 6) { // Typewriter
                if (uv.x > uWipeProgress) discard;
            }
            
            uv = clamp(uv, 0.0, 1.0); // Prevent wrapping artifacts
            vec4 texColor = texture2D(sTexture, uv);
            
            vec4 finalColor = vColor;
            if (uGradientEnabled == 1) {
                float rad = uGradientAngle * 0.0174533; // deg to rad
                vec2 dir = vec2(cos(rad), sin(rad));
                float t = dot(uv - 0.5, dir) + 0.5;
                t = clamp(t, 0.0, 1.0);
                finalColor = mix(uGradientColor1, uGradientColor2, t);
                finalColor.a *= vColor.a;
            }

            if (uEffectMode == 1) { // Shadow mode
                float accumAlpha = 0.0;
                float totalWeight = 0.0;
                float blurRadius = uShadowBlur * 0.4; 
                for (float x = -1.0; x <= 1.0; x += 1.0) {
                    for (float y = -1.0; y <= 1.0; y += 1.0) {
                        float weight = 1.0 / (1.0 + x*x + y*y);
                        vec2 offset = vec2(x, y) * blurRadius * uTexelSize;
                        accumAlpha += texture2D(sTexture, uv + offset).a * weight;
                        totalWeight += weight;
                    }
                }
                float avgAlpha = accumAlpha / totalWeight;
                if (avgAlpha < 0.01) discard;
                gl_FragColor = vec4(uEffectColor.rgb, avgAlpha * uEffectColor.a * finalColor.a * alphaMod);
            } else if (uEffectMode == 2) { // Stroke mode
                if (texColor.a > 0.8) discard; 
                
                float maxAlpha = 0.0;
                // Optimized 8-sample stroke
                for (int i = 0; i < 8; i++) {
                    float a = float(i) * 0.78539; // 45 degrees
                    vec2 offset = vec2(cos(a), sin(a)) * uStrokeWidth * uTexelSize;
                    maxAlpha = max(maxAlpha, texture2D(sTexture, uv + offset).a);
                }
                
                if (maxAlpha < 0.01) discard;
                gl_FragColor = vec4(uEffectColor.rgb, maxAlpha * uEffectColor.a * finalColor.a * alphaMod);
            } else if (uEffectMode == 3) { // Glow mode
                float accumAlpha = 0.0;
                float totalWeight = 0.0;
                float blurRadius = uGlowSize * 0.8; 
                for (float x = -1.5; x <= 1.5; x += 1.0) {
                    for (float y = -1.5; y <= 1.5; y += 1.0) {
                        float dist = length(vec2(x, y));
                        float weight = exp(-dist * dist / 2.0);
                        vec2 offset = vec2(x, y) * blurRadius * uTexelSize;
                        accumAlpha += texture2D(sTexture, uv + offset).a * weight;
                        totalWeight += weight;
                    }
                }
                float avgAlpha = accumAlpha / totalWeight;
                if (avgAlpha < 0.01) discard;
                gl_FragColor = vec4(uEffectColor.rgb, avgAlpha * uEffectColor.a * finalColor.a * alphaMod * 1.5); // Boost glow
            } else if (uEffectMode == 4) { // Reflection mode
                vec2 reflUv = vec2(uv.x, 1.0 - uv.y);
                vec4 texSample = texture2D(sTexture, reflUv);
                float gradient = 1.0 - uv.y;
                gl_FragColor = texSample * finalColor * uReflectionColor * alphaMod * uReflectionOpacity * gradient;
            } else { 
                if (texColor.a < 0.01) discard;
                gl_FragColor = texColor * finalColor * alphaMod;
            }
        }
    """.trimIndent()

    private val fragmentShaderOESCode = """
        #extension GL_OES_EGL_image_external : require
        precision mediump float;
        varying vec2 fTexCoord;
        uniform samplerExternalOES sTexture;
        uniform vec4 vColor;
        
        uniform int uEffectMode; 
        uniform vec4 uEffectColor;
        uniform vec2 uTexelSize;
        uniform float uStrokeWidth;
        uniform float uShadowBlur;
        uniform float uGlowSize;
        uniform float uWipeProgress;
        uniform int uWipeType;
        uniform float uCharCount;
        uniform float uWipeIntensity;
        uniform float uReflectionOpacity;
        uniform vec4 uReflectionColor;
        
        uniform int uGradientEnabled;
        uniform vec4 uGradientColor1;
        uniform vec4 uGradientColor2;
        uniform float uGradientAngle;

        void main() {
            vec2 uv = fTexCoord;
            float alphaMod = 1.0;
            if (uWipeType == 1) {
                float softness = 0.15;
                alphaMod = 1.0 - smoothstep(uWipeProgress - softness, uWipeProgress, uv.x);
            } else if (uWipeType == 2) {
                float softness = 0.2;
                float dist = distance(uv, vec2(0.5, 0.5)) * 2.0;
                alphaMod = 1.0 - smoothstep(uWipeProgress - softness, uWipeProgress, dist);
            } else if (uWipeType == 3) { // Wavy Bend
                float waveFreq = 8.0;
                float waveAmp = 0.04 * uWipeIntensity;
                float phase = uWipeProgress * 6.2832;
                uv.y += sin(uv.x * waveFreq + phase) * waveAmp;
                uv.x += cos(uv.y * waveFreq * 0.7 + phase * 1.3) * waveAmp * 0.5;
            } else if (uWipeType == 4) { // Ripple
                float dist = distance(uv, vec2(0.5, 0.5));
                float wave = sin(dist * 25.0 - uWipeProgress * 6.2832);
                uv += (uv - 0.5) * wave * 0.04 * uWipeIntensity;
            } else if (uWipeType == 5 || uWipeType == 7) { // Slide Up Staggered (Fade)
                float stagger = (uWipeType == 7) ? 0.6 : 0.5;
                float blocks = max(uCharCount, 1.0);
                float qx = (uWipeType == 7) ? floor(uv.x * blocks) / blocks : uv.x;
                float localT = clamp((uWipeProgress - (1.0 - qx) * stagger) / (1.0 - stagger), 0.0, 1.0);
                alphaMod *= localT;
            } else if (uWipeType == 8 || uWipeType == 9) { // Staggered Edge Slide (Fade)
                float stagger = 0.6;
                float blocks = max(uCharCount, 1.0);
                float qx = floor(uv.x * blocks) / blocks;
                float localT = clamp((uWipeProgress - (1.0 - qx) * stagger) / (1.0 - stagger), 0.0, 1.0);
                alphaMod *= localT;
            } else if (uWipeType == 6) { // Typewriter
                if (uv.x > uWipeProgress) discard;
            }
            
            uv = clamp(uv, 0.0, 1.0); // Prevent wrapping artifacts
            if (alphaMod <= 0.0) discard;

            vec4 texColor = texture2D(sTexture, uv);
            
            vec4 finalColor = vColor;
            if (uGradientEnabled == 1) {
                float rad = uGradientAngle * 0.0174533; // deg to rad
                vec2 dir = vec2(cos(rad), sin(rad));
                float t = dot(uv - 0.5, dir) + 0.5;
                t = clamp(t, 0.0, 1.0);
                finalColor = mix(uGradientColor1, uGradientColor2, t);
                finalColor.a *= vColor.a;
            }

            if (uEffectMode == 1) { // Shadow mode
                float accumAlpha = 0.0;
                float totalWeight = 0.0;
                float blurRadius = uShadowBlur * 0.4; 
                for (float x = -1.0; x <= 1.0; x += 1.0) {
                    for (float y = -1.0; y <= 1.0; y += 1.0) {
                        float weight = 1.0 / (1.0 + x*x + y*y);
                        vec2 offset = vec2(x, y) * blurRadius * uTexelSize;
                        accumAlpha += texture2D(sTexture, uv + offset).a * weight;
                        totalWeight += weight;
                    }
                }
                float avgAlpha = accumAlpha / totalWeight;
                if (avgAlpha < 0.01) discard;
                gl_FragColor = vec4(uEffectColor.rgb, avgAlpha * uEffectColor.a * finalColor.a * alphaMod);
            } else if (uEffectMode == 2) { // Stroke mode
                if (texColor.a > 0.8) discard; 
                
                float maxAlpha = 0.0;
                for (int i = 0; i < 8; i++) {
                    float a = float(i) * 0.78539;
                    vec2 offset = vec2(cos(a), sin(a)) * uStrokeWidth * uTexelSize;
                    maxAlpha = max(maxAlpha, texture2D(sTexture, uv + offset).a);
                }
                
                if (maxAlpha < 0.01) discard;
                gl_FragColor = vec4(uEffectColor.rgb, maxAlpha * uEffectColor.a * finalColor.a * alphaMod);
            } else if (uEffectMode == 3) { // Glow mode
                float accumAlpha = 0.0;
                float totalWeight = 0.0;
                float blurRadius = uGlowSize * 0.8; 
                for (float x = -1.5; x <= 1.5; x += 1.0) {
                    for (float y = -1.5; y <= 1.5; y += 1.0) {
                        float dist = length(vec2(x, y));
                        float weight = exp(-dist * dist / 2.0);
                        vec2 offset = vec2(x, y) * blurRadius * uTexelSize;
                        accumAlpha += texture2D(sTexture, uv + offset).a * weight;
                        totalWeight += weight;
                    }
                }
                float avgAlpha = accumAlpha / totalWeight;
                if (avgAlpha < 0.01) discard;
                gl_FragColor = vec4(uEffectColor.rgb, avgAlpha * uEffectColor.a * finalColor.a * alphaMod * 1.5);
            } else if (uEffectMode == 4) { // Reflection mode
                vec2 reflUv = vec2(uv.x, 1.0 - uv.y);
                vec4 texSample = texture2D(sTexture, reflUv);
                float gradient = 1.0 - uv.y;
                gl_FragColor = texSample * finalColor * uReflectionColor * alphaMod * uReflectionOpacity * gradient;
            } else { 
                if (texColor.a < 0.01) discard;
                gl_FragColor = texColor * finalColor * alphaMod;
            }
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
        uEffectModeLoc = GLES20.glGetUniformLocation(program, "uEffectMode")
        uEffectColorLoc = GLES20.glGetUniformLocation(program, "uEffectColor")
        uTexelSizeLoc = GLES20.glGetUniformLocation(program, "uTexelSize")
        uStrokeWidthLoc = GLES20.glGetUniformLocation(program, "uStrokeWidth")
        uShadowBlurLoc = GLES20.glGetUniformLocation(program, "uShadowBlur")
        uGlowSizeLoc = GLES20.glGetUniformLocation(program, "uGlowSize")
        uBendingAmountLoc = GLES20.glGetUniformLocation(program, "uBendingAmount")
        uReflectionOffsetLoc = GLES20.glGetUniformLocation(program, "uReflectionOffset")
        uReflectionOpacityLoc = GLES20.glGetUniformLocation(program, "uReflectionOpacity")
        uReflectionColorLoc = GLES20.glGetUniformLocation(program, "uReflectionColor")
        uWipeProgressLoc = GLES20.glGetUniformLocation(program, "uWipeProgress")
        uWipeTypeLoc = GLES20.glGetUniformLocation(program, "uWipeType")
        uGradientEnabledLoc = GLES20.glGetUniformLocation(program, "uGradientEnabled")
        uGradientColor1Loc = GLES20.glGetUniformLocation(program, "uGradientColor1")
        uGradientColor2Loc = GLES20.glGetUniformLocation(program, "uGradientColor2")
        uGradientAngleLoc = GLES20.glGetUniformLocation(program, "uGradientAngle")
        uWipeIntensityLoc = GLES20.glGetUniformLocation(program, "uWipeIntensity")
        uCharCountLoc = GLES20.glGetUniformLocation(program, "uCharCount")
        
        vPositionOESLoc = GLES20.glGetAttribLocation(programOES, "vPosition")
        vTexCoordOESLoc = GLES20.glGetAttribLocation(programOES, "vTexCoord")
        uMVPMatrixOESLoc = GLES20.glGetUniformLocation(programOES, "uMVPMatrix")
        sTextureOESLoc = GLES20.glGetUniformLocation(programOES, "sTexture")
        vColorOESLoc = GLES20.glGetUniformLocation(programOES, "vColor")
        uEffectModeOESLoc = GLES20.glGetUniformLocation(programOES, "uEffectMode")
        uEffectColorOESLoc = GLES20.glGetUniformLocation(programOES, "uEffectColor")
        uTexelSizeOESLoc = GLES20.glGetUniformLocation(programOES, "uTexelSize")
        uStrokeWidthOESLoc = GLES20.glGetUniformLocation(programOES, "uStrokeWidth")
        uShadowBlurOESLoc = GLES20.glGetUniformLocation(programOES, "uShadowBlur")
        uGlowSizeOESLoc = GLES20.glGetUniformLocation(programOES, "uGlowSize")
        uBendingAmountOESLoc = GLES20.glGetUniformLocation(programOES, "uBendingAmount")
        uWipeProgressOESLoc = GLES20.glGetUniformLocation(programOES, "uWipeProgress")
        uWipeTypeOESLoc = GLES20.glGetUniformLocation(programOES, "uWipeType")
        uWipeIntensityOESLoc = GLES20.glGetUniformLocation(programOES, "uWipeIntensity")
        uCharCountOESLoc = GLES20.glGetUniformLocation(programOES, "uCharCount")
        uReflectionOffsetOESLoc = GLES20.glGetUniformLocation(programOES, "uReflectionOffset")
        uReflectionOpacityOESLoc = GLES20.glGetUniformLocation(programOES, "uReflectionOpacity")
        uReflectionColorOESLoc = GLES20.glGetUniformLocation(programOES, "uReflectionColor")
        uGradientEnabledOESLoc = GLES20.glGetUniformLocation(programOES, "uGradientEnabled")
        uGradientColor1OESLoc = GLES20.glGetUniformLocation(programOES, "uGradientColor1")
        uGradientColor2OESLoc = GLES20.glGetUniformLocation(programOES, "uGradientColor2")
        uGradientAngleOESLoc = GLES20.glGetUniformLocation(programOES, "uGradientAngle")

        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
    }

    private fun useProgram(isOES: Boolean) {
        val p = if (isOES) programOES else program
        GLES20.glUseProgram(p)
    }

    private fun loadShader(type: Int, shaderCode: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, shaderCode)
        GLES20.glCompileShader(shader)
        return shader
    }

    private fun setBlendMode(mode: Int) {
        GLES20.glBlendEquation(GLES20.GL_FUNC_ADD) // Default
        when (mode) {
            0 -> GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA) // Normal
            1 -> GLES20.glBlendFunc(GLES20.GL_DST_COLOR, GLES20.GL_ONE_MINUS_SRC_ALPHA) // Multiply
            2 -> GLES20.glBlendFunc(GLES20.GL_ONE, GLES20.GL_ONE_MINUS_SRC_COLOR) // Screen
            // Note: Advanced modes like Overlay/Dodge/Burn require shader-based blending 
            // which needs frame-buffer access or a more complex multi-pass setup.
            else -> GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        }
    }

    fun drawTextClip(
        clip: SubtitleClip,
        animState: AnimatedTextState = AnimatedTextState(),
        assetManager: android.content.res.AssetManager? = null
    ) {
        if (animState.opacity <= 0f) return

        if (clip.text.isEmpty()) return

        // Cache the raw text bitmap, but handle typewriter/wavy in shader
        val cacheKey = "${clip.id}_${clip.text}_${clip.fontSize}_${clip.fontFamily}_${clip.color}_" +
                       "${clip.isShadowEnabled}_${clip.shadowColor}_${clip.shadowBlur}_${clip.shadowOffsetX}_${clip.shadowOffsetY}_" +
                       "${clip.isStrokeEnabled}_${clip.strokeColor}_${clip.strokeWidth}_" +
                       "${clip.isBackgroundEnabled}_${clip.backgroundColor}_${clip.backgroundRadius}_" +
                       "${clip.letterSpacing}_${clip.textOpacity}"
        
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
            val baselineHeight = 1080f
            val effectiveFontSize = clip.fontSize // Design is based on 1080p baseline

            val paint = Paint().apply {
                isAntiAlias = true
                textSize = effectiveFontSize
                color = Color.WHITE
                textAlign = Paint.Align.CENTER
                letterSpacing = clip.letterSpacing / clip.fontSize
                if (assetManager != null) {
                    typeface = FontManager.getTypeface(assetManager, clip.fontFamily)
                }
            }

            val bounds = Rect()
            paint.getTextBounds(clip.text, 0, clip.text.length, bounds)
            
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
                val rect = RectF(
                    hPadding - 15f, 
                    vPadding - 5f, 
                    hPadding + bounds.width() + 15f, 
                    vPadding + bounds.height() + 5f
                )
                canvas.drawRoundRect(rect, clip.backgroundRadius, clip.backgroundRadius, bgPaint)
            }

            if (clip.isShadowEnabled && Color.alpha(clip.shadowColor) > 0) {
                val radius = if (clip.shadowBlur <= 0f) 0.1f else clip.shadowBlur
                paint.setShadowLayer(radius, clip.shadowOffsetX, clip.shadowOffsetY, clip.shadowColor)
            }

            val textCenterX = bmpWidth / 2f
            val textBaselineY = (bmpHeight / 2f) - ((bounds.top + bounds.bottom) / 2f)

            if (clip.isStrokeEnabled && clip.strokeWidth > 0f) {
                paint.style = Paint.Style.STROKE
                paint.strokeWidth = clip.strokeWidth
                paint.strokeJoin = Paint.Join.ROUND
                paint.strokeCap = Paint.Cap.ROUND
                paint.color = clip.strokeColor
                canvas.drawText(clip.text, textCenterX, textBaselineY, paint)
            }

            paint.style = Paint.Style.FILL
            val fillAlpha = (Color.alpha(clip.color) * clip.textOpacity).toInt()
            paint.color = Color.argb(fillAlpha, Color.red(clip.color), Color.green(clip.color), Color.blue(clip.color))
            canvas.drawText(clip.text, textCenterX, textBaselineY, paint)

            val textures = IntArray(1)
            GLES20.glGenTextures(1, textures, 0)
            textureId = textures[0]
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
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
        
        // Perspective warp matrix for local 3D perspective distortion
        val pWarp = FloatArray(16)
        android.opengl.Matrix.setIdentityM(pWarp, 0)
        pWarp[11] = -0.4f // Strong, gorgeous 3D perspective depth coefficient
        
        val temp = FloatArray(16)
        android.opengl.Matrix.multiplyMM(temp, 0, model, 0, pWarp, 0)
        System.arraycopy(temp, 0, model, 0, 16)
        
        val rotX = animState.rotationX
        val rotY = animState.rotationY
        val totalRotation = animState.rotation
        
        if (rotX != 0f) {
            android.opengl.Matrix.rotateM(model, 0, rotX, 1f, 0f, 0f)
        }
        if (rotY != 0f) {
            android.opengl.Matrix.rotateM(model, 0, rotY, 0f, 1f, 0f)
        }
        if (totalRotation != 0f) {
            android.opengl.Matrix.rotateM(model, 0, totalRotation, 0f, 0f, 1f)
        }
        
        val finalScale = animState.scale
        val baselineHeight = 1080f
        val logW = (bmpWidth.toFloat() / baselineHeight) * 2 * finalScale * animState.scaleX
        val logH = (bmpHeight.toFloat() / baselineHeight) * 2 * finalScale * animState.scaleY
        android.opengl.Matrix.scaleM(model, 0, logW, logH, 1f)
        
        android.opengl.Matrix.multiplyMM(mvpMatrix, 0, projection, 0, model, 0)
        useProgram(false)
        
        // Handle Wipe Animations
        var wipeType = 0 // Default typewriter
        when (clip.entranceAnimation.type) {
            AnimationType.GRADIENT_WIPE -> wipeType = 1
            AnimationType.RADIAL_WIPE -> wipeType = 2
            AnimationType.WAVY_BEND -> wipeType = 3
            AnimationType.SMOOTH_SLIDE_UP -> wipeType = 5
            AnimationType.STAGGERED_SLIDE_UP -> wipeType = 7
            AnimationType.STAGGERED_SLIDE_FROM_TOP -> wipeType = 8
            AnimationType.STAGGERED_SLIDE_FROM_BOTTOM -> wipeType = 9
            AnimationType.TYPEWRITER -> wipeType = 6
            else -> {}
        }
        // Loop animation can also drive the wave
        if (clip.loopAnimation.type == AnimationType.WAVY_BEND) wipeType = 3
        if (clip.loopAnimation.type == AnimationType.RIPPLE) wipeType = 4
        
        GLES20.glUniform1i(uWipeTypeLoc, wipeType)
        
        GLES20.glUniform1i(uGradientEnabledLoc, if (clip.isGradientEnabled) 1 else 0)
        if (clip.isGradientEnabled) {
            GLES20.glUniform4f(uGradientColor1Loc, 
                android.graphics.Color.red(clip.gradientColor1) / 255f,
                android.graphics.Color.green(clip.gradientColor1) / 255f,
                android.graphics.Color.blue(clip.gradientColor1) / 255f,
                android.graphics.Color.alpha(clip.gradientColor1) / 255f)
            GLES20.glUniform4f(uGradientColor2Loc, 
                android.graphics.Color.red(clip.gradientColor2) / 255f,
                android.graphics.Color.green(clip.gradientColor2) / 255f,
                android.graphics.Color.blue(clip.gradientColor2) / 255f,
                android.graphics.Color.alpha(clip.gradientColor2) / 255f)
            GLES20.glUniform1f(uGradientAngleLoc, clip.gradientAngle)
        }
        GLES20.glUniform1f(uWipeProgressLoc, animState.typewriterProgress)
        GLES20.glUniform1f(uCharCountLoc, clip.text.length.toFloat())
        GLES20.glUniform1f(uWipeIntensityLoc, if (clip.loopAnimation.type != AnimationType.NONE) clip.loopAnimation.intensity else clip.entranceAnimation.intensity)
        GLES20.glUniform2f(uTexelSizeLoc, 1f / bmpWidth, 1f / bmpHeight)

        GLES20.glUniform4f(vColorLoc, 
            android.graphics.Color.red(clip.color) / 255f,
            android.graphics.Color.green(clip.color) / 255f,
            android.graphics.Color.blue(clip.color) / 255f,
            (android.graphics.Color.alpha(clip.color) / 255f) * animState.opacity * clip.textOpacity)

        GLES20.glUniformMatrix4fv(uMVPMatrixLoc, 1, false, mvpMatrix, 0)
        
        // Pass Motion Blur Vector
        GLES20.glUniform2f(uBlurVectorLoc, blurX, blurY)
        
        GLES20.glUniform1f(uBendingAmountLoc, if (clip.isBendingEnabled) clip.bendingAmount else 0f)
        setBlendMode(clip.blendMode.ordinal)

        val activeBuffer = if (clip.isBendingEnabled || wipeType == 5 || wipeType == 7) bendingVertexBuffer else vertexBuffer
        val activeCount = if (clip.isBendingEnabled || wipeType == 5 || wipeType == 7) bendingVertexCount else 4

        activeBuffer.position(0)
        GLES20.glVertexAttribPointer(vPositionLoc, 3, GLES20.GL_FLOAT, false, 5 * 4, activeBuffer)
        GLES20.glEnableVertexAttribArray(vPositionLoc)
        
        activeBuffer.position(3)
        GLES20.glVertexAttribPointer(vTexCoordLoc, 2, GLES20.GL_FLOAT, false, 5 * 4, activeBuffer)
        GLES20.glEnableVertexAttribArray(vTexCoordLoc)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glUniform1i(sTextureLoc, 0)

        // Skip redundant GPU passes for text clips (they are baked into the bitmap)
        // Only do GPU shadow/stroke for image overlays
        if (!clip.isText) {
            // Pass 1: Shadow
            if (clip.isShadowEnabled && Color.alpha(clip.shadowColor) > 0) {
                val shadowMVP = FloatArray(16)
                val shadowModel = FloatArray(16)
                android.opengl.Matrix.setIdentityM(shadowModel, 0)
                
                val shadowGlX = glX + (clip.shadowOffsetX / width) * 2 * aspect
                val shadowGlY = glY - (clip.shadowOffsetY / height) * 2
                android.opengl.Matrix.translateM(shadowModel, 0, shadowGlX, shadowGlY, 0f)
                
                if (totalRotation != 0f) {
                    android.opengl.Matrix.rotateM(shadowModel, 0, totalRotation, 0f, 0f, 1f)
                }
                
                android.opengl.Matrix.scaleM(shadowModel, 0, logW, logH, 1f)
                android.opengl.Matrix.multiplyMM(shadowMVP, 0, projection, 0, shadowModel, 0)
                
                GLES20.glUniformMatrix4fv(uMVPMatrixLoc, 1, false, shadowMVP, 0)
                GLES20.glUniform1i(uEffectModeLoc, 1) // Shadow Mode
                GLES20.glUniform1f(uShadowBlurLoc, clip.shadowBlur)
                
                val sc = clip.shadowColor
                GLES20.glUniform4f(uEffectColorLoc, (sc shr 16 and 0xFF)/255f, (sc shr 8 and 0xFF)/255f, (sc and 0xFF)/255f, (sc shr 24 and 0xFF)/255f)
                
                GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)
            }

            // Pass 2: Stroke
            if (clip.isStrokeEnabled && clip.strokeWidth > 0f) {
                GLES20.glUniformMatrix4fv(uMVPMatrixLoc, 1, false, mvpMatrix, 0)
                GLES20.glUniform1i(uEffectModeLoc, 2) // Stroke Mode
                GLES20.glUniform1f(uStrokeWidthLoc, clip.strokeWidth)
                
                val sc = clip.strokeColor
                GLES20.glUniform4f(uEffectColorLoc, (sc shr 16 and 0xFF)/255f, (sc shr 8 and 0xFF)/255f, (sc and 0xFF)/255f, (sc shr 24 and 0xFF)/255f)
                
                GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)
            }
        }

        // Pass 3: Main Text
        GLES20.glUniformMatrix4fv(uMVPMatrixLoc, 1, false, mvpMatrix, 0)
        GLES20.glUniform1i(uEffectModeLoc, 0) // Normal Mode
        
        val a = if (clip.isText) {
            // Text color is already baked into the bitmap, so we only apply global and animation opacities
            animState.opacity
        } else {
            val tc = clip.color
            ((tc shr 24 and 0xFF) / 255f) * animState.opacity * clip.textOpacity
        }

        if (clip.isText) {
            GLES20.glUniform4f(vColorLoc, 1f, 1f, 1f, a)
        } else {
            val tc = clip.color
            GLES20.glUniform4f(vColorLoc, (tc shr 16 and 0xFF)/255f, (tc shr 8 and 0xFF)/255f, (tc and 0xFF)/255f, a)
        }
        
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)

        // Pass 4: Glow (Only for text)
        if (clip.isText && clip.isGlowEnabled && Color.alpha(clip.glowColor) > 0) {
            GLES20.glUniform1i(uEffectModeLoc, 3) // Glow Mode
            GLES20.glUniform1f(uGlowSizeLoc, clip.glowSize)
            val gc = clip.glowColor
            GLES20.glUniform4f(uEffectColorLoc, (gc shr 16 and 0xFF)/255f, (gc shr 8 and 0xFF)/255f, (gc and 0xFF)/255f, (gc shr 24 and 0xFF)/255f)
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)
        }

        // Pass 5: Reflection
        if (clip.isReflectionEnabled) {
            val reflMVP = FloatArray(16)
            val reflModel = FloatArray(16)
            android.opengl.Matrix.setIdentityM(reflModel, 0)
            
            // Reflection is flipped and offset down
            val reflGlX = glX
            val vPadding = if (clip.isText) (clip.shadowBlur + Math.abs(clip.shadowOffsetY) + 30f).coerceAtLeast(30f) else 0f
            val paddingGL = (vPadding / bmpHeight.toFloat().coerceAtLeast(1f)) * logH
            val reflGlY = glY - logH + paddingGL * 2 - (clip.reflectionOffset / height) * 2
            android.opengl.Matrix.translateM(reflModel, 0, reflGlX, reflGlY, 0f)
            
            if (totalRotation != 0f) {
                android.opengl.Matrix.rotateM(reflModel, 0, totalRotation, 0f, 0f, 1f)
            }
            
            android.opengl.Matrix.scaleM(reflModel, 0, logW, logH, 1f)
            android.opengl.Matrix.multiplyMM(reflMVP, 0, projection, 0, reflModel, 0)
            
            GLES20.glUniformMatrix4fv(uMVPMatrixLoc, 1, false, reflMVP, 0)
            GLES20.glUniform1i(uEffectModeLoc, 4) // Reflection Mode
            GLES20.glUniform1f(uReflectionOpacityLoc, clip.reflectionOpacity)
            val rc = clip.reflectionColor
            GLES20.glUniform4f(uReflectionColorLoc, (rc shr 16 and 0xFF)/255f, (rc shr 8 and 0xFF)/255f, (rc and 0xFF)/255f, (rc shr 24 and 0xFF)/255f)
            
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)
        }
        
        setBlendMode(0) // Reset to Normal
        
        // Don't delete texture here, it's cached!
    }

    fun drawImageClip(
        clip: SubtitleClip,
        animState: AnimatedTextState = AnimatedTextState(),
        currentTimeMs: Long = 0L,
        timeoutUs: Long = 0
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
            
            // Only update GIF texture if time changed enough
            val lastGifTime = textureCache["gif_time_${path}"] ?: -1
            if (time != lastGifTime) {
                gif.movie.setTime(time)
                gif.bitmap.eraseColor(Color.TRANSPARENT)
                gif.movie.draw(gif.canvas, 0f, 0f)
                
                var tex = textureCache["gif_tex_${path}"] ?: 0
                if (tex == 0) {
                    val t = IntArray(1)
                    GLES20.glGenTextures(1, t, 0)
                    tex = t[0]
                    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, tex)
                    GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
                    GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
                    textureCache["gif_tex_${path}"] = tex
                }
                
                GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, tex)
                GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, gif.bitmap, 0)
                textureCache["gif_time_${path}"] = time
                textureId = tex
            } else {
                textureId = textureCache["gif_tex_${path}"] ?: 0
            }
            
            bmpWidth = gif.bitmap.width
            bmpHeight = gif.bitmap.height
            isCached = true // Now it's cached!
        } else if (lowerPath.endsWith(".mp4") || lowerPath.endsWith(".mov") || lowerPath.endsWith(".mkv") || lowerPath.endsWith(".webm")) {
            val cacheKey = "${clip.id}_$path"
            val decoder = hwVideoDecoderCache.getOrPut(cacheKey) {
                HardwareVideoDecoder().apply { init(path) }
            }
            
            val rawTime = (currentTimeMs - clip.startTime).coerceAtLeast(0)
            val duration = decoder.getDurationMs()
            val clipTime = if (duration > 0) rawTime % duration else rawTime
            decoder.updateFrame(clipTime, timeoutUs)
            
            textureId = decoder.getTextureId()
            bmpWidth = decoder.getWidth()
            bmpHeight = decoder.getHeight()
            isCached = true
            isOES = true
        } else {
            textureId = textureCache[path] ?: 0
            if (textureId == 0) {
                val bitmap = BitmapFactory.decodeFile(path)
                if (bitmap != null) {
                    val tex = IntArray(1)
                    GLES20.glGenTextures(1, tex, 0)
                    GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, tex[0])
                    GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
                    GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
                    GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
                    dimensionCache[path] = Pair(bitmap.width, bitmap.height)
                    bitmap.recycle()
                    textureId = tex[0]
                    textureCache[path] = textureId
                }
            }
            val dims = dimensionCache[path] ?: Pair(1280, 720)
            bmpWidth = dims.first
            bmpHeight = dims.second
            isCached = true
            isOES = false
        }

        useProgram(isOES)
        
        val uMVP = if (isOES) uMVPMatrixOESLoc else uMVPMatrixLoc
        val sTex = if (isOES) sTextureOESLoc else sTextureLoc
        val vCol = if (isOES) vColorOESLoc else vColorLoc
        val uMode = if (isOES) uEffectModeOESLoc else uEffectModeLoc
        val uECol = if (isOES) uEffectColorOESLoc else uEffectColorLoc
        val uTSize = if (isOES) uTexelSizeOESLoc else uTexelSizeLoc
        val uSWidth = if (isOES) uStrokeWidthOESLoc else uStrokeWidthLoc
        val uSBlur = if (isOES) uShadowBlurOESLoc else uShadowBlurLoc
        val vPos = if (isOES) vPositionOESLoc else vPositionLoc
        val vTex = if (isOES) vTexCoordOESLoc else vTexCoordLoc

        val uWipeP = if (isOES) uWipeProgressOESLoc else uWipeProgressLoc
        val uWipeC = if (isOES) uCharCountOESLoc else uCharCountLoc
        val uWipeT = if (isOES) uWipeTypeOESLoc else uWipeTypeLoc
        val uReflO = if (isOES) uReflectionOpacityOESLoc else uReflectionOpacityLoc
        val uReflC = if (isOES) uReflectionColorOESLoc else uReflectionColorLoc
        val uGradE = if (isOES) uGradientEnabledOESLoc else uGradientEnabledLoc
        val uGradC1 = if (isOES) uGradientColor1OESLoc else uGradientColor1Loc
        val uGradC2 = if (isOES) uGradientColor2OESLoc else uGradientColor2Loc
        val uGradA = if (isOES) uGradientAngleOESLoc else uGradientAngleLoc

        GLES20.glUniform2f(uTSize, 1f / bmpWidth, 1f / bmpHeight)
        
        // Image/Overlay Wipe
        var wipeType = 0
        when (clip.entranceAnimation.type) {
            AnimationType.GRADIENT_WIPE -> wipeType = 1
            AnimationType.RADIAL_WIPE -> wipeType = 2
            AnimationType.WAVY_BEND -> wipeType = 3
            AnimationType.SMOOTH_SLIDE_UP -> wipeType = 5
            AnimationType.STAGGERED_SLIDE_UP -> wipeType = 7
            AnimationType.STAGGERED_SLIDE_FROM_TOP -> wipeType = 8
            AnimationType.STAGGERED_SLIDE_FROM_BOTTOM -> wipeType = 9
            AnimationType.TYPEWRITER -> wipeType = 6
            else -> {}
        }
        // Loop animation can also drive the wave
        if (clip.loopAnimation.type == AnimationType.WAVY_BEND) wipeType = 3
        if (clip.loopAnimation.type == AnimationType.RIPPLE) wipeType = 4
        
        GLES20.glUniform1i(uWipeT, wipeType)
        GLES20.glUniform1f(uWipeP, animState.typewriterProgress)
        GLES20.glUniform1f(uWipeC, 15f) // Default for images/video
        GLES20.glUniform1f(if (isOES) uWipeIntensityOESLoc else uWipeIntensityLoc, if (clip.loopAnimation.type != AnimationType.NONE) clip.loopAnimation.intensity else clip.entranceAnimation.intensity)
        
        GLES20.glUniform1i(uGradE, if (clip.isGradientEnabled) 1 else 0)
        if (clip.isGradientEnabled) {
            GLES20.glUniform4f(uGradC1, 
                android.graphics.Color.red(clip.gradientColor1) / 255f,
                android.graphics.Color.green(clip.gradientColor1) / 255f,
                android.graphics.Color.blue(clip.gradientColor1) / 255f,
                android.graphics.Color.alpha(clip.gradientColor1) / 255f)
            GLES20.glUniform4f(uGradC2, 
                android.graphics.Color.red(clip.gradientColor2) / 255f,
                android.graphics.Color.green(clip.gradientColor2) / 255f,
                android.graphics.Color.blue(clip.gradientColor2) / 255f,
                android.graphics.Color.alpha(clip.gradientColor2) / 255f)
            GLES20.glUniform1f(uGradA, clip.gradientAngle)
        }
        if (!isOES) {
            GLES20.glUniform2f(uBlurVectorLoc, 0f, 0f) 
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
        
        // Perspective warp matrix for local 3D perspective distortion
        val pWarp = FloatArray(16)
        android.opengl.Matrix.setIdentityM(pWarp, 0)
        pWarp[11] = -0.4f // Strong, gorgeous 3D perspective depth coefficient
        
        val temp = FloatArray(16)
        android.opengl.Matrix.multiplyMM(temp, 0, model, 0, pWarp, 0)
        System.arraycopy(temp, 0, model, 0, 16)
        
        val rotX = animState.rotationX
        val rotY = animState.rotationY
        val totalRotation = animState.rotation
        
        if (rotX != 0f) {
            android.opengl.Matrix.rotateM(model, 0, rotX, 1f, 0f, 0f)
        }
        if (rotY != 0f) {
            android.opengl.Matrix.rotateM(model, 0, rotY, 0f, 1f, 0f)
        }
        if (totalRotation != 0f) {
            android.opengl.Matrix.rotateM(model, 0, totalRotation, 0f, 0f, 1f)
        }
        
        val finalScale = animState.scale
        val imgAspect = bmpWidth.toFloat() / bmpHeight.toFloat().coerceAtLeast(1f)
        
        var logW = (2f * imgAspect) * finalScale * animState.scaleX
        var logH = 2f * finalScale * animState.scaleY

        if (clip.isBackground) {
            when (clip.fillMode) {
                0 -> { // Cover
                    if (imgAspect > aspect) {
                        logH = 2f * finalScale * animState.scaleY
                        logW = logH * imgAspect
                    } else {
                        logW = 2f * aspect * finalScale * animState.scaleX
                        logH = logW / imgAspect
                    }
                }
                1 -> { // Fit
                    if (imgAspect > aspect) {
                        logW = 2f * aspect * finalScale * animState.scaleX
                        logH = logW / imgAspect
                    } else {
                        logH = 2f * finalScale * animState.scaleY
                        logW = logH * imgAspect
                    }
                }
                2 -> { // Center
                    val baseline = 1080f
                    logW = (bmpWidth.toFloat() / baseline) * 2f * finalScale * animState.scaleX
                    logH = (bmpHeight.toFloat() / baseline) * 2f * finalScale * animState.scaleY
                }
            }
        }
        
        val a = animState.opacity
        GLES20.glUniform4f(vCol, 1f, 1f, 1f, a)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(if (isOES) android.opengl.GLES11Ext.GL_TEXTURE_EXTERNAL_OES else GLES20.GL_TEXTURE_2D, textureId)
        GLES20.glUniform1i(sTex, 0)

        val activeBuffer = if (clip.isBendingEnabled || clip.entranceAnimation.type == AnimationType.SMOOTH_SLIDE_UP || clip.entranceAnimation.type == AnimationType.STAGGERED_SLIDE_UP) bendingVertexBuffer else vertexBuffer
        val activeCount = if (clip.isBendingEnabled || clip.entranceAnimation.type == AnimationType.SMOOTH_SLIDE_UP || clip.entranceAnimation.type == AnimationType.STAGGERED_SLIDE_UP) bendingVertexCount else 4

        activeBuffer.position(0)
        GLES20.glVertexAttribPointer(vPos, 3, GLES20.GL_FLOAT, false, 5 * 4, activeBuffer)
        GLES20.glEnableVertexAttribArray(vPos)
        activeBuffer.position(3)
        GLES20.glVertexAttribPointer(vTex, 2, GLES20.GL_FLOAT, false, 5 * 4, activeBuffer)
        GLES20.glEnableVertexAttribArray(vTex)

        // Pass 1: Shadow
        if (clip.isShadowEnabled && Color.alpha(clip.shadowColor) > 0) {
            val shadowModel = FloatArray(16)
            android.opengl.Matrix.setIdentityM(shadowModel, 0)
            
            val shadowGlX = glX + (clip.shadowOffsetX / width) * 2 * aspect
            val shadowGlY = glY - (clip.shadowOffsetY / height) * 2
            android.opengl.Matrix.translateM(shadowModel, 0, shadowGlX, shadowGlY, 0f)
            
            if (totalRotation != 0f) {
                android.opengl.Matrix.rotateM(shadowModel, 0, totalRotation, 0f, 0f, 1f)
            }
            
            android.opengl.Matrix.scaleM(shadowModel, 0, logW, logH, 1f)
            
            val shadowMVP = FloatArray(16)
            android.opengl.Matrix.multiplyMM(shadowMVP, 0, projection, 0, shadowModel, 0)
            
            GLES20.glUniformMatrix4fv(uMVP, 1, false, shadowMVP, 0)
            GLES20.glUniform1i(uMode, 1) // Shadow Mode
            GLES20.glUniform1f(uSBlur, clip.shadowBlur)
            
            val sc = clip.shadowColor
            GLES20.glUniform4f(uECol, (sc shr 16 and 0xFF)/255f, (sc shr 8 and 0xFF)/255f, (sc and 0xFF)/255f, (sc shr 24 and 0xFF)/255f)
            
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)
        }

        // Pass 2: Stroke
        if (clip.isStrokeEnabled && clip.strokeWidth > 0f) {
            val strokeMVP = FloatArray(16)
            val strokeModel = FloatArray(16)
            android.opengl.Matrix.setIdentityM(strokeModel, 0)
            android.opengl.Matrix.translateM(strokeModel, 0, glX, glY, 0f)
            if (totalRotation != 0f) {
                android.opengl.Matrix.rotateM(strokeModel, 0, totalRotation, 0f, 0f, 1f)
            }
            android.opengl.Matrix.scaleM(strokeModel, 0, logW, logH, 1f)
            android.opengl.Matrix.multiplyMM(strokeMVP, 0, projection, 0, strokeModel, 0)
            
            GLES20.glUniformMatrix4fv(uMVP, 1, false, strokeMVP, 0)
            GLES20.glUniform1i(uMode, 2) // Stroke Mode
            GLES20.glUniform1f(uSWidth, clip.strokeWidth)
            
            val sc = clip.strokeColor
            GLES20.glUniform4f(uECol, (sc shr 16 and 0xFF)/255f, (sc shr 8 and 0xFF)/255f, (sc and 0xFF)/255f, (sc shr 24 and 0xFF)/255f)
            
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)
        }

        // Pass 3: Main image
        android.opengl.Matrix.scaleM(model, 0, logW, logH, 1f)
        android.opengl.Matrix.multiplyMM(mvpMatrix, 0, projection, 0, model, 0)
        GLES20.glUniformMatrix4fv(uMVP, 1, false, mvpMatrix, 0)
        GLES20.glUniform1i(uMode, 0) // Normal Mode
        GLES20.glUniform1f(if (isOES) uBendingAmountOESLoc else uBendingAmountLoc, if (clip.isBendingEnabled) clip.bendingAmount else 0f)
        
        if (clip is SubtitleClip) {
            setBlendMode(clip.blendMode.ordinal)
        }
        
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)

        // Pass 4: Glow
        if (clip.isGlowEnabled && Color.alpha(clip.glowColor) > 0) {
            GLES20.glUniform1i(uMode, 3) // Glow Mode
            GLES20.glUniform1f(if (isOES) uGlowSizeOESLoc else uGlowSizeLoc, clip.glowSize)
            val gc = clip.glowColor
            GLES20.glUniform4f(if (isOES) uEffectColorOESLoc else uEffectColorLoc, (gc shr 16 and 0xFF)/255f, (gc shr 8 and 0xFF)/255f, (gc and 0xFF)/255f, (gc shr 24 and 0xFF)/255f)
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)
        }

        // Pass 5: Reflection
        if (clip.isReflectionEnabled) {
            val reflMVP = FloatArray(16)
            val reflModel = FloatArray(16)
            android.opengl.Matrix.setIdentityM(reflModel, 0)
            
            // Reflection is flipped and offset down
            val reflGlX = glX
            val vPadding = if (clip.isText) (clip.shadowBlur + Math.abs(clip.shadowOffsetY) + 30f).coerceAtLeast(30f) else 0f
            val paddingGL = (vPadding / bmpHeight.toFloat().coerceAtLeast(1f)) * logH
            val reflGlY = glY - logH + paddingGL * 2 - (clip.reflectionOffset / height) * 2
            android.opengl.Matrix.translateM(reflModel, 0, reflGlX, reflGlY, 0f)
            
            if (totalRotation != 0f) {
                android.opengl.Matrix.rotateM(reflModel, 0, totalRotation, 0f, 0f, 1f)
            }
            
            android.opengl.Matrix.scaleM(reflModel, 0, logW, logH, 1f)
            android.opengl.Matrix.multiplyMM(reflMVP, 0, projection, 0, reflModel, 0)
            
            GLES20.glUniformMatrix4fv(uMVP, 1, false, reflMVP, 0)
            GLES20.glUniform1i(uMode, 4) // Reflection Mode
            GLES20.glUniform1f(uReflO, clip.reflectionOpacity)
            val rc = clip.reflectionColor
            GLES20.glUniform4f(uReflC, (rc shr 16 and 0xFF)/255f, (rc shr 8 and 0xFF)/255f, (rc and 0xFF)/255f, (rc shr 24 and 0xFF)/255f)
            
            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, activeCount)
        }
        
        if (clip is SubtitleClip) {
            setBlendMode(0) // Reset
        }
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
