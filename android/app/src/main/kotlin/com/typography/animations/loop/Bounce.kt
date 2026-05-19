package com.typography.animations.loop

import com.typography.AnimatedTextState
import kotlin.math.*

fun evaluateBounce(angle: Float): AnimatedTextState {
    val freq = 2f
    val intensity = 0.05f
    return AnimatedTextState(offsetY = abs(sin(angle * freq)) * -intensity)
}
