package com.typography.animations

import com.typography.AnimatedTextState
import com.typography.AnimationType
import com.typography.animations.exit.*

/**
 * Exit animation dispatcher.
 * Delegates to individual Kotlin files in the exit/ package.
 */
object ExitAnimations {

    fun evaluate(type: AnimationType, t: Float): AnimatedTextState {
        return when (type) {
            AnimationType.FADE_OUT -> evaluateFadeOut(t)
            AnimationType.FADE_IN -> evaluateFadeIn(t)
            AnimationType.GRADIENT_WIPE -> evaluateGradientWipe(t)
            AnimationType.RADIAL_WIPE -> evaluateRadialWipe(t)
            AnimationType.WAVY_BEND -> evaluateWavyBend(t)
            AnimationType.THROWBACK -> evaluateThrowback(t)
            AnimationType.SLIDE_UP -> evaluateSlideUp(t)
            AnimationType.SLIDE_DOWN -> evaluateSlideDown(t)
            AnimationType.SLIDE_LEFT -> evaluateSlideLeft(t)
            AnimationType.SLIDE_RIGHT -> evaluateSlideRight(t)
            AnimationType.SCALE_UP -> evaluateScaleUp(t)
            AnimationType.SCALE_DOWN -> evaluateScaleDown(t)
            AnimationType.SMOOTH_SLIDE_UP -> evaluateSmoothSlideUp(t)
            AnimationType.STAGGERED_SLIDE_UP -> evaluateStaggeredSlideUp(t)
            AnimationType.BOUNCE_IN -> evaluateBounceIn(t)
            AnimationType.ROTATE_IN -> evaluateRotateIn(t)
            AnimationType.ZOOM_IN -> evaluateZoomIn(t)
            AnimationType.ZOOM_OUT -> evaluateZoomOut(t)
            AnimationType.FLIP_X -> evaluateFlipX(t)
            AnimationType.FLIP_Y -> evaluateFlipY(t)
            AnimationType.ELASTIC_DROP -> evaluateElasticDrop(t)
            AnimationType.SLIDE_FROM_TOP -> evaluateSlideFromTop(t)
            AnimationType.SLIDE_FROM_BOTTOM -> evaluateSlideFromBottom(t)
            AnimationType.SLIDE_FROM_LEFT -> evaluateSlideFromLeft(t)
            AnimationType.SLIDE_FROM_RIGHT -> evaluateSlideFromRight(t)
            AnimationType.STAGGERED_SLIDE_FROM_TOP -> evaluateStaggeredSlideFromTop(t)
            AnimationType.STAGGERED_SLIDE_FROM_BOTTOM -> evaluateStaggeredSlideFromBottom(t)
            AnimationType.STAGGERED_SLIDE_FROM_LEFT -> evaluateStaggeredSlideFromLeft(t)
            AnimationType.STAGGERED_SLIDE_FROM_RIGHT -> evaluateStaggeredSlideFromRight(t)
            else -> AnimatedTextState()
        }
    }
}
