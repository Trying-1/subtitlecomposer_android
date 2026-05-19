import '../base/animated_text_state.dart';

/// Slide entrance animations: slideUp, slideDown, slideLeft, slideRight.
AnimatedTextState evaluateSlideUpEntrance(double t) {
  return AnimatedTextState(offsetY: 0.3 * (1.0 - t));
}

AnimatedTextState evaluateSlideDownEntrance(double t) {
  return AnimatedTextState(offsetY: -0.3 * (1.0 - t));
}

AnimatedTextState evaluateSlideLeftEntrance(double t) {
  return AnimatedTextState(offsetX: 0.5 * (1.0 - t));
}

AnimatedTextState evaluateSlideRightEntrance(double t) {
  return AnimatedTextState(offsetX: -0.5 * (1.0 - t));
}
