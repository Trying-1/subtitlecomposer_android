import '../base/animated_text_state.dart';

/// Scale-based entrance animations: scaleUp, scaleDown, bounceIn, rotateIn.
AnimatedTextState evaluateScaleUpEntrance(double t) {
  return AnimatedTextState(scale: t, opacity: t);
}

AnimatedTextState evaluateScaleDownEntrance(double t) {
  return AnimatedTextState(scale: 2.0 - t, opacity: t);
}

AnimatedTextState evaluateBounceInEntrance(double t) {
  return AnimatedTextState(scale: t, offsetY: 0.2 * (1.0 - t));
}

AnimatedTextState evaluateRotateInEntrance(double t) {
  return AnimatedTextState(rotation: 360.0 * (1.0 - t), opacity: t, scale: t);
}
