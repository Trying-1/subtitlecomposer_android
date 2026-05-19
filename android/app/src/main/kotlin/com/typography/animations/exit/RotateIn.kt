package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateRotateIn(t: Float) = AnimatedTextState(rotation = -360f * (1f - t), opacity = t, scale = t)
