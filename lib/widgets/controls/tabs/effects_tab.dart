import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import 'common/common_controls.dart';

class EffectsTab extends StatefulWidget {
  final TimelineClip clip;
  final Function({
    bool? isShadowEnabled,
    int? shadowColor,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
    bool? isBackgroundEnabled,
    int? backgroundColor,
    double? backgroundRadius,
    bool? isStrokeEnabled,
    int? strokeColor,
    double? strokeWidth,
  }) onUpdate;

  const EffectsTab({
    super.key,
    required this.clip,
    required this.onUpdate,
  });

  @override
  State<EffectsTab> createState() => _EffectsTabState();
}

class _EffectsTabState extends State<EffectsTab> {
  int _activeSubTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = ['SHADOW', 'STROKE'];
    if (widget.clip is SubtitleClip) tabs.add('BACKGROUND');

    return Column(
      children: [
        CommonControls.buildSubTabBar(tabs, _activeSubTabIndex, (index) {
          setState(() => _activeSubTabIndex = index);
        }),
        const SizedBox(height: 16),
        if (_activeSubTabIndex == 0) 
          _buildShadowView() 
        else if (_activeSubTabIndex == 1)
          _buildStrokeView()
        else if (_activeSubTabIndex == 2 && widget.clip is SubtitleClip)
          _buildBackgroundView(),
      ],
    );
  }

  Widget _buildShadowView() {
    final clip = widget.clip;
    bool isEnabled = false;
    int color = 0;
    double blur = 0;
    double dx = 0;
    double dy = 0;

    if (clip is SubtitleClip) {
      isEnabled = clip.isShadowEnabled;
      color = clip.shadowColor;
      blur = clip.shadowBlur;
      dx = clip.shadowOffsetX;
      dy = clip.shadowOffsetY;
    } else if (clip is OverlayClip) {
      isEnabled = clip.isShadowEnabled;
      color = clip.shadowColor;
      blur = clip.shadowBlur;
      dx = clip.shadowOffsetX;
      dy = clip.shadowOffsetY;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ENABLE SHADOW', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            CommonControls.buildToggle(isEnabled, (v) => widget.onUpdate(isShadowEnabled: v)),
          ],
        ),
        const SizedBox(height: 20),
        if (isEnabled) ...[
          CommonControls.buildColorPicker(context, 'Shadow Color', color, (c) => widget.onUpdate(shadowColor: c)),
          const SizedBox(height: 12),
          CommonControls.buildSlider(context, 'Shadow Blur', blur, 0, 50, (v) => widget.onUpdate(shadowBlur: v), onReset: () => widget.onUpdate(shadowBlur: 10)),
          const SizedBox(height: 12),
          CommonControls.buildSlider(context, 'Shadow Offset X', dx, -50, 50, (v) => widget.onUpdate(shadowOffsetX: v), onReset: () => widget.onUpdate(shadowOffsetX: 5)),
          const SizedBox(height: 12),
          CommonControls.buildSlider(context, 'Shadow Offset Y', dy, -50, 50, (v) => widget.onUpdate(shadowOffsetY: v), onReset: () => widget.onUpdate(shadowOffsetY: 5)),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('Shadow is disabled', style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildStrokeView() {
    final clip = widget.clip;
    bool isEnabled = false;
    int color = 0;
    double width = 0;

    if (clip is SubtitleClip) {
      isEnabled = clip.isStrokeEnabled;
      color = clip.strokeColor;
      width = clip.strokeWidth;
    } else if (clip is OverlayClip) {
      isEnabled = clip.isStrokeEnabled;
      color = clip.strokeColor;
      width = clip.strokeWidth;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ENABLE STROKE', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            CommonControls.buildToggle(isEnabled, (v) => widget.onUpdate(isStrokeEnabled: v)),
          ],
        ),
        const SizedBox(height: 20),
        if (isEnabled) ...[
          CommonControls.buildColorPicker(context, 'Stroke Color', color, (c) => widget.onUpdate(strokeColor: c)),
          const SizedBox(height: 12),
          CommonControls.buildSlider(context, 'Stroke Width', width, 0, 30, (v) => widget.onUpdate(strokeWidth: v), onReset: () => widget.onUpdate(strokeWidth: 5)),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('Stroke is disabled', style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildBackgroundView() {
    final clip = widget.clip;
    if (clip is! SubtitleClip) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ENABLE BACKGROUND', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            CommonControls.buildToggle(clip.isBackgroundEnabled, (v) => widget.onUpdate(isBackgroundEnabled: v)),
          ],
        ),
        const SizedBox(height: 20),
        if (clip.isBackgroundEnabled) ...[
          CommonControls.buildColorPicker(context, 'Background Color', clip.backgroundColor, (c) => widget.onUpdate(backgroundColor: c)),
          const SizedBox(height: 12),
          CommonControls.buildSlider(context, 'Corner Radius', clip.backgroundRadius, 0, 100, (v) => widget.onUpdate(backgroundRadius: v), onReset: () => widget.onUpdate(backgroundRadius: 10)),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('Background is disabled', style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
