package com.typography.animations.exit

import com.typography.AnimatedTextState
import com.typography.EasingType
import com.typography.animations.EasingFunctions

fun evaluateElasticDrop(t: Float): AnimatedTextState {
    val dropOffset = 2.0f * (1f - EasingFunctions.applyEasing(t, EasingType.ELASTIC_OUT))
    return AnimatedTextState(offsetY = dropOffset, opacity = t)
}
