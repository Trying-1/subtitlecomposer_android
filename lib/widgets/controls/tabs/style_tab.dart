import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import '../../../utils/animation_library.dart';
import 'common/common_controls.dart';

class StyleTab extends StatefulWidget {
  final SubtitleClip clip;
  final Function({
    int? color,
    int? strokeColor,
    double? strokeWidth,
    double? textOpacity,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
  }) onUpdate;

  const StyleTab({
    super.key,
    required this.clip,
    required this.onUpdate,
  });

  @override
  State<StyleTab> createState() => _StyleTabState();
}

class _StyleTabState extends State<StyleTab> {
  int _activeSubTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommonControls.buildSubTabBar(['COLOR', 'STROKE', 'ANIMATIONS'], _activeSubTabIndex, (index) {
          setState(() => _activeSubTabIndex = index);
        }),
        const SizedBox(height: 16),
        if (_activeSubTabIndex == 0)
          Column(
            children: [
              CommonControls.buildColorPicker(context, 'Text Color', widget.clip.color, (c) => widget.onUpdate(color: c)),
              const SizedBox(height: 16),
              CommonControls.buildSlider(context, 'Text Opacity', widget.clip.textOpacity, 0, 1, (v) => widget.onUpdate(textOpacity: v)),
            ],
          )
        else if (_activeSubTabIndex == 1)
          Column(
            children: [
              CommonControls.buildColorPicker(context, 'Stroke Color', widget.clip.strokeColor, (c) => widget.onUpdate(strokeColor: c)),
              const SizedBox(height: 12),
              CommonControls.buildSlider(context, 'Stroke Width', widget.clip.strokeWidth, 0, 30, (v) => widget.onUpdate(strokeWidth: v)),
            ],
          )
        else
          _buildAnimationsView(),
      ],
    );
  }

  Widget _buildAnimationsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimationCategory(
          'ENTRANCE',
          AnimationLibrary.entranceAnimations,
          widget.clip.entranceAnimation,
          (type) => widget.onUpdate(entranceAnimation: widget.clip.entranceAnimation.copyWith(type: type)),
        ),
        const SizedBox(height: 16),
        _buildAnimationCategory(
          'EXIT',
          AnimationLibrary.exitAnimations,
          widget.clip.exitAnimation,
          (type) => widget.onUpdate(exitAnimation: widget.clip.exitAnimation.copyWith(type: type)),
        ),
        const SizedBox(height: 16),
        _buildAnimationCategory(
          'LOOP',
          AnimationLibrary.loopAnimations,
          widget.clip.loopAnimation,
          (type) => widget.onUpdate(loopAnimation: widget.clip.loopAnimation.copyWith(type: type)),
        ),
      ],
    );
  }

  Widget _buildAnimationCategory(
    String title,
    List<AnimationMetadata> items,
    ClipAnimation current,
    Function(AnimationType) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final active = current.type == item.type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelected(item.type),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: active ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? Colors.deepPurpleAccent.withOpacity(0.4) : Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 16, color: active ? Colors.deepPurpleAccent : Colors.white38),
                        const SizedBox(height: 4),
                        Text(item.label, style: TextStyle(fontSize: 8, color: active ? Colors.white : Colors.white38, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
