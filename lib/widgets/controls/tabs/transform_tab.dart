import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import 'common/common_controls.dart';

class TransformTab extends StatelessWidget {
  final TimelineClip clip;
  final Function({double? scale, double? rotation, double? opacity}) onUpdate;

  const TransformTab({
    super.key,
    required this.clip,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommonControls.buildSlider(context, 'Scale', clip.scale, 0.1, 5.0, (v) => onUpdate(scale: v), onReset: () => onUpdate(scale: 1.0)),
        const SizedBox(height: 12),
        CommonControls.buildSlider(context, 'Rotation', clip.rotation, -180, 180, (v) => onUpdate(rotation: v), onReset: () => onUpdate(rotation: 0.0)),
        const SizedBox(height: 8),
        CommonControls.buildQuickRotationControls(clip.rotation, (v) => onUpdate(rotation: v)),
        const SizedBox(height: 12),
        CommonControls.buildSlider(context, 'Opacity', clip.opacity, 0, 1, (v) => onUpdate(opacity: v), onReset: () => onUpdate(opacity: 1.0)),
      ],
    );
  }
}
