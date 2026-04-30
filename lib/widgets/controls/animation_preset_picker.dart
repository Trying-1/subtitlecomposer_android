import 'package:flutter/material.dart';
import '../../models/editor_models.dart';
import '../../utils/animation_presets.dart';

class AnimationPresetPicker extends StatelessWidget {
  final SubtitleClip clip;
  final Function(AnimationPreset) onApply;

  const AnimationPresetPicker({
    super.key,
    required this.clip,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Animation Presets',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AnimationPresets.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = AnimationPresets.all[index];
              final isSelected = _isPresetActive(preset);
              return _buildPresetChip(preset, isSelected);
            },
          ),
        ),
      ],
    );
  }

  bool _isPresetActive(AnimationPreset preset) {
    return clip.entranceAnimation.type == preset.entrance.type &&
           clip.exitAnimation.type == preset.exit.type;
  }

  Widget _buildPresetChip(AnimationPreset preset, bool isSelected) {
    return GestureDetector(
      onTap: () => onApply(preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        decoration: BoxDecoration(
          gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
          color: isSelected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              preset.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              preset.name,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
