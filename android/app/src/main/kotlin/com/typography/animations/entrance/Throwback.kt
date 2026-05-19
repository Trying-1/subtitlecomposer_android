package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateThrowback(t: Float): AnimatedTextState {
    val s = 4.0f - 3.0f * t
    val o = if (t < 0.3f) t / 0.3f else 1.0f
    return AnimatedTextState(scale = s, opacity = o)
}
