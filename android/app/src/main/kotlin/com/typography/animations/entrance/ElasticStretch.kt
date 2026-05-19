package com.typography.animations.entrance

import com.typography.AnimatedTextState
import com.typography.EasingType
import com.typography.animations.EasingFunctions
import kotlin.math.cos

fun evaluateElasticStretch(t: Float): AnimatedTextState {
    val easeT = EasingFunctions.applyEasing(t, EasingType.EASE_OUT)
    val elasticT = EasingFunctions.applyEasing(t, EasingType.ELASTIC_OUT)
    
    val offsetY = -0.3f * (1.0f - elasticT)
    val scaleX = 1.0f - 0.4f * (1.0f - easeT) * cos(t * 3.14159265f)
    val scaleY = 1.0f + 0.6f * (1.0f - easeT) * cos(t * 3.14159265f)
    
    return AnimatedTextState(
        opacity = t.coerceIn(0f, 1f),
        offsetY = offsetY,
        scaleX = scaleX,
        scaleY = scaleY
    )
}
