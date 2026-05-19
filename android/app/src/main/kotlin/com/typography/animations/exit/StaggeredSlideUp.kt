package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateStaggeredSlideUp(t: Float) = AnimatedTextState(typewriterProgress = 1f - t)
