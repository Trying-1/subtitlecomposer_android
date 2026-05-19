package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateRadialWipe(t: Float) = AnimatedTextState(typewriterProgress = 1f - t)
