import 'dart:math';
import 'dart:ui';
import '../../../models/editor_models.dart';

/// All easing / timing functions extracted into a single utility class.
/// Isolated here so a bug in easing math doesn't pollute animation logic.
class EasingFunctions {
  /// Apply easing curve to a normalized t value.
  static double applyEasing(double t, EasingType easing, [Keyframe? keyframe]) {
    t = t.clamp(0.0, 1.0);
    switch (easing) {
      case EasingType.linear:
        return t;
      case EasingType.easeIn:
        return t * t * t;
      case EasingType.easeOut:
        return 1.0 - pow(1.0 - t, 3).toDouble();
      case EasingType.easeInOut:
        return t < 0.5
            ? 4 * t * t * t
            : 1.0 - pow(-2 * t + 2, 3).toDouble() / 2;
      case EasingType.bounceOut:
        return _bounceOut(t);
      case EasingType.elasticOut:
        return _elasticOut(t);
      case EasingType.custom:
        return _solveCubicBezier(
          t,
          keyframe?.cp1x ?? 0.42,
          keyframe?.cp1y ?? 0.0,
          keyframe?.cp2x ?? 0.58,
          keyframe?.cp2y ?? 1.0,
        );
      case EasingType.graph:
        return _solveGraph(t, keyframe?.customGraphPoints);
    }
  }

  static double _bounceOut(double t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    } else if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    } else {
      t -= 2.625 / 2.75;
      return 7.5625 * t * t + 0.984375;
    }
  }

  static double _elasticOut(double t) {
    if (t == 0.0 || t == 1.0) return t;
    return pow(2, -10 * t).toDouble() * sin((t - 0.075) * (2 * pi) / 0.3) + 1.0;
  }

  static double _solveCubicBezier(double x, double x1, double y1, double x2, double y2) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;

    double t = x;
    for (int i = 0; i < 8; i++) {
      final currentX = _sampleBezier(t, x1, x2);
      final derivative = _sampleBezierDerivative(t, x1, x2);
      if (derivative.abs() < 1e-6) break;
      t -= (currentX - x) / derivative;
      t = t.clamp(0.0, 1.0);
    }

    return _sampleBezier(t, y1, y2);
  }

  static double _sampleBezier(double t, double p1, double p2) {
    return 3 * p1 * t * pow(1 - t, 2) + 3 * p2 * pow(t, 2) * (1 - t) + pow(t, 3);
  }

  static double _sampleBezierDerivative(double t, double p1, double p2) {
    return (3 * p1 * pow(1 - t, 2)) -
        (6 * p1 * t * (1 - t)) +
        (6 * p2 * t * (1 - t)) -
        (3 * p2 * pow(t, 2)) +
        (3 * pow(t, 2));
  }

  static double _solveGraph(double t, List<double>? points) {
    if (points == null || points.isEmpty) return t;

    final nodes = <Offset>[const Offset(0, 0)];
    for (int i = 0; i < points.length; i += 2) {
      if (i + 1 < points.length) {
        nodes.add(Offset(points[i], points[i + 1]));
      }
    }
    nodes.add(const Offset(1, 1));
    nodes.sort((a, b) => a.dx.compareTo(b.dx));

    final n = nodes.length;
    if (n < 2) return t;

    // Compute slopes
    final ms = List.filled(n - 1, 0.0);
    for (int i = 0; i < n - 1; i++) {
      final dx = nodes[i + 1].dx - nodes[i].dx;
      ms[i] = dx == 0 ? 0 : (nodes[i + 1].dy - nodes[i].dy) / dx;
    }

    // Compute tangents (Monotone Cubic Hermite Spline)
    final ds = List.filled(n, 0.0);
    ds[0] = ms[0];
    ds[n - 1] = ms[n - 2];
    for (int i = 1; i < n - 1; i++) {
      if (ms[i - 1] * ms[i] <= 0) {
        ds[i] = 0;
      } else {
        ds[i] = (ms[i - 1] + ms[i]) / 2.0;
      }
    }

    // Find segment
    int idx = 0;
    while (idx < n - 2 && t > nodes[idx + 1].dx) {
      idx++;
    }

    final p1 = nodes[idx];
    final p2 = nodes[idx + 1];
    final h = p2.dx - p1.dx;
    if (h.abs() < 1e-6) return p2.dy;

    final lt = (t - p1.dx) / h;
    final lt2 = lt * lt;
    final lt3 = lt2 * lt;

    return (2 * lt3 - 3 * lt2 + 1) * p1.dy +
        (lt3 - 2 * lt2 + lt) * h * ds[idx] +
        (-2 * lt3 + 3 * lt2) * p2.dy +
        (lt3 - lt2) * h * ds[idx + 1];
  }
}
