import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';
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
import 'tabs/font_tab.dart';
import 'tabs/audio_tab.dart';
import 'tabs/keyframe_manager_tab.dart';
import 'tabs/layout_tab.dart';

class BottomControlPanel extends StatefulWidget {
  final TimelineClip? clip;
  final OverlayClip? selectedOverlay;
  final AudioClip? selectedAudio;
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
  final VoidCallback? onTranscribe;
  final VoidCallback? onImportModel;
  final VoidCallback? onBulkEditJson;
  final VoidCallback? onBulkEditText;
  final VoidCallback? onForceAlign;
  final VoidCallback? onAddMusic;
  final VoidCallback? onAddSFX;
  final bool isModelReady;
  final bool isImportingModel;
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
    bool? isStrokeEnabled,
    CustomBlendMode? blendMode,
    String? fontFamily,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    double? textOpacity,
    List<Keyframe>? keyframes,
    TextCase? textCase,
    double? volume,
    bool? isGlowEnabled,
    int? glowColor,
    double? glowSize,
    bool? isBendingEnabled,
    double? bendingAmount,
    bool? isReflectionEnabled,
    double? reflectionOffset,
    double? reflectionOpacity,
    int? reflectionColor,
    bool? isGradientEnabled,
    int? gradientColor1,
    int? gradientColor2,
    double? gradientAngle,
  }) onUpdate;
  final Function(String path) onAddAudioClip;
  final Function(AnimationPreset) onApplyPreset;

  const BottomControlPanel({
    super.key,
    this.clip,
    this.selectedOverlay,
    this.selectedAudio,
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
    this.onTranscribe,
    this.onImportModel,
    this.onBulkEditJson,
    this.onBulkEditText,
    this.onForceAlign,
    this.onAddMusic,
    this.onAddSFX,
    this.isModelReady = false,
    this.isImportingModel = false,
    required this.onAddOverlay,
    required this.onAddAudioClip,
    required this.onUpdate,
    required this.onApplyPreset,
  });

  @override
  State<BottomControlPanel> createState() => _BottomControlPanelState();
}

class _BottomControlPanelState extends State<BottomControlPanel> {

