package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateFlip3DY(t: Float): AnimatedTextState {
    val rotationY = -90.0f * (1.0f - t)
    val scale = 0.6f + 0.4f * t
    return AnimatedTextState(
        opacity = t.coerceIn(0f, 1f),
        rotationY = rotationY,
        scale = scale
    )
}
