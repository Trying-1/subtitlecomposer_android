package com.typography.animations

import com.typography.AnimatedTextState
import com.typography.AnimationType
import com.typography.EasingType
import kotlin.math.*

/**
 * All easing / timing functions extracted into a single utility object.
 * Isolated so a bug in easing math doesn't pollute animation logic.
 */
object EasingFunctions {

    fun applyEasing(t: Float, easing: EasingType, keyframe: com.typography.Keyframe? = null): Float {
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

    fun bounceOut(t: Float): Float {
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

    fun elasticOut(t: Float): Float {
        if (t == 0f || t == 1f) return t
        return 2f.pow(-10f * t) * sin((t - 0.075f) * (2f * PI.toFloat()) / 0.3f) + 1f
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

        val ms = FloatArray(n - 1)
        for (i in 0 until n - 1) {
            val dx = nodes[i + 1].first - nodes[i].first
            ms[i] = if (abs(dx) < 1e-6f) 0f else (nodes[i + 1].second - nodes[i].second) / dx
        }

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

    private fun Float.pow(exp: Float): Float = this.toDouble().pow(exp.toDouble()).toFloat()
    private fun Float.pow(exp: Int): Float = this.toDouble().pow(exp).toFloat()
}
