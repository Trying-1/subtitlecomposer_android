import '../base/animated_text_state.dart';

/// Wipe exit animations: gradientWipe, radialWipe, wavyBend.
AnimatedTextState evaluateGradientWipeExit(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}

AnimatedTextState evaluateRadialWipeExit(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}

AnimatedTextState evaluateWavyBendExit(double t) {
  return AnimatedTextState(typewriterProgress: 1.0 - t);
}
