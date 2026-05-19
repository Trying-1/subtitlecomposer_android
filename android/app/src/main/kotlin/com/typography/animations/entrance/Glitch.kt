package com.typography.animations.entrance

import com.typography.AnimatedTextState
import kotlin.math.cos

fun evaluateGlitch(t: Float): AnimatedTextState {
    if (t >= 1.0f) {
        return AnimatedTextState(
            opacity = 1f,
            offsetX = 0f,
            offsetY = 0f,
            scaleX = 1f,
            scaleY = 1f,
            rotation = 0f
        )
    }

    val p = 1.0f - t
    val offsetX = -0.25f * p * p
    val rotation = -15.0f * cos(t * 3.14159265f * 1.5f) * p

    return AnimatedTextState(
        opacity = t.coerceIn(0f, 1f),
        offsetX = offsetX,
        rotation = rotation
    )
}
