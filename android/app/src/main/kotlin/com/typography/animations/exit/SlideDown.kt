package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateSlideDown(t: Float) = AnimatedTextState(offsetY = 0.3f * (1f - t))
