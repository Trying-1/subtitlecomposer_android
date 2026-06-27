package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateSlideFromLeft(t: Float) = AnimatedTextState(offsetX = -1.0f * (1f - t))
