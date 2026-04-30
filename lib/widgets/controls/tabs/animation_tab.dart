import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import '../../../utils/animation_presets.dart';
import '../animation_preset_picker.dart';
import 'common/common_controls.dart';

class AnimationTab extends StatelessWidget {
  final SubtitleClip clip;
  final Function({
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
  }) onUpdate;
  final Function(AnimationPreset) onApplyPreset;

  const AnimationTab({
    super.key,
    required this.clip,
    required this.onUpdate,
    required this.onApplyPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimationPresetPicker(
          clip: clip,
          onApply: onApplyPreset,
        ),
        const SizedBox(height: 24),
        const Text('ENTRANCE', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        CommonControls.buildAnimationTypeDropdown(
          'Type',
          clip.entranceAnimation.type,
          (AnimationType type) => onUpdate(entranceAnimation: clip.entranceAnimation.copyWith(type: type)),
        ),
        const SizedBox(height: 12),
        CommonControls.buildEasingDropdown(
          'Easing',
          clip.entranceAnimation.easing,
          (EasingType easing) => onUpdate(entranceAnimation: clip.entranceAnimation.copyWith(easing: easing)),
        ),
        const SizedBox(height: 12),
        CommonControls.buildSlider(
          context,
          'Duration',
          clip.entranceAnimation.durationMs.toDouble(),
          100,
          2000,
          (v) => onUpdate(entranceAnimation: clip.entranceAnimation.copyWith(durationMs: v.toInt())),
        ),
        const SizedBox(height: 24),
        const Text('EXIT', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        CommonControls.buildAnimationTypeDropdown(
          'Type',
          clip.exitAnimation.type,
          (AnimationType type) => onUpdate(exitAnimation: clip.exitAnimation.copyWith(type: type)),
        ),
        const SizedBox(height: 12),
        CommonControls.buildEasingDropdown(
          'Easing',
          clip.exitAnimation.easing,
          (EasingType easing) => onUpdate(exitAnimation: clip.exitAnimation.copyWith(easing: easing)),
        ),
        const SizedBox(height: 12),
        CommonControls.buildSlider(
          context,
          'Duration',
          clip.exitAnimation.durationMs.toDouble(),
          100,
          2000,
          (v) => onUpdate(exitAnimation: clip.exitAnimation.copyWith(durationMs: v.toInt())),
        ),
        const SizedBox(height: 24),
        const Text('LOOP (CONTINUOUS)', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        _buildLoopSelector(
          clip.loopAnimation,
          (anim) => onUpdate(loopAnimation: anim),
        ),
      ],
    );
  }

  Widget _buildLoopSelector(ClipAnimation current, ValueChanged<ClipAnimation> onChanged) {
    final options = [
      {'type': AnimationType.none, 'label': 'None', 'icon': Icons.not_interested},
      {'type': AnimationType.shake, 'label': 'Shake', 'icon': Icons.vibration},
      {'type': AnimationType.wobble, 'label': 'Wobble', 'icon': Icons.waves},
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = current.type == opt['type'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(current.copyWith(type: opt['type'] as AnimationType)),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10),
              ),
              child: Column(
                children: [
                  Icon(opt['icon'] as IconData, size: 16, color: isSelected ? Colors.white : Colors.white38),
                  const SizedBox(height: 4),
                  Text(opt['label'] as String, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.white38, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
