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
        var scaleX = 1f
        var scaleY = 1f
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
            scaleX *= state.scaleX
            scaleY *= state.scaleY
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
            scaleX *= state.scaleX
            scaleY *= state.scaleY
            rotation += state.rotation
        }
 
        // Loop
        val loop = clip.loopAnimation
        if (loop.type != AnimationType.NONE) {
            val state = evaluateLoop(loop.type, currentTimeMs, loop.durationMs)
            offsetX += state.offsetX
            offsetY += state.offsetY
            rotation += state.rotation
            scale *= state.scale
            scaleX *= state.scaleX
            scaleY *= state.scaleY
        }
 
        return AnimatedTextState(
            opacity = opacity.coerceIn(0f, 1f),
            offsetX = offsetX,
            offsetY = offsetY,
            scale = scale.coerceIn(0.01f, 10f),
            scaleX = scaleX,
            scaleY = scaleY,
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
            AnimationType.ZOOM_IN -> AnimatedTextState(scale = t * t, opacity = t)
            AnimationType.ZOOM_OUT -> AnimatedTextState(scale = 1f + (1f - t) * 2f, opacity = t)
            AnimationType.FLIP_X -> AnimatedTextState(scaleX = t, opacity = t)
            AnimationType.FLIP_Y -> AnimatedTextState(scaleY = t, opacity = t)
            AnimationType.ELASTIC_DROP -> {
                // Drop from off-screen top (-2.0 normalized)
                val dropOffset = -2.0f * (1f - applyEasing(t, EasingType.ELASTIC_OUT))
                AnimatedTextState(offsetY = dropOffset, opacity = if (t < 0.1f) t * 10f else 1f)
            }
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
            AnimationType.ZOOM_IN -> AnimatedTextState(scale = t * t, opacity = t)
            AnimationType.ZOOM_OUT -> AnimatedTextState(scale = 1f + (1f - t) * 2f, opacity = t)
            AnimationType.FLIP_X -> AnimatedTextState(scaleX = t, opacity = t)
            AnimationType.FLIP_Y -> AnimatedTextState(scaleY = t, opacity = t)
            AnimationType.ELASTIC_DROP -> {
                // Drop out the bottom (2.0 normalized)
                val dropOffset = 2.0f * (1f - applyEasing(t, EasingType.ELASTIC_OUT))
                AnimatedTextState(offsetY = dropOffset, opacity = t)
            }
            else -> AnimatedTextState()
        }
    }
 
    private fun evaluateLoop(type: AnimationType, timeMs: Long, durationMs: Int): AnimatedTextState {
        val t = timeMs.toFloat() / 1000f
        val angle = (t * 2f * PI.toFloat())
        return when (type) {
            AnimationType.SHAKE -> {
                val freq = 15f
                val intensity = 0.02f
                AnimatedTextState(
                    offsetX = sin(angle * freq) * intensity,
                    offsetY = cos(angle * freq * 0.7f) * intensity
                )
            }
            AnimationType.WOBBLE -> {
                val freq = 3f
                val rotIntensity = 5f
                val scaleIntensity = 0.05f
                AnimatedTextState(
                    rotation = sin(angle * freq) * rotIntensity,
                    scale = 1f + sin(angle * freq * 0.6f) * scaleIntensity
                )
            }
            AnimationType.PULSE -> {
                val freq = 2f
                val scaleIntensity = 0.1f
                AnimatedTextState(scale = 1f + sin(angle * freq) * scaleIntensity)
            }
            AnimationType.BOUNCE -> {
                val freq = 2f
                val intensity = 0.05f
                AnimatedTextState(offsetY = abs(sin(angle * freq)) * -intensity)
            }
            AnimationType.SWING -> {
                val freq = 1.5f
                val rotIntensity = 15f
                AnimatedTextState(rotation = sin(angle * freq) * rotIntensity)
            }
            AnimationType.SPIN -> {
                val freq = 1f // 1 rotation per second
                AnimatedTextState(rotation = (timeMs % 1000) / 1000f * 360f)
            }
            AnimationType.HEARTBEAT -> {
                val freq = 1.2f
                val localT = (t * freq) % 1.0f
                val s = if (localT < 0.2f) {
                    1f + sin(localT * 5f * PI.toFloat()) * 0.2f
                } else if (localT < 0.5f) {
                    val t2 = (localT - 0.2f) * (1f / 0.3f)
                    1f + sin(t2 * PI.toFloat()) * 0.1f
                } else {
                    1f
                }
                AnimatedTextState(scale = s)
            }
            AnimationType.JELLO -> {
                val freq = 2.5f
                val intensity = 0.15f
                val s = sin(angle * freq)
                AnimatedTextState(
                    scaleX = 1f + s * intensity,
                    scaleY = 1f - s * intensity
                )
            }
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
