import '../../../models/editor_models.dart';
import 'throwback.dart';
import 'wavy.dart';
import 'gradient_wipe.dart';
import 'radial_wipe.dart';
import 'fade.dart';
import 'pop_in.dart';
import 'slide_up.dart';
import 'slide_left.dart';
import 'typewriter.dart';
import 'bounce.dart';
import 'spin_in.dart';
import 'cinematic.dart';
import 'elastic.dart';
import 'ripple.dart';
import 'smooth_slide.dart';
import 'char_slide.dart';
import 'edge_top.dart';
import 'edge_bottom.dart';
import 'stag_top.dart';
import 'stag_bottom.dart';
import 'edge_left.dart';
import 'edge_right.dart';
import 'stag_left.dart';
import 'stag_right.dart';
import 'elastic_stretch.dart';
import 'spiral_drop.dart';
import 'glitch.dart';
import 'flip3d_x.dart';
import 'flip3d_y.dart';
import 'spin3d.dart';

class AnimationPreset {
  final String name;
  final String icon;
  final ClipAnimation entrance;
  final ClipAnimation exit;

  const AnimationPreset({
    required this.name,
    required this.icon,
    required this.entrance,
    required this.exit,
  });
}

class AnimationPresets {
  static const List<AnimationPreset> all = [
    AnimationPreset(
      name: 'None',
      icon: '✕',
      entrance: ClipAnimation(type: AnimationType.none),
      exit: ClipAnimation(type: AnimationType.none),
    ),
    throwbackPreset,
    wavyPreset,
    gradientWipePreset,
    radialWipePreset,
    fadePreset,
    popInPreset,
    slideUpPreset,
    slideLeftPreset,
    typewriterPreset,
    bouncePreset,
    spinInPreset,
    cinematicPreset,
    elasticPreset,
    ripplePreset,
    smoothSlidePreset,
    charSlidePreset,
    edgeTopPreset,
    edgeBottomPreset,
    edgeLeftPreset,
    edgeRightPreset,
    stagTopPreset,
    stagBottomPreset,
    stagLeftPreset,
    stagRightPreset,
    elasticStretchPreset,
    spiralDropPreset,
    glitchPreset,
    flip3D_XPreset,
    flip3D_YPreset,
    spin3DPreset,
  ];

  static String animationTypeName(AnimationType type) {
    switch (type) {
      case AnimationType.none: return 'None';
      case AnimationType.fadeIn: return 'Fade In';
      case AnimationType.fadeOut: return 'Fade Out';
      case AnimationType.slideUp: return 'Slide Up';
      case AnimationType.slideDown: return 'Slide Down';
      case AnimationType.slideLeft: return 'Slide Left';
      case AnimationType.slideRight: return 'Slide Right';
      case AnimationType.scaleUp: return 'Scale Up';
      case AnimationType.scaleDown: return 'Scale Down';
      case AnimationType.typewriter: return 'Typewriter';
      case AnimationType.bounceIn: return 'Bounce In';
      case AnimationType.rotateIn: return 'Rotate In';
      case AnimationType.wobble: return 'Wobble';
      case AnimationType.shake: return 'Shake';
      case AnimationType.zoomIn: return 'Zoom In';
      case AnimationType.zoomOut: return 'Zoom Out';
      case AnimationType.flipX: return 'Flip X';
      case AnimationType.flipY: return 'Flip Y';
      case AnimationType.pulse: return 'Pulse';
      case AnimationType.bounce: return 'Bounce';
      case AnimationType.swing: return 'Swing';
      case AnimationType.spin: return 'Spin';
      case AnimationType.elasticDrop: return 'Elastic Drop';
      case AnimationType.heartbeat: return 'Heartbeat';
      case AnimationType.jello: return 'Jello';
      case AnimationType.gradientWipe: return 'Gradient Wipe';
      case AnimationType.radialWipe: return 'Radial Wipe';
      case AnimationType.throwback: return 'Throwback';
      case AnimationType.wavyBend: return 'Wavy Bend';
      case AnimationType.ripple: return 'Ripple';
      case AnimationType.smoothSlideUp: return 'Smooth Slide Up';
      case AnimationType.staggeredSlideUp: return 'Staggered Slide';
      case AnimationType.slideFromTop: return 'Edge Top';
      case AnimationType.slideFromBottom: return 'Edge Bottom';
      case AnimationType.slideFromLeft: return 'Edge Left';
      case AnimationType.slideFromRight: return 'Edge Right';
      case AnimationType.staggeredSlideFromTop: return 'Stag Top';
      case AnimationType.staggeredSlideFromBottom: return 'Stag Bottom';
      case AnimationType.staggeredSlideFromLeft: return 'Stag Left';
      case AnimationType.staggeredSlideFromRight: return 'Stag Right';
      case AnimationType.elasticStretch: return 'Motion Stretch';
      case AnimationType.spiralDrop: return 'Spring Zoom';
      case AnimationType.glitch: return 'Pendulum Swing';
      case AnimationType.flip3D_X: return '3D Flip X';
      case AnimationType.flip3D_Y: return '3D Flip Y';
      case AnimationType.spin3D: return '3D Spin Zoom';
    }
  }

  static String easingTypeName(EasingType type) {
    switch (type) {
      case EasingType.linear: return 'Linear';
      case EasingType.easeIn: return 'Ease In';
      case EasingType.easeOut: return 'Ease Out';
      case EasingType.easeInOut: return 'Ease In-Out';
      case EasingType.bounceOut: return 'Bounce';
      case EasingType.elasticOut: return 'Elastic';
      case EasingType.custom: return 'Custom';
      case EasingType.graph: return 'Graph';
    }
  }
}
