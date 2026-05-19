package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateBounceIn(t: Float) = AnimatedTextState(scale = t, offsetY = 0.2f * (1f - t))
