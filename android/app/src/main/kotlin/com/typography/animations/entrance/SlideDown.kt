package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateSlideDown(t: Float) = AnimatedTextState(offsetY = -0.3f * (1f - t))
