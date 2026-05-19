package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateStaggeredSlideFromTop(t: Float) = AnimatedTextState(typewriterProgress = 1f - t)
