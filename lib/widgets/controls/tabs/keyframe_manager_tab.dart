import 'package:flutter/material.dart';
import 'dart:math';
import '../../../models/editor_models.dart';
import 'common/common_controls.dart';
import 'common/custom_bezier_editor.dart';

class KeyframeManagerTab extends StatefulWidget {
  final TimelineClip clip;
  final Duration currentPosition;
  final Function({List<Keyframe>? keyframes}) onUpdate;

  const KeyframeManagerTab({
    super.key,
    required this.clip,
    required this.currentPosition,
    required this.onUpdate,
  });

  @override
  State<KeyframeManagerTab> createState() => _KeyframeManagerTabState();
}

class _KeyframeManagerTabState extends State<KeyframeManagerTab> {
  int _activeSubTab = 0; // 0: POINTS, 1: SPEED

  @override
  Widget build(BuildContext context) {
    final relPosMs = (widget.currentPosition - widget.clip.startTime).inMilliseconds;
    final relPosSec = relPosMs / 1000.0;
    final isWithinClip = widget.currentPosition >= widget.clip.startTime && widget.currentPosition <= widget.clip.endTime;

    // Check if there's a keyframe already at/near this position
    final existingIndex = widget.clip.keyframes.indexWhere((k) => (k.timeOffset - relPosSec).abs() < 0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('KEYFRAME MANAGER', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            Row(
              children: [
                if (isWithinClip)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _addOrUpdateKeyframe(relPosSec, existingIndex),
                    icon: Icon(existingIndex >= 0 ? Icons.update_rounded : Icons.add_rounded, size: 12, color: Colors.deepPurpleAccent),
                    label: Text(
                      existingIndex >= 0 ? "UPDATE @ ${relPosSec.toStringAsFixed(2)}s" : "ADD @ ${relPosSec.toStringAsFixed(2)}s",
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ),
                if (widget.clip.keyframes.isNotEmpty)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => widget.onUpdate(keyframes: []),
                    child: const Text('CLEAR ALL', style: TextStyle(fontSize: 8, color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        CommonControls.buildSubTabBar(['POINTS', 'SPEED'], _activeSubTab, (index) {
          setState(() => _activeSubTab = index);
        }),
        const SizedBox(height: 16),

        _activeSubTab == 0 ? _buildPointsList() : _buildSpeedCurves(),
      ],
    );
  }

  Widget _buildPointsList() {
    if (widget.clip.keyframes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.diamond_outlined, size: 24, color: Colors.white10),
              SizedBox(height: 12),
              Text(
                "No keyframes added yet.\nMove the playhead over the clip and tap 'ADD' above.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.white24, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: widget.clip.keyframes.map((k) => _buildKeyframeItem(context, k)).toList(),
    );
  }

  Widget _buildSpeedCurves() {
    if (widget.clip.keyframes.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "Add at least 2 keyframes to configure\nspeed curves between them.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.white24, height: 1.5),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(widget.clip.keyframes.length - 1, (i) {
        return _buildCurveIntervalItem(widget.clip.keyframes[i], widget.clip.keyframes[i + 1]);
      }),
    );
  }

  Widget _buildCurveIntervalItem(Keyframe k1, Keyframe k2) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.linear_scale_rounded, size: 12, color: Colors.deepPurpleAccent),
              const SizedBox(width: 8),
              Text(
                "INTERVAL: ${k1.timeOffset.toStringAsFixed(1)}s ➔ ${k2.timeOffset.toStringAsFixed(1)}s",
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniGraph(k1.easing),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<EasingType>(
                    value: k1.easing,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1F1F29),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white38),
                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                    items: EasingType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (easing) => easing != null ? _updateKeyframeEasing(k1, easing) : null,
                  ),
                ),
              ),
            ],
          ),
          if (k1.easing == EasingType.custom) ...[
            const SizedBox(height: 16),
            CustomBezierEditor(
              cp1x: k1.cp1x ?? 0.42,
              cp1y: k1.cp1y ?? 0.0,
              cp2x: k1.cp2x ?? 0.58,
              cp2y: k1.cp2y ?? 1.0,
              onUpdate: (x1, y1, x2, y2) => _updateKeyframeCustomPoints(k1, x1, y1, x2, y2),
            ),
          ],
          if (k1.easing == EasingType.graph) ...[
            const SizedBox(height: 16),
            CustomGraphEditor(
              points: k1.customGraphPoints,
              onUpdate: (pts) => _updateKeyframeGraphPoints(k1, pts),
            ),
          ],
        ],
      ),
    );
  }

  void _updateKeyframeGraphPoints(Keyframe target, List<double> points) {
    final newKeyframes = List<Keyframe>.from(widget.clip.keyframes);
    final idx = newKeyframes.indexWhere((k) => k.timeOffset == target.timeOffset);
    if (idx != -1) {
      newKeyframes[idx] = newKeyframes[idx].copyWith(customGraphPoints: points);
      widget.onUpdate(keyframes: newKeyframes);
    }
  }

  Widget _buildMiniGraph(EasingType easing, [Keyframe? k]) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: CustomPaint(
        painter: CurvePainter(easing, k),
      ),
    );
  }

  Widget _buildKeyframeItem(BuildContext context, Keyframe k) {
    final relPosMs = (widget.currentPosition - widget.clip.startTime).inMilliseconds;
    final relPosSec = relPosMs / 1000.0;
    final isAtThisPos = (k.timeOffset - relPosSec).abs() < 0.05;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isAtThisPos ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAtThisPos ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.transparent),
      ),
      child: Row(
        children: [
          _buildMiniGraph(k.easing, k),
          const SizedBox(width: 12),
          Text(
            "${k.timeOffset.toStringAsFixed(2)}s",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, fontFamily: 'monospace'),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
            onPressed: () => _removeKeyframe(k),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _updateKeyframeCustomPoints(Keyframe target, double x1, double y1, double x2, double y2) {
    final newKeyframes = List<Keyframe>.from(widget.clip.keyframes);
    final idx = newKeyframes.indexWhere((k) => k.timeOffset == target.timeOffset);
    if (idx != -1) {
      newKeyframes[idx] = newKeyframes[idx].copyWith(cp1x: x1, cp1y: y1, cp2x: x2, cp2y: y2);
      widget.onUpdate(keyframes: newKeyframes);
    }
  }

  void _updateKeyframeEasing(Keyframe target, EasingType easing) {
    final newKeyframes = List<Keyframe>.from(widget.clip.keyframes);
    final idx = newKeyframes.indexWhere((k) => k.timeOffset == target.timeOffset);
    if (idx != -1) {
      newKeyframes[idx] = newKeyframes[idx].copyWith(easing: easing);
      widget.onUpdate(keyframes: newKeyframes);
    }
  }

  void _addOrUpdateKeyframe(double timeOffset, int existingIndex) {
    final newKeyframes = List<Keyframe>.from(widget.clip.keyframes);
    
    final keyframe = Keyframe(
      timeOffset: timeOffset,
      x: widget.clip.x,
      y: widget.clip.y,
      scale: widget.clip.scale,
      rotation: widget.clip.rotation,
      opacity: widget.clip.opacity,
    );

    if (existingIndex >= 0) {
      newKeyframes[existingIndex] = keyframe;
    } else {
      newKeyframes.add(keyframe);
      newKeyframes.sort((a, b) => a.timeOffset.compareTo(b.timeOffset));
    }

    widget.onUpdate(keyframes: newKeyframes);
  }

  void _removeKeyframe(Keyframe k) {
    final newKeyframes = List<Keyframe>.from(widget.clip.keyframes)..removeWhere((item) => item.timeOffset == k.timeOffset);
    widget.onUpdate(keyframes: newKeyframes);
  }
}

class CurvePainter extends CustomPainter {
  final EasingType easing;
  final Keyframe? keyframe;
  CurvePainter(this.easing, [this.keyframe]);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurpleAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);

    for (double t = 0; t <= 1.0; t += 0.05) {
      final x = t * size.width;
      final y = size.height - _applyEasing(t, easing) * size.height;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  double _applyEasing(double t, EasingType easing) {
    switch (easing) {
      case EasingType.linear: return t;
      case EasingType.easeIn: return t * t * t;
      case EasingType.easeOut: return 1.0 - pow(1.0 - t, 3).toDouble();
      case EasingType.easeInOut: return t < 0.5 ? 4 * t * t * t : 1.0 - pow(-2 * t + 2, 3).toDouble() / 2;
      case EasingType.bounceOut:
        if (t < 1 / 2.75) return 7.5625 * t * t;
        else if (t < 2 / 2.75) { t -= 1.5 / 2.75; return 7.5625 * t * t + 0.75; }
        else if (t < 2.5 / 2.75) { t -= 2.25 / 2.75; return 7.5625 * t * t + 0.9375; }
        else { t -= 2.625 / 2.75; return 7.5625 * t * t + 0.984375; }
      case EasingType.elasticOut:
        if (t == 0.0 || t == 1.0) return t;
        return pow(2, -10 * t).toDouble() * sin((t - 0.075) * (2 * pi) / 0.3) + 1.0;
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
    return t;
  }

  double _solveGraph(double t, List<double>? points) {
    if (points == null || points.isEmpty) return t;
    
    final nodes = <Offset>[const Offset(0, 0)];
    for (int i = 0; i < points.length; i += 2) {
      if (i + 1 < points.length) nodes.add(Offset(points[i], points[i + 1]));
    }
    nodes.add(const Offset(1, 1));
    nodes.sort((a, b) => a.dx.compareTo(b.dx));

    final n = nodes.length;
    if (n < 2) return t;

    final ms = List.filled(n - 1, 0.0);
    for (int i = 0; i < n - 1; i++) {
        final dx = nodes[i+1].dx - nodes[i].dx;
        ms[i] = dx == 0 ? 0 : (nodes[i+1].dy - nodes[i].dy) / dx;
    }

    final ds = List.filled(n, 0.0);
    ds[0] = ms[0];
    ds[n - 1] = ms[n - 2];
    for (int i = 1; i < n - 1; i++) {
        if (ms[i-1] * ms[i] <= 0) ds[i] = 0;
        else ds[i] = (ms[i-1] + ms[i]) / 2.0;
    }

    int idx = 0;
    while (idx < n - 2 && t > nodes[idx + 1].dx) idx++;

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

  double _solveCubicBezier(double x, double x1, double y1, double x2, double y2) {
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

  double _sampleBezier(double t, double p1, double p2) {
    return 3 * p1 * t * pow(1 - t, 2) + 3 * p2 * pow(t, 2) * (1 - t) + pow(t, 3);
  }

  double _sampleBezierDerivative(double t, double p1, double p2) {
    return (3 * p1 * pow(1 - t, 2)) - (6 * p1 * t * (1 - t)) + (6 * p2 * t * (1 - t)) - (3 * p2 * pow(t, 2)) + (3 * pow(t, 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
