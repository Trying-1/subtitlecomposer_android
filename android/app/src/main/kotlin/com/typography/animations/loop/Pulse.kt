package com.typography.animations.loop

import com.typography.AnimatedTextState
import kotlin.math.*

fun evaluatePulse(angle: Float): AnimatedTextState {
    val freq = 2f
    val scaleIntensity = 0.1f
    return AnimatedTextState(scale = 1f + sin(angle * freq) * scaleIntensity)
}
