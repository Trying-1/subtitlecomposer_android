package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateThrowback(t: Float): AnimatedTextState {
    val s = 1.0f + 3.0f * (1f - t)
    return AnimatedTextState(scale = s, opacity = t)
}
