package com.typography.animations.loop

import com.typography.AnimatedTextState
import kotlin.math.*

fun evaluateHeartbeat(t: Float, speedFactor: Float): AnimatedTextState {
    val freq = 1.2f * speedFactor
    val localT = (t * freq) % 1.0f
    val s = if (localT < 0.2f) {
        1f + sin(localT * 5f * PI.toFloat()) * 0.2f
    } else if (localT < 0.5f) {
        val t2 = (localT - 0.2f) * (1f / 0.3f)
        1f + sin(t2 * PI.toFloat()) * 0.1f
    } else {
        1f
    }
    return AnimatedTextState(scale = s)
}
