import 'package:flutter/material.dart';
import '../models/editor_models.dart';

class AnimationMetadata {
  final AnimationType type;
  final String label;
  final IconData icon;
  final String description;

  const AnimationMetadata({
    required this.type,
    required this.label,
    required this.icon,
    this.description = '',
  });
}

class AnimationLibrary {
  static const List<AnimationMetadata> entranceAnimations = [
    AnimationMetadata(
      type: AnimationType.none,
      label: 'None',
      icon: Icons.not_interested_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.fadeIn,
      label: 'Fade In',
      icon: Icons.blur_on_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideUp,
      label: 'Slide Up',
      icon: Icons.arrow_upward_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideDown,
      label: 'Slide Down',
      icon: Icons.arrow_downward_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideLeft,
      label: 'Slide Left',
      icon: Icons.arrow_back_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideRight,
      label: 'Slide Right',
      icon: Icons.arrow_forward_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.scaleUp,
      label: 'Scale Up',
      icon: Icons.zoom_in_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.scaleDown,
      label: 'Scale Down',
      icon: Icons.zoom_out_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.bounceIn,
      label: 'Bounce',
      icon: Icons.auto_graph_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.rotateIn,
      label: 'Rotate',
      icon: Icons.rotate_right_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.zoomIn,
      label: 'Zoom In',
      icon: Icons.zoom_in_map_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.zoomOut,
      label: 'Zoom Out',
      icon: Icons.zoom_out_map_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.flipX,
      label: 'Flip X',
      icon: Icons.flip_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.flipY,
      label: 'Flip Y',
      icon: Icons.flip_camera_android_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.elasticDrop,
      label: 'Elastic Drop',
      icon: Icons.south_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.gradientWipe,
      label: 'Grad Wipe',
      icon: Icons.wb_twilight_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.radialWipe,
      label: 'Radial',
      icon: Icons.track_changes_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.throwback,
      label: 'Throwback',
      icon: Icons.rocket_launch_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.wavyBend,
      label: 'Wavy Bend',
      icon: Icons.waves_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.ripple,
      label: 'Ripple',
      icon: Icons.blur_circular_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.smoothSlideUp,
      label: 'Smooth Slide',
      icon: Icons.auto_awesome_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.staggeredSlideUp,
      label: 'Char Slide',
      icon: Icons.format_strikethrough_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideFromTop,
      label: 'Edge Top',
      icon: Icons.expand_more_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideFromBottom,
      label: 'Edge Bottom',
      icon: Icons.expand_less_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.staggeredSlideFromTop,
      label: 'Stag Top',
      icon: Icons.keyboard_double_arrow_down_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.staggeredSlideFromBottom,
      label: 'Stag Bottom',
      icon: Icons.keyboard_double_arrow_up_rounded,
    ),
  ];

  static const List<AnimationMetadata> exitAnimations = [
    AnimationMetadata(
      type: AnimationType.none,
      label: 'None',
      icon: Icons.not_interested_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.fadeOut,
      label: 'Fade Out',
      icon: Icons.blur_off_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideUp,
      label: 'Slide Up',
      icon: Icons.arrow_upward_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideDown,
      label: 'Slide Down',
      icon: Icons.arrow_downward_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideLeft,
      label: 'Slide Left',
      icon: Icons.arrow_back_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideRight,
      label: 'Slide Right',
      icon: Icons.arrow_forward_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.scaleUp,
      label: 'Scale Up',
      icon: Icons.zoom_in_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.scaleDown,
      label: 'Scale Down',
      icon: Icons.zoom_out_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.zoomIn,
      label: 'Zoom In',
      icon: Icons.zoom_in_map_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.zoomOut,
      label: 'Zoom Out',
      icon: Icons.zoom_out_map_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.flipX,
      label: 'Flip X',
      icon: Icons.flip_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.flipY,
      label: 'Flip Y',
      icon: Icons.flip_camera_android_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.elasticDrop,
      label: 'Elastic Drop',
      icon: Icons.south_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.gradientWipe,
      label: 'Grad Wipe',
      icon: Icons.wb_twilight_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.radialWipe,
      label: 'Radial',
      icon: Icons.track_changes_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.throwback,
      label: 'Throwback',
      icon: Icons.rocket_launch_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.wavyBend,
      label: 'Wavy Bend',
      icon: Icons.waves_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.ripple,
      label: 'Ripple',
      icon: Icons.blur_circular_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.smoothSlideUp,
      label: 'Smooth Slide',
      icon: Icons.auto_awesome_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.staggeredSlideUp,
      label: 'Char Slide',
      icon: Icons.format_strikethrough_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideFromTop,
      label: 'Edge Top',
      icon: Icons.expand_more_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.slideFromBottom,
      label: 'Edge Bottom',
      icon: Icons.expand_less_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.staggeredSlideFromTop,
      label: 'Stag Top',
      icon: Icons.keyboard_double_arrow_down_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.staggeredSlideFromBottom,
      label: 'Stag Bottom',
      icon: Icons.keyboard_double_arrow_up_rounded,
    ),
  ];

  static const List<AnimationMetadata> loopAnimations = [
    AnimationMetadata(
      type: AnimationType.none,
      label: 'None',
      icon: Icons.not_interested_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.wobble,
      label: 'Wobble',
      icon: Icons.vibration_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.shake,
      label: 'Shake',
      icon: Icons.flash_on_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.pulse,
      label: 'Pulse',
      icon: Icons.favorite_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.bounce,
      label: 'Bounce',
      icon: Icons.expand_less_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.swing,
      label: 'Swing',
      icon: Icons.waves_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.spin,
      label: 'Spin',
      icon: Icons.sync_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.heartbeat,
      label: 'Heartbeat',
      icon: Icons.monitor_heart_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.jello,
      label: 'Jello',
      icon: Icons.animation_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.wavyBend,
      label: 'Wavy Bend',
      icon: Icons.waves_rounded,
    ),
    AnimationMetadata(
      type: AnimationType.ripple,
      label: 'Ripple',
      icon: Icons.blur_circular_rounded,
    ),
  ];
}
