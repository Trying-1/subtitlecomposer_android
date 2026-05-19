import '../base/animated_text_state.dart';

/// Scale-based exit animations: scaleUp, scaleDown, bounceIn (exit), rotateIn (exit).
AnimatedTextState evaluateScaleUpExit(double t) {
  return AnimatedTextState(scale: t, opacity: t);
}

AnimatedTextState evaluateScaleDownExit(double t) {
  return AnimatedTextState(scale: 2.0 - t, opacity: t);
}

AnimatedTextState evaluateBounceInExit(double t) {
  return AnimatedTextState(scale: t, offsetY: -0.2 * (1.0 - t));
}

AnimatedTextState evaluateRotateInExit(double t) {
  return AnimatedTextState(rotation: -360.0 * (1.0 - t), opacity: t, scale: t);
}
