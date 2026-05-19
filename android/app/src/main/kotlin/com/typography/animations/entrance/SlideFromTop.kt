package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateSlideFromTop(t: Float) = AnimatedTextState(offsetY = -1.0f * (1f - t))
