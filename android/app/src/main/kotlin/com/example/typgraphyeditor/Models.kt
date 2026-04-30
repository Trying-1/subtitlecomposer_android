package com.example.typgraphyeditor

enum class AnimationType {
    NONE,
    FADE_IN,
    FADE_OUT,
    SLIDE_UP,
    SLIDE_DOWN,
    SLIDE_LEFT,
    SLIDE_RIGHT,
    SCALE_UP,
    SCALE_DOWN,
    TYPEWRITER,
    BOUNCE_IN,
    ROTATE_IN,
    WOBBLE,
    SHAKE,
    ZOOM_IN,
    ZOOM_OUT,
    FLIP_X,
    FLIP_Y,
    PULSE,
    BOUNCE,
    SWING,
    SPIN,
    ELASTIC_DROP,
    HEARTBEAT,
    JELLO;

    companion object {
        fun fromIndex(index: Int): AnimationType = entries.getOrElse(index) { NONE }
    }
}

enum class EasingType {
    LINEAR,
    EASE_IN,
    EASE_OUT,
    EASE_IN_OUT,
    BOUNCE_OUT,
    ELASTIC_OUT,
    CUSTOM,
    GRAPH;

    companion object {
        fun fromIndex(index: Int): EasingType = entries.getOrElse(index) { LINEAR }
    }
}

enum class CustomBlendMode {
    NORMAL,
    MULTIPLY,
    SCREEN,
    OVERLAY,
    DARKEN,
    LIGHTEN,
    COLOR_DODGE,
    COLOR_BURN,
    HARD_LIGHT,
    SOFT_LIGHT,
    DIFFERENCE,
    EXCLUSION;

    companion object {
        fun fromIndex(index: Int): CustomBlendMode = entries.getOrElse(index) { NORMAL }
    }
}

data class ClipAnimation(
    val type: AnimationType = AnimationType.NONE,
    val easing: EasingType = EasingType.EASE_OUT,
    val durationMs: Int = 500
) {
    companion object {
        fun fromMap(map: Map<String, Any>?): ClipAnimation {
            if (map == null) return ClipAnimation()
            return ClipAnimation(
                type = AnimationType.fromIndex((map["type"] as? Number)?.toInt() ?: 0),
                easing = EasingType.fromIndex((map["easing"] as? Number)?.toInt() ?: 0),
                durationMs = (map["durationMs"] as? Number)?.toInt() ?: 500
            )
        }
    }
}

data class Keyframe(
    val timeOffset: Float, // seconds
    val x: Float? = null,
    val y: Float? = null,
    val scale: Float? = null,
    val rotation: Float? = null,
    val opacity: Float? = null,
    val easing: EasingType = EasingType.LINEAR,
    val cp1x: Float? = null,
    val cp1y: Float? = null,
    val cp2x: Float? = null,
    val cp2y: Float? = null,
    val customGraphPoints: List<Float>? = null
) {
    companion object {
        fun fromMap(map: Map<String, Any>?): Keyframe? {
            if (map == null) return null
            return Keyframe(
                timeOffset = (map["timeOffset"] as? Number)?.toFloat() ?: 0f,
                x = (map["x"] as? Number)?.toFloat(),
                y = (map["y"] as? Number)?.toFloat(),
                scale = (map["scale"] as? Number)?.toFloat(),
                rotation = (map["rotation"] as? Number)?.toFloat(),
                opacity = (map["opacity"] as? Number)?.toFloat(),
                easing = EasingType.fromIndex((map["easing"] as? Number)?.toInt() ?: 0),
                cp1x = (map["cp1x"] as? Number)?.toFloat(),
                cp1y = (map["cp1y"] as? Number)?.toFloat(),
                cp2x = (map["cp2x"] as? Number)?.toFloat(),
                cp2y = (map["cp2y"] as? Number)?.toFloat(),
                customGraphPoints = (map["customGraphPoints"] as? List<*>)?.mapNotNull { (it as? Number)?.toFloat() }
            )
        }
    }
}

data class SubtitleClip(
    val id: String,
    val text: String,
    val startTime: Long,
    val endTime: Long,
    val x: Float,
    val y: Float,
    val fontSize: Float,
    val color: Int,
    val strokeColor: Int = 0xFF000000.toInt(),
    val strokeWidth: Float = 0f,
    val shadowColor: Int = 0x00000000,
    val shadowBlur: Float = 0f,
    val shadowOffsetX: Float = 0f,
    val shadowOffsetY: Float = 0f,
    val backgroundColor: Int = 0x00000000,
    val backgroundRadius: Float = 0f,
    val letterSpacing: Float = 0f,
    val rotation: Float = 0f,
    val scale: Float = 1f,
    val opacity: Float = 1f,
    val textOpacity: Float = 1f,
    val isShadowEnabled: Boolean = true,
    val isBackgroundEnabled: Boolean = true,
    val isStrokeEnabled: Boolean = false,
    val fontFamily: String = "Poppins",
    val entranceAnimation: ClipAnimation = ClipAnimation(),
    val exitAnimation: ClipAnimation = ClipAnimation(),
    val loopAnimation: ClipAnimation = ClipAnimation(),
    val blendMode: CustomBlendMode = CustomBlendMode.NORMAL,
    val keyframes: List<Keyframe> = emptyList(),
    val imagePath: String? = null,
    val isText: Boolean = true
)

/**
 * Holds the computed animation state for a single frame.
 */
data class AnimatedTextState(
    val opacity: Float = 1f,
    val offsetX: Float = 0f,
    val offsetY: Float = 0f,
    val scale: Float = 1f,
    val scaleX: Float = 1f,
    val scaleY: Float = 1f,
    val rotation: Float = 0f,
    val typewriterProgress: Float = 1f
)

data class AudioClip(
    val id: String,
    val audioPath: String,
    val startTime: Long,
    val endTime: Long,
    val volume: Float = 1.0f,
    val isMainAudio: Boolean = false
)
