package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateSpin3D(t: Float): AnimatedTextState {
    val rotationX = -180.0f * (1.0f - t)
    val rotationY = -180.0f * (1.0f - t)
    val scale = 0.2f + 0.8f * t
    return AnimatedTextState(
        opacity = t.coerceIn(0f, 1f),
        rotationX = rotationX,
        rotationY = rotationY,
        scale = scale
    )
}
