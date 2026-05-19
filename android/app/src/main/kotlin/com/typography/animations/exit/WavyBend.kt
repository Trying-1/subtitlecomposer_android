package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateWavyBend(t: Float) = AnimatedTextState(typewriterProgress = 1f - t)
