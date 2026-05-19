package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateSlideRight(t: Float) = AnimatedTextState(offsetX = 0.5f * (1f - t))
