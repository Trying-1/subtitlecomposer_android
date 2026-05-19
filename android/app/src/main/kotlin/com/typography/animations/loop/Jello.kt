package com.typography.animations.loop

import com.typography.AnimatedTextState
import kotlin.math.*

fun evaluateJello(angle: Float): AnimatedTextState {
    val freq = 2.5f
    val intensity = 0.15f
    val s = sin(angle * freq)
    return AnimatedTextState(
        scaleX = 1f + s * intensity,
        scaleY = 1f - s * intensity
    )
}
