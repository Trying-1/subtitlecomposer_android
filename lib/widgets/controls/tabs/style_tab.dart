import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import '../../../utils/animation_library.dart';
import 'common/common_controls.dart';

class StyleTab extends StatefulWidget {
  final SubtitleClip clip;
  final Function({
    int? color,
    double? textOpacity,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    bool? isGradientEnabled,
    int? gradientColor1,
    int? gradientColor2,
    double? gradientAngle,
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
        CommonControls.buildSubTabBar(['PALETTES', 'CUSTOM', 'ANIMATIONS'], _activeSubTabIndex, (index) {
          setState(() => _activeSubTabIndex = index);
        }),
        const SizedBox(height: 16),
        if (_activeSubTabIndex == 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonControls.buildPalettesOnly(context, widget.clip.color, (c) => widget.onUpdate(color: c)),
              const SizedBox(height: 16),
              CommonControls.buildDialScrubber(context, 'Text Opacity', widget.clip.textOpacity, 0, 1, (v) => widget.onUpdate(textOpacity: v), onReset: () => widget.onUpdate(textOpacity: 1.0)),
            ],
          )
        else if (_activeSubTabIndex == 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonControls.buildToggleRow('Enable Gradient', widget.clip.isGradientEnabled, (v) => widget.onUpdate(isGradientEnabled: v)),
              const SizedBox(height: 16),
              if (widget.clip.isGradientEnabled) ...[
                CommonControls.buildColorPicker(context, 'Color 1', widget.clip.gradientColor1, (c) => widget.onUpdate(gradientColor1: c)),
                const SizedBox(height: 16),
                CommonControls.buildColorPicker(context, 'Color 2', widget.clip.gradientColor2, (c) => widget.onUpdate(gradientColor2: c)),
                const SizedBox(height: 16),
                CommonControls.buildDialScrubber(context, 'Gradient Angle', widget.clip.gradientAngle, -180, 180, (v) => widget.onUpdate(gradientAngle: v), onReset: () => widget.onUpdate(gradientAngle: 0.0)),
              ] else ...[
                CommonControls.buildColorPicker(context, 'Text Color', widget.clip.color, (c) => widget.onUpdate(color: c)),
              ],
              const SizedBox(height: 16),
              CommonControls.buildDialScrubber(context, 'Text Opacity', widget.clip.textOpacity, 0, 1, (v) => widget.onUpdate(textOpacity: v), onReset: () => widget.onUpdate(textOpacity: 1.0)),
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
        if (widget.clip.loopAnimation.type != AnimationType.none) ...[
          const SizedBox(height: 12),
          CommonControls.buildDialScrubber(
            context, 
            'Loop Speed', 
            1000 / widget.clip.loopAnimation.durationMs.toDouble(), 
            0.01, 
            5.0, 
            (v) => widget.onUpdate(loopAnimation: widget.clip.loopAnimation.copyWith(durationMs: (1000 / v).toInt())),
            onReset: () => widget.onUpdate(loopAnimation: widget.clip.loopAnimation.copyWith(durationMs: 1000)),
          ),
          const SizedBox(height: 12),
          CommonControls.buildDialScrubber(
            context, 
            'Loop Intensity', 
            widget.clip.loopAnimation.intensity, 
            0.1, 
            5.0, 
            (v) => widget.onUpdate(loopAnimation: widget.clip.loopAnimation.copyWith(intensity: v)),
            onReset: () => widget.onUpdate(loopAnimation: widget.clip.loopAnimation.copyWith(intensity: 1.0)),
          ),
        ],
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
