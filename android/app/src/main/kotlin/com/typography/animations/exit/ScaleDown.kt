package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateScaleDown(t: Float) = AnimatedTextState(scale = 2f - t, opacity = t)
