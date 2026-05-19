package com.typography.animations.loop

import com.typography.AnimatedTextState
import kotlin.math.*

fun evaluateWobble(angle: Float): AnimatedTextState {
    val freq = 3f
    val rotIntensity = 5f
    val scaleIntensity = 0.05f
    return AnimatedTextState(
        rotation = sin(angle * freq) * rotIntensity,
        scale = 1f + sin(angle * freq * 0.6f) * scaleIntensity
    )
}
