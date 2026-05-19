package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateZoomOut(t: Float) = AnimatedTextState(scale = 1f + (1f - t) * 2f, opacity = t)
