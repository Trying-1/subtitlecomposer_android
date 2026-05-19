import '../base/animated_text_state.dart';

/// Wipe entrance animations: gradientWipe, radialWipe, wavyBend.
/// These use typewriterProgress to communicate the wipe phase to the renderer.
AnimatedTextState evaluateGradientWipeEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}

AnimatedTextState evaluateRadialWipeEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}

AnimatedTextState evaluateWavyBendEntrance(double t) {
  return AnimatedTextState(typewriterProgress: t);
}
