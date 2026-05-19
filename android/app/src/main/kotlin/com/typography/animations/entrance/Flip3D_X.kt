package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateFlip3DX(t: Float): AnimatedTextState {
    val rotationX = -90.0f * (1.0f - t)
    val scale = 0.6f + 0.4f * t
    return AnimatedTextState(
        opacity = t.coerceIn(0f, 1f),
        rotationX = rotationX,
        scale = scale
    )
}
