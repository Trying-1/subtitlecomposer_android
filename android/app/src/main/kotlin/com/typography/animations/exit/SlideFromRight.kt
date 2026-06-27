package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateSlideFromRight(t: Float) = AnimatedTextState(offsetX = 1.0f * (1f - t))
