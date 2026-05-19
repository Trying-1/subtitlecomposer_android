package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateSlideUp(t: Float) = AnimatedTextState(offsetY = -0.3f * (1f - t))
