import '../../../models/editor_models.dart';
import '../base/animated_text_state.dart';
import 'fade_in.dart';
import 'slide_up.dart';
import 'slide_down.dart';
import 'slide_left.dart';
import 'slide_right.dart';
import 'scale_up.dart';
import 'scale_down.dart';
import 'bounce_in.dart';
import 'rotate_in.dart';
import 'zoom_in.dart';
import 'zoom_out.dart';
import 'flip_x.dart';
import 'flip_y.dart';
import 'gradient_wipe.dart';
import 'radial_wipe.dart';
import 'wavy_bend.dart';
import 'typewriter.dart';
import 'smooth_slide_up.dart';
import 'staggered_slide_up.dart';
import 'slide_from_top.dart';
import 'slide_from_bottom.dart';
import 'slide_from_left.dart';
import 'slide_from_right.dart';
import 'staggered_slide_from_top.dart';
import 'staggered_slide_from_bottom.dart';
import 'staggered_slide_from_left.dart';
import 'staggered_slide_from_right.dart';
import 'throwback.dart';
import 'elastic_drop.dart';
import 'elastic_stretch.dart';
import 'spiral_drop.dart';
import 'glitch.dart';
import 'flip3d_x.dart';
import 'flip3d_y.dart';
import 'spin3d.dart';

/// Entrance animation registry.
/// Dispatches to the individual animation files.
class EntranceRegistry {
  static AnimatedTextState evaluate(AnimationType type, double t) {
    return switch (type) {
      AnimationType.fadeIn => evaluateFadeIn(t),
      AnimationType.slideUp => evaluateSlideUp(t),
      AnimationType.slideDown => evaluateSlideDown(t),
      AnimationType.slideLeft => evaluateSlideLeft(t),
      AnimationType.slideRight => evaluateSlideRight(t),
      AnimationType.scaleUp => evaluateScaleUp(t),
      AnimationType.scaleDown => evaluateScaleDown(t),
      AnimationType.bounceIn => evaluateBounceIn(t),
      AnimationType.rotateIn => evaluateRotateIn(t),
      AnimationType.zoomIn => evaluateZoomIn(t),
      AnimationType.zoomOut => evaluateZoomOut(t),
      AnimationType.flipX => evaluateFlipX(t),
      AnimationType.flipY => evaluateFlipY(t),
      AnimationType.gradientWipe => evaluateGradientWipe(t),
      AnimationType.radialWipe => evaluateRadialWipe(t),
      AnimationType.wavyBend => evaluateWavyBend(t),
      AnimationType.typewriter => evaluateTypewriter(t),
      AnimationType.smoothSlideUp => evaluateSmoothSlideUp(t),
      AnimationType.staggeredSlideUp => evaluateStaggeredSlideUp(t),
      AnimationType.slideFromTop => evaluateSlideFromTop(t),
      AnimationType.slideFromBottom => evaluateSlideFromBottom(t),
      AnimationType.slideFromLeft => evaluateSlideFromLeft(t),
      AnimationType.slideFromRight => evaluateSlideFromRight(t),
      AnimationType.staggeredSlideFromTop => evaluateStaggeredSlideFromTop(t),
      AnimationType.staggeredSlideFromBottom => evaluateStaggeredSlideFromBottom(t),
      AnimationType.staggeredSlideFromLeft => evaluateStaggeredSlideFromLeft(t),
      AnimationType.staggeredSlideFromRight => evaluateStaggeredSlideFromRight(t),
      AnimationType.throwback => evaluateThrowback(t),
      AnimationType.elasticDrop => evaluateElasticDrop(t),
      AnimationType.elasticStretch => evaluateElasticStretch(t),
      AnimationType.spiralDrop => evaluateSpiralDrop(t),
      AnimationType.glitch => evaluateGlitch(t),
      AnimationType.flip3D_X => evaluateFlip3DX(t),
      AnimationType.flip3D_Y => evaluateFlip3DY(t),
      AnimationType.spin3D => evaluateSpin3D(t),
      _ => const AnimatedTextState(),
    };
  }
}
