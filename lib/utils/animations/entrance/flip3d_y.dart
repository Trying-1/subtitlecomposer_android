import '../../base/animated_text_state.dart';

AnimatedTextState evaluateFlip3DY(double t) {
  final rotationY = -90.0 * (1.0 - t);
  final scale = 0.6 + 0.4 * t;
  return AnimatedTextState(
    opacity: t.clamp(0.0, 1.0),
    rotationY: rotationY,
    scale: scale,
  );
}
