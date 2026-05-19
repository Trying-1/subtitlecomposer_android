import '../base/animated_text_state.dart';

AnimatedTextState evaluateRipple(int timeMs, int durationMs) {
  final safeD = durationMs > 0 ? durationMs : 100;
  final phase = (timeMs % safeD) / safeD.toDouble();
  return AnimatedTextState(typewriterProgress: phase);
}
