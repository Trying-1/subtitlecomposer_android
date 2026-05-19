import '../base/animated_text_state.dart';

/// Rotation-based loop animations: spin.
AnimatedTextState evaluateSpinLoop(int timeMs, int durationMs) {
  final safeD = durationMs > 0 ? durationMs : 100;
  final progress = (timeMs % safeD).toDouble() / safeD.toDouble();
  return AnimatedTextState(rotation: progress * 360.0);
}
