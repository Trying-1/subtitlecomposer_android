import '../base/animated_text_state.dart';

AnimatedTextState evaluateSpin3D(double t) {
  final rotationX = -180.0 * (1.0 - t);
  final rotationY = -180.0 * (1.0 - t);
  final scale = 0.2 + 0.8 * t;
  return AnimatedTextState(
    opacity: t.clamp(0.0, 1.0),
    rotationX: rotationX,
    rotationY: rotationY,
    scale: scale,
  );
}
