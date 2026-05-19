package com.typography.animations

import com.typography.AnimatedTextState
import com.typography.AnimationType
import com.typography.animations.loop.*
import kotlin.math.*

/**
 * Loop animation dispatcher.
 * Delegates to individual Kotlin files in the loop/ package.
 */
object LoopAnimations {

    fun evaluate(type: AnimationType, timeMs: Long, durationMs: Int): AnimatedTextState {
        val safeD = durationMs.coerceAtLeast(100)
        val t = timeMs.toFloat() / 1000f
        val speedFactor = 1000f / safeD.toFloat()
        val angle = (t * 2f * PI.toFloat() * speedFactor)

        return when (type) {
            AnimationType.SHAKE -> evaluateShake(angle)
            AnimationType.WOBBLE -> evaluateWobble(angle)
            AnimationType.PULSE -> evaluatePulse(angle)
            AnimationType.BOUNCE -> evaluateBounce(angle)
            AnimationType.SWING -> evaluateSwing(angle)
            AnimationType.SPIN -> evaluateSpin(timeMs, safeD)
            AnimationType.HEARTBEAT -> evaluateHeartbeat(t, speedFactor)
            AnimationType.JELLO -> evaluateJello(angle)
            AnimationType.WAVY_BEND -> evaluateWavyBend(timeMs, safeD)
            AnimationType.RIPPLE -> evaluateRipple(timeMs, safeD)
            else -> AnimatedTextState()
        }
    }
}
