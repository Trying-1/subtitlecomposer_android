import 'dart:math';
import '../../base/animated_text_state.dart';

AnimatedTextState evaluateGlitch(double t) {
  if (t >= 1.0) {
    return const AnimatedTextState(
      opacity: 1.0,
      offsetX: 0.0,
      offsetY: 0.0,
      scaleX: 1.0,
      scaleY: 1.0,
      rotation: 0.0,
    );
  }

  final p = 1.0 - t;
  final offsetX = -0.25 * p * p;
  final rotation = -15.0 * cos(t * pi * 1.5) * p; // Rocking pendulum swing

  return AnimatedTextState(
    opacity: t.clamp(0.0, 1.0),
    offsetX: offsetX,
    rotation: rotation,
  );
}
