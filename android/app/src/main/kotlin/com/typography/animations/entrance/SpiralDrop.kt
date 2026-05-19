package com.typography.animations.entrance

import com.typography.AnimatedTextState
import com.typography.EasingType
import com.typography.animations.EasingFunctions

fun evaluateSpiralDrop(t: Float): AnimatedTextState {
    val elasticT = EasingFunctions.applyEasing(t, EasingType.ELASTIC_OUT)
    
    val scale = 0.2f + 0.8f * elasticT
    val rotation = -8.0f * (1.0f - elasticT)
    
    return AnimatedTextState(
        opacity = (t * 4.0f).coerceIn(0f, 1f),
        scale = scale,
        rotation = rotation
    )
}
