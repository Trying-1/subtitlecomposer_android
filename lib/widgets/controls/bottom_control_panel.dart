import 'package:flutter/material.dart';
import '../../models/editor_models.dart';
import '../../utils/animation_presets.dart';
import 'tabs/text_tab.dart';
import 'tabs/style_tab.dart';
import 'tabs/effects_tab.dart';
import 'tabs/animation_tab.dart';
import 'tabs/transform_tab.dart';
import 'tabs/position_tab.dart';
import 'tabs/background_tab.dart';
import 'tabs/aspect_tab.dart';
import 'tabs/overlay_tab.dart';
import 'tabs/project_tab.dart';
import 'tabs/keyframe_manager_tab.dart';

class BottomControlPanel extends StatefulWidget {
  final TimelineClip? clip;
  final OverlayClip? selectedOverlay;
  final Set<String> selectedClipIds;
  final Duration currentTime;
  final VoidCallback? onImportAudio;
  final VoidCallback? onImportSubtitles;
  final VoidCallback? onImportPlainText;
  final VoidCallback? onPasteSubtitles;
  final VoidCallback? onExport;
  final VoidCallback? onAddClip;
  final VoidCallback? onExtractAudio;
  final VoidCallback? onNewProject;
  final Function(String path) onAddOverlay;
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
    double? textOpacity,
    List<Keyframe>? keyframes,
    TextCase? textCase,
  }) onUpdate;
  final Function(AnimationPreset) onApplyPreset;

  const BottomControlPanel({
    super.key,
    this.clip,
    this.selectedOverlay,
    this.selectedClipIds = const {},
    required this.currentTime,
    this.onImportAudio,
    this.onImportSubtitles,
    this.onImportPlainText,
    this.onPasteSubtitles,
    this.onAddClip,
    this.onExtractAudio,
    this.onExport,
    this.onNewProject,
    required this.onAddOverlay,
    required this.onUpdate,
    required this.onApplyPreset,
  });

  @override
  State<BottomControlPanel> createState() => _BottomControlPanelState();
}

class _BottomControlPanelState extends State<BottomControlPanel> {
  int _activeTabIndex = 0;
  bool _isCollapsed = false;

  final List<Map<String, dynamic>> _tabs = [
    {'name': 'Text', 'icon': Icons.text_fields_rounded},
    {'name': 'Style', 'icon': Icons.palette_rounded},
    {'name': 'Effects', 'icon': Icons.auto_awesome_rounded},
    {'name': 'Animation', 'icon': Icons.animation_rounded},
    {'name': 'Keyframes', 'icon': Icons.diamond_rounded},
    {'name': 'Transform', 'icon': Icons.transform_rounded},
    {'name': 'Position', 'icon': Icons.location_on_rounded},
    {'name': 'Overlay', 'icon': Icons.add_photo_alternate_rounded},
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
    if (_activeTabIndex >= 7) {
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
    final clip = widget.clip!;
    switch (_activeTabIndex) {
      case 0: 
        if (clip is SubtitleClip) return TextTab(clip: clip, onUpdate: ({text, fontFamily, fontSize, letterSpacing, textCase}) => widget.onUpdate(text: text, fontFamily: fontFamily, fontSize: fontSize, letterSpacing: letterSpacing, textCase: textCase));
        return _buildWrongClipTypeMessage("TEXT");
      case 1: 
        if (clip is SubtitleClip) return StyleTab(clip: clip, onUpdate: ({color, strokeColor, strokeWidth, textOpacity, entranceAnimation, exitAnimation, loopAnimation}) => widget.onUpdate(color: color, strokeColor: strokeColor, strokeWidth: strokeWidth, textOpacity: textOpacity, entranceAnimation: entranceAnimation, exitAnimation: exitAnimation, loopAnimation: loopAnimation));
        return _buildWrongClipTypeMessage("STYLE");
      case 2: 
        if (clip is SubtitleClip) return EffectsTab(clip: clip, onUpdate: ({isShadowEnabled, shadowColor, shadowBlur, shadowOffsetX, shadowOffsetY, isBackgroundEnabled, backgroundColor, backgroundRadius}) => widget.onUpdate(isShadowEnabled: isShadowEnabled, shadowColor: shadowColor, shadowBlur: shadowBlur, shadowOffsetX: shadowOffsetX, shadowOffsetY: shadowOffsetY, isBackgroundEnabled: isBackgroundEnabled, backgroundColor: backgroundColor, backgroundRadius: backgroundRadius));
        return _buildWrongClipTypeMessage("EFFECTS");
      case 3: 
        if (clip is SubtitleClip) return AnimationTab(clip: clip, onUpdate: widget.onUpdate, onApplyPreset: widget.onApplyPreset);
        return _buildWrongClipTypeMessage("ANIMATION");
      case 4: return KeyframeManagerTab(clip: clip, currentPosition: widget.currentTime, onUpdate: widget.onUpdate);
      case 5: return TransformTab(clip: clip, onUpdate: widget.onUpdate);
      case 6: return PositionTab(clip: clip, onUpdate: widget.onUpdate);
      default: return const SizedBox();
    }
  }

  Widget _buildWrongClipTypeMessage(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 24, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          Text(
            "$feature CONTROLS ARE FOR TEXT ONLY",
            style: const TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalTabContent() {
    switch (_activeTabIndex) {
      case 7: return OverlayTab(
        selectedOverlay: widget.selectedOverlay,
        onAddOverlay: widget.onAddOverlay,
        onUpdate: widget.onUpdate,
      );
      case 8: return const BackgroundTab();
      case 9: return const AspectTab();
      case 10: return ProjectTab(
        onImportAudio: widget.onImportAudio,
        onImportSubtitles: widget.onImportSubtitles,
        onImportPlainText: widget.onImportPlainText,
        onPasteSubtitles: widget.onPasteSubtitles,
        onAddClip: widget.onAddClip,
        onExtractAudio: widget.onExtractAudio,
        onExport: widget.onExport,
        onNewProject: widget.onNewProject,
      );
      default: return const SizedBox();
    }
  }
}
