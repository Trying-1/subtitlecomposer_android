package com.typography.animations.loop

import com.typography.AnimatedTextState

fun evaluateRipple(timeMs: Long, durationMs: Int): AnimatedTextState {
    val phase = (timeMs % durationMs) / durationMs.toFloat()
    return AnimatedTextState(typewriterProgress = phase)
}
