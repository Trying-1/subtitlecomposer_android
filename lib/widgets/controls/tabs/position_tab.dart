import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import 'common/common_controls.dart';

class PositionTab extends StatelessWidget {
  final TimelineClip clip;
  final Function({double? x, double? y}) onUpdate;

  const PositionTab({
    super.key,
    required this.clip,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ALIGN',
          style: TextStyle(
            fontSize: 8,
            color: Colors.deepPurpleAccent,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        _buildAlignmentGrid(),
        const SizedBox(height: 20),
        CommonControls.buildSlider(context, 'Horizontal (X)', clip.x, 0, 1, (v) => onUpdate(x: v)),
        const SizedBox(height: 12),
        CommonControls.buildSlider(context, 'Vertical (Y)', clip.y, 0, 1, (v) => onUpdate(y: v)),
      ],
    );
  }

  Widget _buildAlignmentGrid() {
    // Margin from edge (10% inset so text isn't flush against borders)
    const double m = 0.08;
    final positions = [
      {'x': m,       'y': m,       'icon': Icons.north_west_rounded,  'label': 'TL'},
      {'x': 0.5,     'y': m,       'icon': Icons.north_rounded,       'label': 'TC'},
      {'x': 1.0 - m, 'y': m,       'icon': Icons.north_east_rounded,  'label': 'TR'},
      {'x': m,       'y': 0.5,     'icon': Icons.west_rounded,        'label': 'ML'},
      {'x': 0.5,     'y': 0.5,     'icon': Icons.center_focus_strong_rounded, 'label': 'C'},
      {'x': 1.0 - m, 'y': 0.5,     'icon': Icons.east_rounded,        'label': 'MR'},
      {'x': m,       'y': 1.0 - m, 'icon': Icons.south_west_rounded,  'label': 'BL'},
      {'x': 0.5,     'y': 1.0 - m, 'icon': Icons.south_rounded,       'label': 'BC'},
      {'x': 1.0 - m, 'y': 1.0 - m, 'icon': Icons.south_east_rounded,  'label': 'BR'},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.2,
        ),
        itemCount: positions.length,
        itemBuilder: (context, index) {
          final pos = positions[index];
          final px = pos['x'] as double;
          final py = pos['y'] as double;
          final isActive = (clip.x - px).abs() < 0.02 && (clip.y - py).abs() < 0.02;

          return GestureDetector(
            onTap: () => onUpdate(x: px, y: py),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? Colors.deepPurpleAccent : Colors.white10,
                  width: isActive ? 1.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    pos['icon'] as IconData,
                    size: 13,
                    color: isActive ? Colors.white : Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pos['label'] as String,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.white : Colors.white38,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
