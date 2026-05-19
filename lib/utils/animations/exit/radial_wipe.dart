import '../base/animated_text_state.dart';

AnimatedTextState evaluateRadialWipe(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}
