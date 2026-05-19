package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateSmoothSlideUp(t: Float) = AnimatedTextState(typewriterProgress = 1f - t)
