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
      children: [
        CommonControls.buildSlider(context, 'Horizontal (X)', clip.x, 0, 1, (v) => onUpdate(x: v)),
        const SizedBox(height: 12),
        CommonControls.buildSlider(context, 'Vertical (Y)', clip.y, 0, 1, (v) => onUpdate(y: v)),
      ],
    );
  }
}
