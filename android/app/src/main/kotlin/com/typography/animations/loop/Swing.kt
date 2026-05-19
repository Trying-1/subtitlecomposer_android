package com.typography.animations.loop

import com.typography.AnimatedTextState
import kotlin.math.*

fun evaluateSwing(angle: Float): AnimatedTextState {
    val freq = 1.5f
    val rotIntensity = 15f
    return AnimatedTextState(rotation = sin(angle * freq) * rotIntensity)
}
