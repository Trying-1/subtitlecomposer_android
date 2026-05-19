import '../base/animated_text_state.dart';

/// Effect-based loop animations: wavyBend (loop), ripple (loop).
/// These use typewriterProgress to communicate the wave phase to the renderer.
AnimatedTextState evaluateWavyBendLoop(int timeMs, int durationMs) {
  final safeD = durationMs > 0 ? durationMs : 100;
  final phase = (timeMs % safeD) / safeD.toDouble();
  return AnimatedTextState(typewriterProgress: phase);
}

AnimatedTextState evaluateRippleLoop(int timeMs, int durationMs) {
  final safeD = durationMs > 0 ? durationMs : 100;
  final phase = (timeMs % safeD) / safeD.toDouble();
  return AnimatedTextState(typewriterProgress: phase);
}
