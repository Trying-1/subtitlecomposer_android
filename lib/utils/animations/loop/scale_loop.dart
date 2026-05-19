import 'dart:math';
import '../base/animated_text_state.dart';

/// Scale-based loop animations: pulse, heartbeat, jello.
AnimatedTextState evaluatePulseLoop(double angle) {
  return AnimatedTextState(scale: 1.0 + 0.1 * sin(angle));
}

AnimatedTextState evaluateHeartbeatLoop(double t, double speedFactor) {
  final freq = 1.2 * speedFactor;
  final localT = (t * freq) % 1.0;
  double s;
  if (localT < 0.2) {
    s = 1.0 + sin(localT * 5.0 * pi) * 0.2;
  } else if (localT < 0.5) {
    final t2 = (localT - 0.2) * (1.0 / 0.3);
    s = 1.0 + sin(t2 * pi) * 0.1;
  } else {
    s = 1.0;
  }
  return AnimatedTextState(scale: s);
}

AnimatedTextState evaluateJelloLoop(double angle) {
  final intensity = 0.15;
  final s = sin(angle);
  // Jello uses asymmetric scale (scaleX/scaleY on native),
  // but on Dart side we approximate with uniform scale.
  return AnimatedTextState(scale: 1.0 + s * intensity);
}
