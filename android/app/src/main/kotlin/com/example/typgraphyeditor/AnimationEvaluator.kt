package com.example.typgraphyeditor

import kotlin.math.*

/**
 * Evaluates animation state for a clip at a given timestamp.
 * Mirrors the Dart AnimationEngine for native rendering consistency.
 */
object AnimationEvaluator {

    fun evaluate(clip: SubtitleClip, currentTimeMs: Long): AnimatedTextState {
        if (currentTimeMs < clip.startTime || currentTimeMs > clip.endTime) {
            return AnimatedTextState(opacity = 0f)
        }

        val elapsed = currentTimeMs - clip.startTime
        val remaining = clip.endTime - currentTimeMs

        var opacity = clip.opacity
        var offsetX = 0f
        var offsetY = 0f
        var scale = clip.scale
        var rotation = clip.rotation
        var typewriterProgress = 1f

        // Entrance
        val entrance = clip.entranceAnimation
        if (entrance.type != AnimationType.NONE && elapsed < entrance.durationMs) {
            val t = applyEasing(elapsed.toFloat() / entrance.durationMs, entrance.easing)
            val state = evaluateEntrance(entrance.type, t)
            opacity *= state.opacity
            offsetX += state.offsetX
            offsetY += state.offsetY
            scale *= state.scale
            rotation += state.rotation
            typewriterProgress = state.typewriterProgress
        }

        // Exit
        val exit = clip.exitAnimation
        if (exit.type != AnimationType.NONE && remaining < exit.durationMs) {
            val t = applyEasing(remaining.toFloat() / exit.durationMs, exit.easing)
            val state = evaluateExit(exit.type, t)
            opacity *= state.opacity
            offsetX += state.offsetX
            offsetY += state.offsetY
            scale *= state.scale
            rotation += state.rotation
        }

        return AnimatedTextState(
            opacity = opacity.coerceIn(0f, 1f),
            offsetX = offsetX,
            offsetY = offsetY,
            scale = scale.coerceIn(0.01f, 10f),
            rotation = rotation,
            typewriterProgress = typewriterProgress.coerceIn(0f, 1f)
        )
    }

    private fun evaluateEntrance(type: AnimationType, t: Float): AnimatedTextState {
        return when (type) {
            AnimationType.FADE_IN -> AnimatedTextState(opacity = t)
            AnimationType.SLIDE_UP -> AnimatedTextState(offsetY = 0.3f * (1f - t))
            AnimationType.SLIDE_DOWN -> AnimatedTextState(offsetY = -0.3f * (1f - t))
            AnimationType.SLIDE_LEFT -> AnimatedTextState(offsetX = 0.5f * (1f - t))
            AnimationType.SLIDE_RIGHT -> AnimatedTextState(offsetX = -0.5f * (1f - t))
            AnimationType.SCALE_UP -> AnimatedTextState(scale = t, opacity = t)
            AnimationType.SCALE_DOWN -> AnimatedTextState(scale = 2f - t, opacity = t)
            AnimationType.TYPEWRITER -> AnimatedTextState(typewriterProgress = t)
            AnimationType.BOUNCE_IN -> AnimatedTextState(scale = t, offsetY = 0.2f * (1f - t))
            AnimationType.ROTATE_IN -> AnimatedTextState(rotation = 360f * (1f - t), opacity = t, scale = t)
            else -> AnimatedTextState()
        }
    }

    private fun evaluateExit(type: AnimationType, t: Float): AnimatedTextState {
        return when (type) {
            AnimationType.FADE_OUT -> AnimatedTextState(opacity = t)
            AnimationType.FADE_IN -> AnimatedTextState(opacity = t)
            AnimationType.SLIDE_UP -> AnimatedTextState(offsetY = -0.3f * (1f - t))
            AnimationType.SLIDE_DOWN -> AnimatedTextState(offsetY = 0.3f * (1f - t))
            AnimationType.SLIDE_LEFT -> AnimatedTextState(offsetX = -0.5f * (1f - t))
            AnimationType.SLIDE_RIGHT -> AnimatedTextState(offsetX = 0.5f * (1f - t))
            AnimationType.SCALE_UP -> AnimatedTextState(scale = t, opacity = t)
            AnimationType.SCALE_DOWN -> AnimatedTextState(scale = 2f - t, opacity = t)
            AnimationType.BOUNCE_IN -> AnimatedTextState(scale = t, offsetY = -0.2f * (1f - t))
            AnimationType.ROTATE_IN -> AnimatedTextState(rotation = -360f * (1f - t), opacity = t, scale = t)
            else -> AnimatedTextState()
        }
    }

    private fun applyEasing(t: Float, easing: EasingType): Float {
        val clamped = t.coerceIn(0f, 1f)
        return when (easing) {
            EasingType.LINEAR -> clamped
            EasingType.EASE_IN -> clamped * clamped * clamped
            EasingType.EASE_OUT -> 1f - (1f - clamped).pow(3)
            EasingType.EASE_IN_OUT -> if (clamped < 0.5f) {
                4f * clamped * clamped * clamped
            } else {
                1f - (-2f * clamped + 2f).pow(3) / 2f
            }
            EasingType.BOUNCE_OUT -> bounceOut(clamped)
            EasingType.ELASTIC_OUT -> elasticOut(clamped)
        }
    }

    private fun bounceOut(t: Float): Float {
        var x = t
        return when {
            x < 1f / 2.75f -> 7.5625f * x * x
            x < 2f / 2.75f -> {
                x -= 1.5f / 2.75f
                7.5625f * x * x + 0.75f
            }
            x < 2.5f / 2.75f -> {
                x -= 2.25f / 2.75f
                7.5625f * x * x + 0.9375f
            }
            else -> {
                x -= 2.625f / 2.75f
                7.5625f * x * x + 0.984375f
            }
        }
    }

    private fun elasticOut(t: Float): Float {
        if (t == 0f || t == 1f) return t
        return 2f.pow(-10f * t) * sin((t - 0.075f) * (2f * PI.toFloat()) / 0.3f) + 1f
    }

    private fun Float.pow(exp: Float): Float = this.toDouble().pow(exp.toDouble()).toFloat()
    private fun Float.pow(exp: Int): Float = this.toDouble().pow(exp).toFloat()
}
