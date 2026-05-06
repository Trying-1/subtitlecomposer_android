import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import 'common/common_controls.dart';

class PositionTab extends StatefulWidget {
  final TimelineClip clip;
  final Function({double? x, double? y}) onUpdate;

  const PositionTab({
    super.key,
    required this.clip,
    required this.onUpdate,
  });

  @override
  State<PositionTab> createState() => _PositionTabState();
}

class _PositionTabState extends State<PositionTab> {
  int _activeSubTab = 0; // 0: Align, 1: Trackpad, 2: Manual
  
  // For throttling updates
  DateTime? _lastUpdate;
  static const _throttleDuration = Duration(milliseconds: 16); // ~60fps

  void _throttledUpdate(double x, double y) {
    final now = DateTime.now();
    if (_lastUpdate == null || now.difference(_lastUpdate!) > _throttleDuration) {
      widget.onUpdate(x: x, y: y);
      _lastUpdate = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-tab Header
        Container(
          height: 28,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              _buildTabItem(0, 'ALIGN'),
              _buildTabItem(1, 'TRACKPAD'),
              _buildTabItem(2, 'MANUAL'),
            ],
          ),
        ),

        // Tab Content
        IndexedStack(
          index: _activeSubTab,
          children: [
            _buildAlignmentGrid(),
            _buildPrecisionTrackpad(context),
            _buildManualControls(context),
          ],
        ),
      ],
    );
  }

  Widget _buildTabItem(int index, String label) {
    final active = _activeSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeSubTab = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: active ? Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : Colors.white38,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualControls(BuildContext context) {
    return Column(
      children: [
        CommonControls.buildDialScrubber(context, 'Horizontal (X)', widget.clip.x, -0.5, 1.5, (v) => widget.onUpdate(x: v), onReset: () => widget.onUpdate(x: 0.5)),
        const SizedBox(height: 12),
        CommonControls.buildDialScrubber(context, 'Vertical (Y)', widget.clip.y, -0.5, 1.5, (v) => widget.onUpdate(y: v), onReset: () => widget.onUpdate(y: 0.5)),
      ],
    );
  }

  Widget _buildPrecisionTrackpad(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            const double sensitivity = 0.0015;
            final double dx = details.delta.dx * sensitivity;
            final double dy = details.delta.dy * sensitivity;
            
            double newX = (widget.clip.x + dx).clamp(0.0, 1.0);
            double newY = (widget.clip.y + dy).clamp(0.0, 1.0);
            
            // Use throttling for smoother performance
            _throttledUpdate(newX, newY);
          },
          onPanEnd: (_) {
            // Ensure the final position is set accurately
            widget.onUpdate(x: widget.clip.x, y: widget.clip.y);
          },
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 160),
                  painter: TrackpadPainter(),
                ),
                const Center(
                  child: Icon(Icons.add_rounded, color: Colors.white10, size: 40),
                ),
                _buildCornerLabel(Alignment.topLeft, 'X: ${(widget.clip.x * 100).toStringAsFixed(1)}%'),
                _buildCornerLabel(Alignment.topRight, 'Y: ${(widget.clip.y * 100).toStringAsFixed(1)}%'),
                const Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'PRECISION NUDGE',
                      style: TextStyle(
                        color: Colors.white12,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerLabel(Alignment alignment, String text) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildAlignmentGrid() {
    const double m = 0.08;
    final positions = [
      {'x': m,       'y': m,       'icon': Icons.north_west_rounded},
      {'x': 0.5,     'y': m,       'icon': Icons.north_rounded},
      {'x': 1.0 - m, 'y': m,       'icon': Icons.north_east_rounded},
      {'x': m,       'y': 0.5,     'icon': Icons.west_rounded},
      {'x': 0.5,     'y': 0.5,     'icon': Icons.center_focus_strong_rounded},
      {'x': 1.0 - m, 'y': 0.5,     'icon': Icons.east_rounded},
      {'x': m,       'y': 1.0 - m, 'icon': Icons.south_west_rounded},
      {'x': 0.5,     'y': 1.0 - m, 'icon': Icons.south_rounded},
      {'x': 1.0 - m, 'y': 1.0 - m, 'icon': Icons.south_east_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.5,
        ),
        itemCount: positions.length,
        itemBuilder: (context, index) {
          final pos = positions[index];
          final px = pos['x'] as double;
          final py = pos['y'] as double;
          final isActive = (widget.clip.x - px).abs() < 0.02 && (widget.clip.y - py).abs() < 0.02;

          return GestureDetector(
            onTap: () => widget.onUpdate(x: px, y: py),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isActive ? Colors.deepPurpleAccent.withOpacity(0.15) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Icon(
                pos['icon'] as IconData,
                size: 14,
                color: isActive ? Colors.deepPurpleAccent : Colors.white38,
              ),
            ),
          );
        },
      ),
    );
  }
}

class TrackpadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;

    const double step = 20.0;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      colors: [
        Colors.deepPurpleAccent.withOpacity(0.08),
        Colors.transparent,
      ],
    ).createShader(rect);
    
    canvas.drawRect(rect, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
