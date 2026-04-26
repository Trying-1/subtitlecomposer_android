import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/editor_models.dart';
import '../../providers/editor_provider.dart';
import '../../utils/animation_presets.dart';
import 'animation_preset_picker.dart';

class BottomControlPanel extends StatefulWidget {
  final SubtitleClip? clip;
  final Set<String> selectedClipIds;
  final VoidCallback? onImportAudio;
  final VoidCallback? onImportSubtitles;
  final VoidCallback? onExport;
  final VoidCallback? onAddClip;
  final Function({
    String? text,
    double? x,
    double? y,
    double? fontSize,
    int? color,
    int? strokeColor,
    double? strokeWidth,
    int? shadowColor,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
    int? backgroundColor,
    double? backgroundRadius,
    double? letterSpacing,
    double? rotation,
    double? scale,
    double? opacity,
    bool? isShadowEnabled,
    bool? isBackgroundEnabled,
    String? fontFamily,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
  }) onUpdate;
  final Function(AnimationPreset) onApplyPreset;

  const BottomControlPanel({
    super.key,
    this.clip,
    this.selectedClipIds = const {},
    this.onImportAudio,
    this.onImportSubtitles,
    this.onExport,
    this.onAddClip,
    required this.onUpdate,
    required this.onApplyPreset,
  });

  @override
  State<BottomControlPanel> createState() => _BottomControlPanelState();
}

