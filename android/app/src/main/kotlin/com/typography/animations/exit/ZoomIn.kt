package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateZoomIn(t: Float) = AnimatedTextState(scale = t * t, opacity = t)
