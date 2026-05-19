package com.typography.animations.exit

import com.typography.AnimatedTextState

fun evaluateStaggeredSlideFromBottom(t: Float) = AnimatedTextState(typewriterProgress = 1f - t)
