import '../base/animated_text_state.dart';

/// Slide exit animations: slideUp, slideDown, slideLeft, slideRight.
/// Exit: t goes from 1 (still visible) to 0 (gone).
AnimatedTextState evaluateSlideUpExit(double t) {
  return AnimatedTextState(offsetY: -0.3 * (1.0 - t));
}

AnimatedTextState evaluateSlideDownExit(double t) {
  return AnimatedTextState(offsetY: 0.3 * (1.0 - t));
}

AnimatedTextState evaluateSlideLeftExit(double t) {
  return AnimatedTextState(offsetX: -0.5 * (1.0 - t));
}

AnimatedTextState evaluateSlideRightExit(double t) {
  return AnimatedTextState(offsetX: 0.5 * (1.0 - t));
}
