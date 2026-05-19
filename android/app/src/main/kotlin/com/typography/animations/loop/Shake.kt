package com.typography.animations.loop

import com.typography.AnimatedTextState
import kotlin.math.*

fun evaluateShake(angle: Float): AnimatedTextState {
    val freq = 15f
    val intensity = 0.02f
    return AnimatedTextState(
        offsetX = sin(angle * freq) * intensity,
        offsetY = cos(angle * freq * 0.7f) * intensity
    )
}
