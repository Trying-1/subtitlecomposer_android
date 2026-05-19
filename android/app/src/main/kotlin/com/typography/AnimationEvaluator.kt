package com.typography

import com.typography.animations.EasingFunctions
import com.typography.animations.EntranceAnimations
import com.typography.animations.ExitAnimations
import com.typography.animations.LoopAnimations

/**
 * Slim animation orchestrator.
 * Delegates type-specific logic to modular animation files in the animations/ package.
 * Keeps only orchestration (keyframe evaluation + entrance/exit/loop blending) here.
 */
object AnimationEvaluator {

    fun evaluate(clip: SubtitleClip, currentTimeMs: Long): AnimatedTextState {
        if (currentTimeMs < clip.startTime || currentTimeMs > clip.endTime) {
            return AnimatedTextState(opacity = 0f)
        }

        val elapsed = currentTimeMs - clip.startTime
        val elapsedSec = elapsed.toFloat() / 1000f
        val remaining = clip.endTime - currentTimeMs

        // 1. Calculate Base State from Keyframes or Properties
        val baseState = evaluateKeyframes(clip.keyframes, elapsedSec, clip)
        
        var opacity = baseState.opacity
        var offsetX = baseState.offsetX
        var offsetY = baseState.offsetY
        var scale = baseState.scale
        var scaleX = 1f
        var scaleY = 1f
        var rotation = baseState.rotation
        var typewriterProgress = 1f
 
        // Entrance
        val entrance = clip.entranceAnimation
        if (entrance.type != AnimationType.NONE && elapsed < entrance.durationMs) {
            val t = EasingFunctions.applyEasing(elapsed.toFloat() / entrance.durationMs, entrance.easing)
            val state = EntranceAnimations.evaluate(entrance.type, t)
            opacity *= state.opacity
            offsetX += state.offsetX
            offsetY += state.offsetY
            scale *= state.scale
            scaleX *= state.scaleX
            scaleY *= state.scaleY
            rotation += state.rotation
            typewriterProgress = state.typewriterProgress
        }
 
        // Exit
        val exit = clip.exitAnimation
        if (exit.type != AnimationType.NONE && remaining < exit.durationMs) {
            val exitProgress = (exit.durationMs - remaining).toFloat() / exit.durationMs
            val t = EasingFunctions.applyEasing(exitProgress.coerceIn(0f, 1f), exit.easing)
            val state = ExitAnimations.evaluate(exit.type, t)
            opacity *= state.opacity
            offsetX += state.offsetX
            offsetY += state.offsetY
            scale *= state.scale
            scaleX *= state.scaleX
            scaleY *= state.scaleY
            rotation += state.rotation
        }
 
        // Loop
        val loop = clip.loopAnimation
        if (loop.type != AnimationType.NONE) {
            val state = LoopAnimations.evaluate(loop.type, currentTimeMs, loop.durationMs)
            offsetX += state.offsetX
            offsetY += state.offsetY
            rotation += state.rotation
            scale *= state.scale
            scaleX *= state.scaleX
            scaleY *= state.scaleY
            
            // For wavy bend or ripple loop, we need the typewriterProgress (used as phase)
            if (loop.type == AnimationType.WAVY_BEND || loop.type == AnimationType.RIPPLE) {
                typewriterProgress = state.typewriterProgress
            }
        }
 
        return AnimatedTextState(
            opacity = opacity.coerceIn(0f, 1f),
            offsetX = offsetX,
            offsetY = offsetY,
            scale = scale.coerceIn(0.01f, 10f),
            scaleX = scaleX,
            scaleY = scaleY,
            rotation = rotation,
            typewriterProgress = typewriterProgress.coerceIn(0f, 1f)
        )
    }

    // ── Keyframe Evaluation (orchestration logic, stays here) ──

    private fun evaluateKeyframes(keyframes: List<Keyframe>, timeOffset: Float, clip: SubtitleClip): AnimatedTextState {
        if (keyframes.isEmpty()) {
            return AnimatedTextState(
                opacity = clip.opacity,
                offsetX = 0f, 
                offsetY = 0f,
                scale = clip.scale,
                rotation = clip.rotation
            )
        }

        val sorted = keyframes.sortedBy { it.timeOffset }
        
        val nextIndex = sorted.indexOfFirst { it.timeOffset > timeOffset }
        
        if (nextIndex == 0) {
            val k = sorted.first()
            return AnimatedTextState(
                opacity = k.opacity ?: clip.opacity,
                offsetX = (k.x ?: clip.x) - clip.x,
                offsetY = (k.y ?: clip.y) - clip.y,
                scale = k.scale ?: clip.scale,
                rotation = k.rotation ?: clip.rotation
            )
        }
        
        if (nextIndex == -1) {
            val k = sorted.last()
            return AnimatedTextState(
                opacity = k.opacity ?: clip.opacity,
                offsetX = (k.x ?: clip.x) - clip.x,
                offsetY = (k.y ?: clip.y) - clip.y,
                scale = k.scale ?: clip.scale,
                rotation = k.rotation ?: clip.rotation
            )
        }

        val k1 = sorted[nextIndex - 1]
        val k2 = sorted[nextIndex]
        var t = (timeOffset - k1.timeOffset) / (k2.timeOffset - k1.timeOffset)
        
        t = EasingFunctions.applyEasing(t, k1.easing, k1)

        return AnimatedTextState(
            opacity = lerp(k1.opacity ?: clip.opacity, k2.opacity ?: clip.opacity, t),
            offsetX = lerp(k1.x ?: clip.x, k2.x ?: clip.x, t) - clip.x,
            offsetY = lerp(k1.y ?: clip.y, k2.y ?: clip.y, t) - clip.y,
            scale = lerp(k1.scale ?: clip.scale, k2.scale ?: clip.scale, t),
            rotation = lerp(k1.rotation ?: clip.rotation, k2.rotation ?: clip.rotation, t)
        )
    }

    private fun lerp(a: Float, b: Float, t: Float): Float = a + (b - a) * t
}
