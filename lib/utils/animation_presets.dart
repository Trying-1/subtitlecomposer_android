import '../models/editor_models.dart';

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
    AnimationPreset(
      name: 'Throwback',
      icon: '🚀',
      entrance: ClipAnimation(type: AnimationType.throwback, durationMs: 600, easing: EasingType.easeOut),
      exit: ClipAnimation(type: AnimationType.throwback, durationMs: 400, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Wavy',
      icon: '🌊',
      entrance: ClipAnimation(type: AnimationType.wavyBend, durationMs: 800, easing: EasingType.easeOut),
      exit: ClipAnimation(type: AnimationType.wavyBend, durationMs: 500, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Grad Wipe',
      icon: '🌓',
      entrance: ClipAnimation(type: AnimationType.gradientWipe, durationMs: 700, easing: EasingType.easeInOut),
      exit: ClipAnimation(type: AnimationType.gradientWipe, durationMs: 500, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Radial',
      icon: '⭕',
      entrance: ClipAnimation(type: AnimationType.radialWipe, durationMs: 600, easing: EasingType.easeOut),
      exit: ClipAnimation(type: AnimationType.radialWipe, durationMs: 400, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Fade',
      icon: '◐',
      entrance: ClipAnimation(type: AnimationType.fadeIn, durationMs: 400, easing: EasingType.easeOut),
      exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 400, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Pop In',
      icon: '💥',
      entrance: ClipAnimation(type: AnimationType.scaleUp, durationMs: 300, easing: EasingType.bounceOut),
      exit: ClipAnimation(type: AnimationType.scaleDown, durationMs: 200, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Slide Up',
      icon: '⬆',
      entrance: ClipAnimation(type: AnimationType.slideUp, durationMs: 400, easing: EasingType.easeOut),
      exit: ClipAnimation(type: AnimationType.slideDown, durationMs: 300, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Slide Left',
      icon: '⬅',
      entrance: ClipAnimation(type: AnimationType.slideLeft, durationMs: 400, easing: EasingType.easeOut),
      exit: ClipAnimation(type: AnimationType.slideRight, durationMs: 300, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Typewriter',
      icon: '⌨',
      entrance: ClipAnimation(type: AnimationType.typewriter, durationMs: 800, easing: EasingType.linear),
      exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 300, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Bounce',
      icon: '⚡',
      entrance: ClipAnimation(type: AnimationType.bounceIn, durationMs: 500, easing: EasingType.bounceOut),
      exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 300, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Spin In',
      icon: '🌀',
      entrance: ClipAnimation(type: AnimationType.rotateIn, durationMs: 600, easing: EasingType.easeOut),
      exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 300, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Cinematic',
      icon: '🎬',
      entrance: ClipAnimation(type: AnimationType.fadeIn, durationMs: 800, easing: EasingType.easeInOut),
      exit: ClipAnimation(type: AnimationType.fadeOut, durationMs: 800, easing: EasingType.easeInOut),
    ),
    AnimationPreset(
      name: 'Elastic',
      icon: '🔮',
      entrance: ClipAnimation(type: AnimationType.scaleUp, durationMs: 600, easing: EasingType.elasticOut),
      exit: ClipAnimation(type: AnimationType.scaleDown, durationMs: 300, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Grad Wipe',
      icon: '🌓',
      entrance: ClipAnimation(type: AnimationType.gradientWipe, durationMs: 700, easing: EasingType.easeInOut),
      exit: ClipAnimation(type: AnimationType.gradientWipe, durationMs: 500, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Radial',
      icon: '⭕',
      entrance: ClipAnimation(type: AnimationType.radialWipe, durationMs: 600, easing: EasingType.easeOut),
      exit: ClipAnimation(type: AnimationType.radialWipe, durationMs: 400, easing: EasingType.easeIn),
    ),
    AnimationPreset(
      name: 'Ripple',
      icon: '💧',
      entrance: ClipAnimation(type: AnimationType.ripple, durationMs: 800, easing: EasingType.easeOut),
      exit: ClipAnimation(type: AnimationType.ripple, durationMs: 500, easing: EasingType.easeIn),
    ),
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