  final List<Map<String, dynamic>> _tabs = [
    {'name': 'Text', 'icon': Icons.text_fields_rounded},
    {'name': 'Font', 'icon': Icons.font_download_rounded},
    {'name': 'Style', 'icon': Icons.palette_rounded},
    {'name': 'Effects', 'icon': Icons.auto_awesome_rounded},
    {'name': 'Layout', 'icon': Icons.grid_view_rounded},
    {'name': 'Animation', 'icon': Icons.animation_rounded},
    {'name': 'Keyframes', 'icon': Icons.diamond_rounded},
    {'name': 'Transform', 'icon': Icons.transform_rounded},
    {'name': 'Position', 'icon': Icons.location_on_rounded},
    {'name': 'Overlay', 'icon': Icons.add_photo_alternate_rounded},
    {'name': 'Background', 'icon': Icons.wallpaper_rounded},
    {'name': 'Audio', 'icon': Icons.audiotrack_rounded},
    {'name': 'Aspect', 'icon': Icons.aspect_ratio_rounded},
    {'name': 'Project', 'icon': Icons.folder_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final isCollapsed = provider.isControlPanelCollapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: isCollapsed ? 52 : 240, 
      decoration: const BoxDecoration(
        color: Color(0xFF16161E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          if (!isCollapsed)
            Expanded(
              child: _buildActiveTabContentWrapper(provider.activeTabIndex),
            ),
          const Divider(height: 1, color: Colors.white10),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildActiveTabContentWrapper(int activeTabIndex) {
    if (activeTabIndex >= 9) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: _buildGlobalTabContent(activeTabIndex),
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
            child: _buildActiveTabContent(activeTabIndex),
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
    final provider = context.watch<EditorProvider>();
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
            return _buildTabBarItem(index, tab['icon'], tab['name'], provider.activeTabIndex);
          }),
        ),
      ),
    );
  }

  Widget _buildTabBarItem(int index, IconData icon, String label, int activeTabIndex) {
    final provider = context.read<EditorProvider>();
    final isCollapsed = provider.isControlPanelCollapsed;
    final isSelected = activeTabIndex == index;

    return InkWell(
      onTap: () {
        if (activeTabIndex == index) {
          provider.toggleControlPanelCollapse();
        } else {
          provider.setActiveTabIndex(index);
        }
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: (isSelected && !isCollapsed) ? Colors.deepPurpleAccent : Colors.transparent,
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

  Widget _buildActiveTabContent(int activeTabIndex) {
    final clip = widget.clip!;
    switch (activeTabIndex) {
      case 0: 
        if (clip is SubtitleClip) return TextTab(clip: clip, onUpdate: ({text, textCase, fontSize, letterSpacing, blendMode}) => widget.onUpdate(text: text, textCase: textCase, fontSize: fontSize, letterSpacing: letterSpacing, blendMode: blendMode));
        return _buildWrongClipTypeMessage("TEXT");
      case 1: 
        if (clip is SubtitleClip) return FontTab(clip: clip, onUpdate: ({fontFamily}) => widget.onUpdate(fontFamily: fontFamily));
        return _buildWrongClipTypeMessage("FONT");
      case 2: 
        if (clip is SubtitleClip) return StyleTab(clip: clip, onUpdate: ({color, textOpacity, entranceAnimation, exitAnimation, loopAnimation, isGradientEnabled, gradientColor1, gradientColor2, gradientAngle}) => widget.onUpdate(color: color, textOpacity: textOpacity, entranceAnimation: entranceAnimation, exitAnimation: exitAnimation, loopAnimation: loopAnimation, isGradientEnabled: isGradientEnabled, gradientColor1: gradientColor1, gradientColor2: gradientColor2, gradientAngle: gradientAngle));
        return _buildWrongClipTypeMessage("STYLE");
      case 3: 
        if (clip is SubtitleClip || clip is OverlayClip) return EffectsTab(clip: clip, onUpdate: ({isShadowEnabled, shadowColor, shadowBlur, shadowOffsetX, shadowOffsetY, isBackgroundEnabled, backgroundColor, backgroundRadius, isStrokeEnabled, strokeColor, strokeWidth, isGlowEnabled, glowColor, glowSize, isBendingEnabled, bendingAmount, isReflectionEnabled, reflectionOffset, reflectionOpacity, reflectionColor}) => widget.onUpdate(isShadowEnabled: isShadowEnabled, shadowColor: shadowColor, shadowBlur: shadowBlur, shadowOffsetX: shadowOffsetX, shadowOffsetY: shadowOffsetY, isBackgroundEnabled: isBackgroundEnabled, backgroundColor: backgroundColor, backgroundRadius: backgroundRadius, isStrokeEnabled: isStrokeEnabled, strokeColor: strokeColor, strokeWidth: strokeWidth, isGlowEnabled: isGlowEnabled, glowColor: glowColor, glowSize: glowSize, isBendingEnabled: isBendingEnabled, bendingAmount: bendingAmount, isReflectionEnabled: isReflectionEnabled, reflectionOffset: reflectionOffset, reflectionOpacity: reflectionOpacity, reflectionColor: reflectionColor));
        return _buildWrongClipTypeMessage("EFFECTS");
      case 4:
        return LayoutTab(
          onApplyPreset: (preset) => context.read<EditorProvider>().applyLayoutPreset(preset),
          selectedClipCount: widget.selectedClipIds.length,
        );
      case 5: 
        if (clip is SubtitleClip) return AnimationTab(clip: clip, onUpdate: widget.onUpdate, onApplyPreset: widget.onApplyPreset);
        return _buildWrongClipTypeMessage("ANIMATION");
      case 6: return KeyframeManagerTab(clip: clip, currentPosition: widget.currentTime, onUpdate: widget.onUpdate);
      case 7: return TransformTab(clip: clip, onUpdate: widget.onUpdate);
      case 8: return PositionTab(clip: clip, onUpdate: widget.onUpdate);
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
            "$feature CONTROLS ARE NOT AVAILABLE FOR THIS CLIP",
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalTabContent(int activeTabIndex) {
    switch (activeTabIndex) {
      case 9: return OverlayTab(
        selectedOverlay: widget.selectedOverlay,
        onAddOverlay: widget.onAddOverlay,
        onUpdate: widget.onUpdate,
      );
      case 10: return const BackgroundTab();
      case 11: return AudioTab(
        selectedAudio: widget.selectedAudio,
        onAddAudio: widget.onAddAudioClip,
        onUpdate: ({volume}) => widget.onUpdate(volume: volume),
      );
      case 12: return const AspectTab();
      case 13: return ProjectTab(
        onImportAudio: widget.onImportAudio,
        onImportSubtitles: widget.onImportSubtitles,
        onImportPlainText: widget.onImportPlainText,
        onPasteSubtitles: widget.onPasteSubtitles,
        onAddClip: widget.onAddClip,
        onExtractAudio: widget.onExtractAudio,
        onExport: widget.onExport,
        onNewProject: widget.onNewProject,
        onTranscribe: widget.onTranscribe,
        onImportModel: widget.onImportModel,
        onBulkEditJson: widget.onBulkEditJson,
        onBulkEditText: widget.onBulkEditText,
        onForceAlign: widget.onForceAlign,
        onAddMusic: widget.onAddMusic,
        onAddSFX: widget.onAddSFX,
        isModelReady: widget.isModelReady,
        isImporting: widget.isImportingModel,
      );
      default: return const SizedBox();
    }
  }
}