class _BottomControlPanelState extends State<BottomControlPanel> {
  int _activeTabIndex = 0;
  bool _isCollapsed = false;
  int _bgSubTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'name': 'Text', 'icon': Icons.text_fields_rounded},
    {'name': 'Style', 'icon': Icons.palette_rounded},
    {'name': 'Effects', 'icon': Icons.auto_awesome_rounded},
    {'name': 'Animation', 'icon': Icons.animation_rounded},
    {'name': 'Transform', 'icon': Icons.transform_rounded},
    {'name': 'Position', 'icon': Icons.location_on_rounded},
    {'name': 'Background', 'icon': Icons.wallpaper_rounded},
    {'name': 'Aspect', 'icon': Icons.aspect_ratio_rounded},
    {'name': 'Project', 'icon': Icons.folder_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: _isCollapsed ? 52 : 240, 
      decoration: const BoxDecoration(
        color: Color(0xFF16161E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          if (!_isCollapsed)
            Expanded(
              child: _buildActiveTabContentWrapper(),
            ),
          const Divider(height: 1, color: Colors.white10),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildActiveTabContentWrapper() {
    // Background, Aspect, and Project tabs should work even if no clip is selected
    if (_activeTabIndex >= 6) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: _buildGlobalTabContent(),
      );
    }

    if (widget.clip == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (widget.selectedClipIds.length > 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: Colors.deepPurpleAccent.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.layers_rounded, size: 14, color: Colors.deepPurpleAccent),
                const SizedBox(width: 8),
                Text(
                  "BATCH EDITING ${widget.selectedClipIds.length} SEGMENTS",
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.deepPurpleAccent, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildActiveTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, size: 32, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 8),
          const Text(
            'Select a clip to edit properties',
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.black26,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            return _buildTabBarItem(index, tab['icon'], tab['name']);
          }),
        ),
      ),
    );
  }

  Widget _buildTabBarItem(int index, IconData icon, String label) {
    final isSelected = _activeTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          if (_activeTabIndex == index) {
            _isCollapsed = !_isCollapsed;
          } else {
            _activeTabIndex = index;
            _isCollapsed = false;
          }
        });
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: (isSelected && !_isCollapsed) ? Colors.deepPurpleAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.deepPurpleAccent : Colors.white24),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 6.5,
                letterSpacing: 0.5,
                color: isSelected ? Colors.white : Colors.white24,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 0.85),
      ),
      child: _buildActiveTabContentSwitch(),
    );
  }

  Widget _buildActiveTabContentSwitch() {
    switch (_activeTabIndex) {
      case 0: return _buildTextTab();
      case 1: return _buildStyleTab();
      case 2: return _buildEffectsTab();
      case 3: return _buildAnimationTab();
      case 4: return _buildTransformTab();
      case 5: return _buildPositionTab();
      default: return const SizedBox();
    }
  }

  Widget _buildGlobalTabContent() {
    switch (_activeTabIndex) {
      case 6: return _buildCanvasTab();
      case 7: return _buildAspectTab();
      case 8: return _buildProjectTab();
      default: return const SizedBox();
    }
  }

  // === Tabs ===

  Widget _buildCanvasTab() {
    final provider = context.watch<EditorProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTabBar(
          ['SOLID', 'IMAGE'], 
          _bgSubTabIndex, 
          (idx) => setState(() => _bgSubTabIndex = idx)
        ),
        const SizedBox(height: 16),
        if (_bgSubTabIndex == 0)
          _buildProjectColorPicker('Solid Color', provider.backgroundColor, (c) => provider.setBackgroundColor(c))
        else ...[
          if (provider.backgroundImagePath != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(provider.backgroundImagePath!),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: Colors.white10, child: const Icon(Icons.image_not_supported, size: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.backgroundImagePath!.split('/').last,
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => provider.setBackgroundImage(null),
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('TRANSFORMATIONS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            const SizedBox(height: 16),
            _buildFillModeSelector(
              provider.backgroundFillMode,
              (mode) => provider.setBackgroundFillMode(mode),
            ),
            const SizedBox(height: 16),
            _buildSlider('Scale', provider.backgroundScale, 0.1, 5.0, (v) => provider.setBackgroundScale(v)),
            const SizedBox(height: 12),
            _buildSlider('Rotation', provider.backgroundRotation, -180, 180, (v) => provider.setBackgroundRotation(v)),
            const SizedBox(height: 12),
            _buildSlider('Horizontal (X)', provider.backgroundX, -2.0, 2.0, (v) => provider.setBackgroundX(v)),
            const SizedBox(height: 12),
            _buildSlider('Vertical (Y)', provider.backgroundY, -2.0, 2.0, (v) => provider.setBackgroundY(v)),
          ] else
            _buildSquareActionButton(
              icon: Icons.image_rounded, 
              label: 'Pick Image', 
              onTap: () => _showImagePickerBottomSheet(context, provider),
              color: Colors.deepPurpleAccent,
            ),
        ],
      ],
    );
  }

  Widget _buildAspectTab() {
    final provider = context.watch<EditorProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ASPECT RATIO', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildRatioOption(9/16, '9:16', Icons.smartphone_rounded, provider),
            const SizedBox(width: 12),
            _buildRatioOption(1, '1:1', Icons.crop_din_rounded, provider),
            const SizedBox(width: 12),
            _buildRatioOption(16/9, '16:9', Icons.tv_rounded, provider),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FILE ACTIONS', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildSquareActionButton(icon: Icons.audiotrack_rounded, label: 'Audio', onTap: widget.onImportAudio),
            const SizedBox(width: 16),
            _buildSquareActionButton(icon: Icons.subtitles_rounded, label: 'Subs', onTap: widget.onImportSubtitles),
            const SizedBox(width: 16),
            _buildSquareActionButton(icon: Icons.add_comment_rounded, label: 'Text', onTap: widget.onAddClip, color: Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 32),
        const Text('FINAL EXPORT', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildSquareActionButton(
              icon: Icons.ios_share_rounded, 
              label: 'Export', 
              onTap: widget.onExport, 
              color: Colors.deepPurpleAccent,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatioOption(double ratio, String label, IconData icon, EditorProvider provider) {
    final isSelected = (provider.aspectRatio - ratio).abs() < 0.01;
    return Expanded(
      child: InkWell(
        onTap: () => provider.setAspectRatio(ratio),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.deepPurpleAccent : Colors.white38),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 9, color: isSelected ? Colors.white : Colors.white24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectColorPicker(String label, int current, ValueChanged<int> onChanged) {
    final colors = [
      0xFF000000, 0xFF16161E, 0xFF2D3436, 0xFFFFFFFF, 
      0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFFFFFF00,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 12),
        Row(
          children: colors.map((c) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onChanged(c),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: current == c ? Colors.deepPurpleAccent : Colors.white10, 
                    width: 2,
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSquareActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.white,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isPrimary ? color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPrimary ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08),
                width: isPrimary ? 1.5 : 1,
              ),
            ),
            child: Icon(
              icon, 
              size: 22, 
              color: isPrimary ? color : color.withOpacity(0.8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 7, 
            color: isPrimary ? Colors.white : Colors.white38, 
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextTab() {
    final clip = widget.clip!;
    return Column(
      children: [
        _buildTextField(clip.text, (v) => widget.onUpdate(text: v)),
        const SizedBox(height: 16),
        _buildFontFamilyDropdown(clip.fontFamily, (v) => widget.onUpdate(fontFamily: v)),
        const SizedBox(height: 16),
        _buildSlider('Font Size', clip.fontSize, 10, 150, (v) => widget.onUpdate(fontSize: v)),
        const SizedBox(height: 12),
        _buildSlider('Letter Spacing', clip.letterSpacing, -5, 40, (v) => widget.onUpdate(letterSpacing: v)),
      ],
    );
  }

  Widget _buildStyleTab() {
    final clip = widget.clip!;
    return Column(
      children: [
        _buildColorPicker('Text Color', clip.color, (c) => widget.onUpdate(color: c)),
        const SizedBox(height: 20),
        _buildColorPicker('Stroke Color', clip.strokeColor, (c) => widget.onUpdate(strokeColor: c)),
        const SizedBox(height: 12),
        _buildSlider('Stroke Width', clip.strokeWidth, 0, 30, (v) => widget.onUpdate(strokeWidth: v)),
      ],
    );
  }

  Widget _buildEffectsTab() {
    final clip = widget.clip!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('DROP SHADOW', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            _buildToggle(clip.isShadowEnabled, (v) => widget.onUpdate(isShadowEnabled: v)),
          ],
        ),
        const SizedBox(height: 16),
        if (clip.isShadowEnabled) ...[
          _buildColorPicker('Shadow Color', clip.shadowColor, (c) => widget.onUpdate(shadowColor: c)),
          const SizedBox(height: 12),
          _buildSlider('Blur', clip.shadowBlur, 0, 50, (v) => widget.onUpdate(shadowBlur: v)),
          const SizedBox(height: 12),
          _buildSlider('Offset X', clip.shadowOffsetX, -30, 30, (v) => widget.onUpdate(shadowOffsetX: v)),
          const SizedBox(height: 12),
          _buildSlider('Offset Y', clip.shadowOffsetY, -30, 30, (v) => widget.onUpdate(shadowOffsetY: v)),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('BACKGROUND', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            _buildToggle(clip.isBackgroundEnabled, (v) => widget.onUpdate(isBackgroundEnabled: v)),
          ],
        ),
        const SizedBox(height: 16),
        if (clip.isBackgroundEnabled) ...[
          _buildColorPicker('Box Color', clip.backgroundColor, (c) => widget.onUpdate(backgroundColor: c)),
          const SizedBox(height: 12),
          _buildSlider('Corner Radius', clip.backgroundRadius, 0, 100, (v) => widget.onUpdate(backgroundRadius: v)),
        ],
      ],
    );
  }

  Widget _buildAnimationTab() {
    final clip = widget.clip!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimationPresetPicker(
          clip: clip,
          onApply: widget.onApplyPreset,
        ),
        const SizedBox(height: 24),
        const Text('ENTRANCE', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        _buildAnimationTypeDropdown(
          'Type',
          clip.entranceAnimation.type,
          (type) => widget.onUpdate(entranceAnimation: clip.entranceAnimation.copyWith(type: type)),
        ),
        const SizedBox(height: 12),
        _buildEasingDropdown(
          'Easing',
          clip.entranceAnimation.easing,
          (easing) => widget.onUpdate(entranceAnimation: clip.entranceAnimation.copyWith(easing: easing)),
        ),
        const SizedBox(height: 12),
        _buildSlider(
          'Duration',
          clip.entranceAnimation.durationMs.toDouble(),
          100,
          2000,
          (v) => widget.onUpdate(entranceAnimation: clip.entranceAnimation.copyWith(durationMs: v.toInt())),
        ),
        const SizedBox(height: 24),
        const Text('EXIT', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        _buildAnimationTypeDropdown(
          'Type',
          clip.exitAnimation.type,
          (type) => widget.onUpdate(exitAnimation: clip.exitAnimation.copyWith(type: type)),
        ),
        const SizedBox(height: 12),
        _buildEasingDropdown(
          'Easing',
          clip.exitAnimation.easing,
          (easing) => widget.onUpdate(exitAnimation: clip.exitAnimation.copyWith(easing: easing)),
        ),
        const SizedBox(height: 12),
        _buildSlider(
          'Duration',
          clip.exitAnimation.durationMs.toDouble(),
          100,
          2000,
          (v) => widget.onUpdate(exitAnimation: clip.exitAnimation.copyWith(durationMs: v.toInt())),
        ),
        const SizedBox(height: 24),
        const Text('LOOP (CONTINUOUS)', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        _buildLoopSelector(
          clip.loopAnimation,
          (anim) => widget.onUpdate(loopAnimation: anim),
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

  Widget _buildTransformTab() {
    final clip = widget.clip!;
    return Column(
      children: [
        _buildSlider('Scale', clip.scale, 0.1, 5.0, (v) => widget.onUpdate(scale: v)),
        const SizedBox(height: 12),
        _buildSlider('Rotation', clip.rotation, -180, 180, (v) => widget.onUpdate(rotation: v)),
        const SizedBox(height: 12),
        _buildSlider('Opacity', clip.opacity, 0, 1, (v) => widget.onUpdate(opacity: v)),
      ],
    );
  }

  Widget _buildPositionTab() {
    final clip = widget.clip!;
    return Column(
      children: [
        _buildSlider('Horizontal (X)', clip.x, 0, 1, (v) => widget.onUpdate(x: v)),
        const SizedBox(height: 12),
        _buildSlider('Vertical (Y)', clip.y, 0, 1, (v) => widget.onUpdate(y: v)),
      ],
    );
  }

  // === Common Controls ===

  Widget _buildSubTabBar(List<String> labels, int current, ValueChanged<int> onChanged) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final isSelected = current == index;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : Colors.white38,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTextField(String current, ValueChanged<String> onChanged) {
    return TextField(
      controller: TextEditingController(text: current)..selection = TextSelection.fromPosition(TextPosition(offset: current.length)),
      style: const TextStyle(fontSize: 13, color: Colors.white),
      maxLines: 1,
      onSubmitted: onChanged,
      decoration: InputDecoration(
        hintText: 'Enter text...',
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildColorPicker(String label, int current, ValueChanged<int> onChanged) {
    final colors = [
      0xFFFFFFFF, 0xFF000000, 0xFFFF0000, 0xFF00FF00, 
      0xFF0000FF, 0xFFFFFF00, 0xFFFF00FF, 0xFF00FFFF,
      0xFFFF9800, 0xFF9C27B0,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: colors.map((c) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => onChanged(c),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: current == c ? Colors.deepPurpleAccent : Colors.transparent, 
                      width: 2,
                    ),
                    boxShadow: [
                      if (current == c) BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.3), blurRadius: 8)
                    ]
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFontFamilyDropdown(String current, ValueChanged<String> onChanged) {
    final fonts = [
      'Poppins', 'Bellota', 'BhuTukaExpandedOne', 'Bokor', 'BungeeHairline',
      'Caramel', 'Centralwell', 'Chalk Board', 'Eternal', 'Explora',
      'GrandifloraOne', 'KleeOne', 'Lacquer', 'LibreBarcode39Text',
      'LuckiestGuy', 'MajorMonoDisplay', 'Metrophobic', 'Michroma',
      'Milker', 'NCLNeovibes', 'NewRocker', 'NewTegomin', 'ProtestRevolution',
      'RELIGATH', 'akony', 'modernline', 'modernline bold'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: fonts.contains(current) ? current : 'Poppins',
        isExpanded: true,
        dropdownColor: const Color(0xFF1E1E2A),
        style: const TextStyle(fontSize: 12, color: Colors.white70),
        underline: const SizedBox(),
        items: fonts.map((font) => DropdownMenuItem(value: font, child: Text(font, style: TextStyle(fontFamily: font, fontSize: 11)))).toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    );
  }

  Widget _buildAnimationTypeDropdown(String label, AnimationType current, ValueChanged<AnimationType> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<AnimationType>(
            value: current,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E1E2A),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            underline: const SizedBox(),
            items: AnimationType.values.map((type) => DropdownMenuItem(value: type, child: Text(AnimationPresets.animationTypeName(type)))).toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEasingDropdown(String label, EasingType current, ValueChanged<EasingType> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<EasingType>(
            value: current,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E1E2A),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            underline: const SizedBox(),
            items: EasingType.values.map((type) => DropdownMenuItem(value: type, child: Text(AnimationPresets.easingTypeName(type)))).toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
            Text(value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: Colors.deepPurpleAccent,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.deepPurpleAccent,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 20,
      width: 36,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurpleAccent,
        activeTrackColor: Colors.deepPurpleAccent.withOpacity(0.3),
        inactiveThumbColor: Colors.white24,
        inactiveTrackColor: Colors.white10,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showImagePickerBottomSheet(BuildContext context, EditorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF14141E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CHOOSE BACKGROUND', style: TextStyle(fontSize: 10, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            _buildPickerOption(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              subtitle: 'Choose from your photos',
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) provider.setBackgroundImage(image.path);
              },
            ),
            const SizedBox(height: 12),
            _buildPickerOption(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              subtitle: 'Capture a new background',
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) provider.setBackgroundImage(image.path);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.deepPurpleAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFillModeSelector(int current, ValueChanged<int> onChanged) {
    final options = [
      {'val': 0, 'label': 'Cover', 'icon': Icons.fullscreen_rounded},
      {'val': 1, 'label': 'Fit', 'icon': Icons.fullscreen_exit_rounded},
      {'val': 2, 'label': 'Center', 'icon': Icons.center_focus_strong_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FILL MODE', style: TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = current == opt['val'];
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(opt['val'] as int),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Icon(opt['icon'] as IconData, size: 14, color: isSelected ? Colors.white : Colors.white38),
                      const SizedBox(height: 2),
                      Text(opt['label'] as String, style: TextStyle(fontSize: 8, color: isSelected ? Colors.white : Colors.white38, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
