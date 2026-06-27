import '../base/animated_text_state.dart';

AnimatedTextState evaluateFlip3DX(double t) {
  final rotationX = -90.0 * (1.0 - t);
  final scale = 0.6 + 0.4 * t;
  return AnimatedTextState(
    opacity: t.clamp(0.0, 1.0),
    rotationX: rotationX,
    scale: scale,
  );
}
