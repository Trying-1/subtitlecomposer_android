package com.typography.animations.loop

import com.typography.AnimatedTextState

fun evaluateSpin(timeMs: Long, durationMs: Int): AnimatedTextState {
    val progress = (timeMs % durationMs).toFloat() / durationMs.toFloat()
    return AnimatedTextState(rotation = progress * 360f)
}
