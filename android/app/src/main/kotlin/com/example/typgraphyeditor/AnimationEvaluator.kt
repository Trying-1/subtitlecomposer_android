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
        val elapsedSec = elapsed.toFloat() / 1000f
        val remaining = clip.endTime - currentTimeMs

        // 1. Calculate Base State from Keyframes or Properties
        val baseState = evaluateKeyframes(clip.keyframes, elapsedSec, clip)
        
        var opacity = baseState.opacity
        var offsetX = baseState.offsetX
        var offsetY = baseState.offsetY
        var scale = baseState.scale
        var scaleX = 1f
        var scaleY = 1f
        var rotation = baseState.rotation
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

    private fun evaluateKeyframes(keyframes: List<Keyframe>, timeOffset: Float, clip: SubtitleClip): AnimatedTextState {
        if (keyframes.isEmpty()) {
            return AnimatedTextState(
                opacity = clip.opacity,
                offsetX = 0f, 
                offsetY = 0f,
                scale = clip.scale,
                rotation = clip.rotation
                // Note: offsetX/offsetY in AnimatedTextState are RELATIVE to clip.x/y
                // But if we use keyframes, we might want absolute X/Y.
                // Let's stick to keyframes defining absolute positions (gl space or 0..1).
                // Actually, let's have keyframes define the base (opacity, scale, rot) 
                // and for X/Y we'll use them as offsets or absolute 0..1?
                // 0..1 is more powerful.
            )
        }

        val sorted = keyframes.sortedBy { it.timeOffset }
        
        // Find surrounding keyframes
        val nextIndex = sorted.indexOfFirst { it.timeOffset > timeOffset }
        
        if (nextIndex == 0) {
            val k = sorted.first()
            return AnimatedTextState(
                opacity = k.opacity ?: clip.opacity,
                offsetX = (k.x ?: clip.x) - clip.x,
                offsetY = (k.y ?: clip.y) - clip.y,
                scale = k.scale ?: clip.scale,
                rotation = k.rotation ?: clip.rotation
            )
        }
        
        if (nextIndex == -1) {
            val k = sorted.last()
            return AnimatedTextState(
                opacity = k.opacity ?: clip.opacity,
                offsetX = (k.x ?: clip.x) - clip.x,
                offsetY = (k.y ?: clip.y) - clip.y,
                scale = k.scale ?: clip.scale,
                rotation = k.rotation ?: clip.rotation
            )
        }

        val k1 = sorted[nextIndex - 1]
        val k2 = sorted[nextIndex]
        var t = (timeOffset - k1.timeOffset) / (k2.timeOffset - k1.timeOffset)
        
        t = applyEasing(t, k1.easing, k1)

        return AnimatedTextState(
            opacity = lerp(k1.opacity ?: clip.opacity, k2.opacity ?: clip.opacity, t),
            offsetX = lerp(k1.x ?: clip.x, k2.x ?: clip.x, t) - clip.x,
            offsetY = lerp(k1.y ?: clip.y, k2.y ?: clip.y, t) - clip.y,
            scale = lerp(k1.scale ?: clip.scale, k2.scale ?: clip.scale, t),
            rotation = lerp(k1.rotation ?: clip.rotation, k2.rotation ?: clip.rotation, t)
        )
    }

    private fun lerp(a: Float, b: Float, t: Float): Float = a + (b - a) * t
 
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

    private fun applyEasing(t: Float, easing: EasingType, keyframe: Keyframe? = null): Float {
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
            EasingType.CUSTOM -> solveCubicBezier(
                clamped,
                keyframe?.cp1x ?: 0.42f,
                keyframe?.cp1y ?: 0.0f,
                keyframe?.cp2x ?: 0.58f,
                keyframe?.cp2y ?: 1.0f
            )
            EasingType.GRAPH -> evaluateGraph(clamped, keyframe?.customGraphPoints)
        }
    }

    private fun evaluateGraph(t: Float, points: List<Float>?): Float {
        if (points == null || points.isEmpty()) return t
        
        val nodes = mutableListOf(Pair(0f, 0f))
        for (i in 0 until points.size step 2) {
            if (i + 1 < points.size) {
                nodes.add(Pair(points[i], points[i + 1]))
            }
        }
        nodes.add(Pair(1f, 1f))
        nodes.sortBy { it.first }

        val n = nodes.size
        if (n < 2) return t

        // Compute slopes
        val ms = FloatArray(n - 1)
        for (i in 0 until n - 1) {
            val dx = nodes[i + 1].first - nodes[i].first
            ms[i] = if (abs(dx) < 1e-6f) 0f else (nodes[i + 1].second - nodes[i].second) / dx
        }

        // Compute tangents (Monotone Cubic Hermite Spline)
        val ds = FloatArray(n)
        ds[0] = ms[0]
        ds[n - 1] = ms[n - 2]
        for (i in 1 until n - 1) {
            if (ms[i - 1] * ms[i] <= 0) {
                ds[i] = 0f
            } else {
                ds[i] = (ms[i - 1] + ms[i]) / 2f
            }
        }

        // Find segment
        var idx = 0
        while (idx < n - 2 && t > nodes[idx + 1].first) idx++

        val p1 = nodes[idx]
        val p2 = nodes[idx + 1]
        val h = p2.first - p1.first
        if (abs(h) < 1e-6f) return p2.second

        val lt = (t - p1.first) / h
        val lt2 = lt * lt
        val lt3 = lt2 * lt

        return (2 * lt3 - 3 * lt2 + 1) * p1.second +
               (lt3 - 2 * lt2 + lt) * h * ds[idx] +
               (-2 * lt3 + 3 * lt2) * p2.second +
               (lt3 - lt2) * h * ds[idx + 1]
    }

    private fun solveCubicBezier(x: Float, x1: Float, y1: Float, x2: Float, y2: Float): Float {
        if (x <= 0f) return 0f
        if (x >= 1f) return 1f

        var t = x
        for (i in 0 until 8) {
            val currentX = sampleBezier(t, x1, x2)
            val derivative = sampleBezierDerivative(t, x1, x2)
            if (abs(derivative) < 1e-6f) break
            t -= (currentX - x) / derivative
            t = t.coerceIn(0f, 1f)
        }

        return sampleBezier(t, y1, y2)
    }

    private fun sampleBezier(t: Float, p1: Float, p2: Float): Float {
        return 3f * p1 * t * (1f - t).pow(2) + 3f * p2 * t.pow(2) * (1f - t) + t.pow(3)
    }

    private fun sampleBezierDerivative(t: Float, p1: Float, p2: Float): Float {
        return (3f * p1 * (1f - t).pow(2)) - (6f * p1 * t * (1f - t)) + (6f * p2 * t * (1f - t)) - (3f * p2 * t.pow(2)) + (3f * t.pow(2))
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
