package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateSlideFromBottom(t: Float) = AnimatedTextState(offsetY = 1.0f * (1f - t))
