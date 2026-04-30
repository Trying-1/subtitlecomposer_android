import 'package:flutter/material.dart';
import 'dart:math';

/// A professional Cubic Bezier editor for keyframe easing.
class CustomBezierEditor extends StatefulWidget {
  final double cp1x;
  final double cp1y;
  final double cp2x;
  final double cp2y;
  final Function(double, double, double, double) onUpdate;

  const CustomBezierEditor({
    super.key,
    required this.cp1x,
    required this.cp1y,
    required this.cp2x,
    required this.cp2y,
    required this.onUpdate,
  });

  @override
  State<CustomBezierEditor> createState() => _CustomBezierEditorState();
}

class _CustomBezierEditorState extends State<CustomBezierEditor> {
  late double _cp1x, _cp1y, _cp2x, _cp2y;

  @override
  void initState() {
    super.initState();
    _cp1x = widget.cp1x;
    _cp1y = widget.cp1y;
    _cp2x = widget.cp2x;
    _cp2y = widget.cp2y;
  }

  @override
  void didUpdateWidget(CustomBezierEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cp1x != widget.cp1x || oldWidget.cp1y != widget.cp1y ||
        oldWidget.cp2x != widget.cp2x || oldWidget.cp2y != widget.cp2y) {
      _cp1x = widget.cp1x;
      _cp1y = widget.cp1y;
      _cp2x = widget.cp2x;
      _cp2y = widget.cp2y;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final height = 150.0;
        return Column(
          children: [
            Container(
              width: size,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                  Positioned.fill(child: CustomPaint(painter: _BezierCurvePainter(_cp1x, _cp1y, _cp2x, _cp2y))),
                  Positioned.fill(child: CustomPaint(painter: _BezierControlsPainter(_cp1x, _cp1y, _cp2x, _cp2y))),
                  _buildHandle(1, size, height),
                  _buildHandle(2, size, height),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPointLabel("P1", _cp1x, _cp1y),
                _buildPointLabel("P2", _cp2x, _cp2y),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointLabel(String name, double x, double y) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
        Text("(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})",
            style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildHandle(int index, double width, double height) {
    final x = (index == 1 ? _cp1x : _cp2x) * width;
    final y = (1.0 - (index == 1 ? _cp1y : _cp2y)) * height;
    return Positioned(
      left: x - 15,
      top: y - 15,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => _updateHandle(details.delta, index, width, height),
        onVerticalDragUpdate: (details) => _updateHandle(details.delta, index, width, height),
        child: Container(
          width: 30, height: 30, color: Colors.transparent,
          child: Center(
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: index == 1 ? Colors.cyanAccent : Colors.deepPurpleAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateHandle(Offset delta, int index, double width, double height) {
    setState(() {
      final x = (index == 1 ? _cp1x : _cp2x) * width;
      final y = (1.0 - (index == 1 ? _cp1y : _cp2y)) * height;
      final nx = ((x + delta.dx) / width).clamp(0.0, 1.0);
      final ny = (1.0 - ((y + delta.dy) / height)).clamp(0.0, 1.0);
      if (index == 1) { _cp1x = nx; _cp1y = ny; } else { _cp2x = nx; _cp2y = ny; }
    });
    widget.onUpdate(_cp1x, _cp1y, _cp2x, _cp2y);
  }
}

/// A node-based graph editor for complex speed curves.
class CustomGraphEditor extends StatefulWidget {
  final List<double>? points;
  final Function(List<double>) onUpdate;

  const CustomGraphEditor({
    super.key,
    this.points,
    required this.onUpdate,
  });

  @override
  State<CustomGraphEditor> createState() => _CustomGraphEditorState();
}

class _CustomGraphEditorState extends State<CustomGraphEditor> {
  late List<Offset> _nodes;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _initNodes();
  }

  void _initNodes() {
    _nodes = [];
    if (widget.points != null) {
      for (int i = 0; i < widget.points!.length; i += 2) {
        if (i + 1 < widget.points!.length) {
          _nodes.add(Offset(widget.points![i], widget.points![i + 1]));
        }
      }
    }
    _nodes.sort((a, b) => a.dx.compareTo(b.dx));
  }

  @override
  void didUpdateWidget(CustomGraphEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) { _initNodes(); }
  }

  void _onUpdate() {
    final flat = _nodes.expand((e) => [e.dx, e.dy]).toList();
    widget.onUpdate(flat);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = 150.0;
        return Column(
          children: [
            GestureDetector(
              onTapUp: (details) {
                final x = (details.localPosition.dx / width).clamp(0.01, 0.99);
                final y = (1.0 - (details.localPosition.dy / height)).clamp(0.0, 1.0);
                setState(() {
                  _nodes.add(Offset(x, y));
                  _nodes.sort((a, b) => a.dx.compareTo(b.dx));
                  _selectedIndex = _nodes.indexOf(Offset(x, y));
                });
                _onUpdate();
              },
              child: Container(
                width: width, height: height,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                    Positioned.fill(child: CustomPaint(painter: _GraphCurvePainter(_nodes))),
                    _buildAnchor(const Offset(0, 1), height, width),
                    _buildAnchor(const Offset(1, 0), height, width),
                    ..._nodes.asMap().entries.map((entry) => _buildDraggableNode(entry.key, entry.value, width, height)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TAP TO ADD NODES", style: TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.bold)),
                if (_selectedIndex != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() { _nodes.removeAt(_selectedIndex!); _selectedIndex = null; });
                      _onUpdate();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                    label: const Text("DELETE NODE", style: TextStyle(fontSize: 8, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnchor(Offset pos, double height, double width) {
    return Positioned(
      left: pos.dx * width - 4,
      top: pos.dy * height - 4,
      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle)),
    );
  }

  Widget _buildDraggableNode(int index, Offset node, double width, double height) {
    final isSelected = _selectedIndex == index;
    return Positioned(
      left: node.dx * width - 15,
      top: (1.0 - node.dy) * height - 15,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _selectedIndex = index),
        onVerticalDragStart: (_) => setState(() => _selectedIndex = index),
        onHorizontalDragUpdate: (details) => _updateNode(index, details.delta, width, height),
        onVerticalDragUpdate: (details) => _updateNode(index, details.delta, width, height),
        child: Container(
          width: 30, height: 30, color: Colors.transparent,
          child: Center(
            child: Container(
              width: isSelected ? 12 : 8, height: isSelected ? 12 : 8,
              decoration: BoxDecoration(
                color: isSelected ? Colors.cyanAccent : Colors.deepPurpleAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateNode(int index, Offset delta, double width, double height) {
    setState(() {
      final node = _nodes[index];
      final nx = ((node.dx * width + delta.dx) / width).clamp(0.01, 0.99);
      final ny = (1.0 - (((1.0 - node.dy) * height + delta.dy) / height)).clamp(0.0, 1.0);
      _nodes[index] = Offset(nx, ny);
      _nodes.sort((a, b) => a.dx.compareTo(b.dx));
      _selectedIndex = _nodes.indexOf(Offset(nx, ny));
    });
    _onUpdate();
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
        final x = size.width * (i / 4.0);
        final y = size.height * (i / 4.0);
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BezierCurvePainter extends CustomPainter {
  final double x1, y1, x2, y2;
  _BezierCurvePainter(this.x1, this.y1, this.x2, this.y2);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 3..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height);
    path.cubicTo(x1 * size.width, (1 - y1) * size.height, x2 * size.width, (1 - y2) * size.height, size.width, 0);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_BezierCurvePainter oldDelegate) => oldDelegate.x1 != x1 || oldDelegate.y1 != y1 || oldDelegate.x2 != x2 || oldDelegate.y2 != y2;
}

class _BezierControlsPainter extends CustomPainter {
  final double x1, y1, x2, y2;
  _BezierControlsPainter(this.x1, this.y1, this.x2, this.y2);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white24..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), Offset(x1 * size.width, (1 - y1) * size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(x2 * size.width, (1 - y2) * size.height), paint);
  }
  @override
  bool shouldRepaint(_BezierControlsPainter oldDelegate) => oldDelegate.x1 != x1 || oldDelegate.y1 != y1 || oldDelegate.x2 != x2 || oldDelegate.y2 != y2;
}

class _GraphCurvePainter extends CustomPainter {
  final List<Offset> nodes;
  _GraphCurvePainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white70..strokeWidth = 2..style = PaintingStyle.stroke;
    final fullNodes = [const Offset(0, 0), ...nodes, const Offset(1, 1)];
    final n = fullNodes.length;
    if (n < 2) return;

    // Compute slopes
    final ms = List.filled(n - 1, 0.0);
    for (int i = 0; i < n - 1; i++) {
        final dx = fullNodes[i+1].dx - fullNodes[i].dx;
        ms[i] = dx == 0 ? 0 : (fullNodes[i+1].dy - fullNodes[i].dy) / dx;
    }

    // Compute tangents (Monotone Cubic Hermite Spline)
    final ds = List.filled(n, 0.0);
    ds[0] = ms[0];
    ds[n - 1] = ms[n - 2];
    for (int i = 1; i < n - 1; i++) {
        if (ms[i-1] * ms[i] <= 0) {
            ds[i] = 0;
        } else {
            ds[i] = (ms[i-1] + ms[i]) / 2.0;
        }
    }

    final path = Path();
    path.moveTo(0, size.height);

    for (int i = 0; i < n - 1; i++) {
        final p1 = fullNodes[i];
        final p2 = fullNodes[i+1];
        final h = p2.dx - p1.dx;
        
        if (h <= 0) {
            path.lineTo(p2.dx * size.width, (1.0 - p2.dy) * size.height);
            continue;
        }

        // Hermite to Bezier control points
        final cp1x = p1.dx + h / 3.0;
        final cp1y = p1.dy + (h / 3.0) * ds[i];
        
        final cp2x = p2.dx - h / 3.0;
        final cp2y = p2.dy - (h / 3.0) * ds[i+1];

        path.cubicTo(
            cp1x * size.width, (1.0 - cp1y) * size.height,
            cp2x * size.width, (1.0 - cp2y) * size.height,
            p2.dx * size.width, (1.0 - p2.dy) * size.height
        );
    }
    
    canvas.drawPath(path, paint);

    final fillPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.deepPurpleAccent.withOpacity(0.2), Colors.transparent]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(_GraphCurvePainter oldDelegate) => oldDelegate.nodes != nodes;
}
