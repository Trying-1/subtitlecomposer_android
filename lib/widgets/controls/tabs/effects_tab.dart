import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import 'common/common_controls.dart';

class EffectsTab extends StatefulWidget {
  final SubtitleClip clip;
  final Function({
    bool? isShadowEnabled,
    int? shadowColor,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
    bool? isBackgroundEnabled,
    int? backgroundColor,
    double? backgroundRadius,
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
    return Column(
      children: [
        CommonControls.buildSubTabBar(['SHADOW', 'BACKGROUND'], _activeSubTabIndex, (index) {
          setState(() => _activeSubTabIndex = index);
        }),
        const SizedBox(height: 16),
        if (_activeSubTabIndex == 0) _buildShadowView() else _buildBackgroundView(),
      ],
    );
  }

  Widget _buildShadowView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ENABLE SHADOW', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            CommonControls.buildToggle(widget.clip.isShadowEnabled, (v) => widget.onUpdate(isShadowEnabled: v)),
          ],
        ),
        const SizedBox(height: 20),
        if (widget.clip.isShadowEnabled) ...[
          CommonControls.buildColorPicker(context, 'Shadow Color', widget.clip.shadowColor, (c) => widget.onUpdate(shadowColor: c)),
          const SizedBox(height: 16),
          CommonControls.buildSlider(context, 'Blur', widget.clip.shadowBlur, 0, 50, (v) => widget.onUpdate(shadowBlur: v)),
          const SizedBox(height: 12),
          CommonControls.buildSlider(context, 'Offset X', widget.clip.shadowOffsetX, -30, 30, (v) => widget.onUpdate(shadowOffsetX: v)),
          const SizedBox(height: 12),
          CommonControls.buildSlider(context, 'Offset Y', widget.clip.shadowOffsetY, -30, 30, (v) => widget.onUpdate(shadowOffsetY: v)),
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

  Widget _buildBackgroundView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ENABLE BACKGROUND', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            CommonControls.buildToggle(widget.clip.isBackgroundEnabled, (v) => widget.onUpdate(isBackgroundEnabled: v)),
          ],
        ),
        const SizedBox(height: 20),
        if (widget.clip.isBackgroundEnabled) ...[
          CommonControls.buildColorPicker(context, 'Box Color', widget.clip.backgroundColor, (c) => widget.onUpdate(backgroundColor: c)),
          const SizedBox(height: 16),
          CommonControls.buildSlider(context, 'Corner Radius', widget.clip.backgroundRadius, 0, 100, (v) => widget.onUpdate(backgroundRadius: v)),
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
