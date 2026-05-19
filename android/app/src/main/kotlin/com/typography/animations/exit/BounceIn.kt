package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateBounceIn(t: Float) = AnimatedTextState(scale = t, offsetY = -0.2f * (1f - t))
