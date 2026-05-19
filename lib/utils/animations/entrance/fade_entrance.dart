import '../base/animated_text_state.dart';

/// Fade entrance animation.
AnimatedTextState evaluateFadeEntrance(double t) {
  return AnimatedTextState(opacity: t);
}
