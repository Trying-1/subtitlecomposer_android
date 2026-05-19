package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateGradientWipe(t: Float) = AnimatedTextState(typewriterProgress = 1f - t)
