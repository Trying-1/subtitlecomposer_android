package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateSlideLeft(t: Float) = AnimatedTextState(offsetX = -0.5f * (1f - t))
