package com.typography.animations.entrance

import com.typography.AnimatedTextState

fun evaluateZoomIn(t: Float) = AnimatedTextState(scale = t * t, opacity = t)
