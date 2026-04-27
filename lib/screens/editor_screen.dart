import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/editor_provider.dart';
import '../widgets/preview/video_preview.dart';
import '../widgets/timeline/timeline_editor.dart';
import '../widgets/timeline/timeline_editor.dart';
import '../widgets/controls/bottom_control_panel.dart';
import '../models/editor_models.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  Future<void> _pickAudio(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result != null && context.mounted) {
      context.read<EditorProvider>().loadAudio(result.files.single.path!);
    }
  }

  Future<void> _pickSubtitles(BuildContext context) async {
    final result = await FilePicker.pickFiles();
    if (result != null && context.mounted) {
      final path = result.files.single.path!;
      final format = path.endsWith('.json') ? 'json' : 'ass';
      context.read<EditorProvider>().loadSubtitles(path, format);
    }
  }

  Future<void> _handleExport(BuildContext context, EditorProvider provider) async {
    final path = await provider.exportVideo();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Video exported to gallery'),
          backgroundColor: Colors.deepPurpleAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleNewProject(BuildContext context, EditorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Project?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will clear your current timeline and background settings. Your imported assets will be saved.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetProject();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('RESET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      // AppBar removed for a cleaner look
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: provider.isTimelineCollapsed ? 1 : 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: const VideoPreview(),
              ),
            ),
            if (provider.isTimelineCollapsed)
                TimelineEditor(
                tracks: provider.tracks,
                overlayTracks: provider.overlayTracks,
                currentTime: provider.currentTime,
                totalDuration: provider.totalDuration,
                isPlaying: provider.isPlaying,
                onTogglePlay: provider.togglePlay,
                isCollapsed: true,
                onToggleCollapse: provider.toggleTimelineCollapse,
                onSeek: (dur) => provider.seek(dur),
                selectedClipIds: provider.selectedClipIds,
                isMultiSelectMode: provider.isMultiSelectMode,
                onToggleMultiSelect: provider.toggleMultiSelectMode,
                isAllSelected: provider.isAllSelected,
                onToggleSelectAll: () => provider.toggleSelectAll(),
                zoomLevel: provider.zoomLevel,
                onSelect: (id) => provider.selectClip(id),
                onToggleSelect: (id) => provider.toggleClipSelection(id),
                onZoomChanged: (v) => provider.setZoomLevel(v),
                onMoveClip: (clip, trackId, startTime) => provider.moveClip(clip, trackId, startTime),
                onAddTrack: (type) => provider.addNewTrack(type),
                onUpdateClipTiming: (clip, start, end, resolve) => provider.updateClipTiming(clip, start, end, resolveCollisions: resolve),
                onResolveCollisions: (id) => provider.forceResolveCollisions(id),
                onStackSelected: () => provider.stackSelectedClips(),
                onResetSelected: () => provider.resetSelectedClips(),
                onAddKeyframe: () => provider.addKeyframeAtCurrentTime(),
                onClearKeyframes: () => provider.clearKeyframes(),
                isKeyframeAtCurrentTime: provider.isKeyframeAtCurrentTime,
                showTextTracks: provider.showTextTracks,
                showOverlayTracks: provider.showOverlayTracks,
                onToggleTextTracks: provider.toggleTextTracks,
                onToggleOverlayTracks: provider.toggleOverlayTracks,
              )
            else
              Expanded(
                flex: 3,
                child: TimelineEditor(
                  tracks: provider.tracks,
                  overlayTracks: provider.overlayTracks,
                  currentTime: provider.currentTime,
                  totalDuration: provider.totalDuration,
                  isPlaying: provider.isPlaying,
                  onTogglePlay: provider.togglePlay,
                  isCollapsed: false,
                  onToggleCollapse: provider.toggleTimelineCollapse,
                  onSeek: (dur) => provider.seek(dur),
                  selectedClipIds: provider.selectedClipIds,
                  isMultiSelectMode: provider.isMultiSelectMode,
                  onToggleMultiSelect: provider.toggleMultiSelectMode,
                  isAllSelected: provider.isAllSelected,
                  onToggleSelectAll: () => provider.toggleSelectAll(),
                  zoomLevel: provider.zoomLevel,
                  onSelect: (id) => provider.selectClip(id),
                  onToggleSelect: (id) => provider.toggleClipSelection(id),
                  onZoomChanged: (v) => provider.setZoomLevel(v),
                  onMoveClip: (clip, trackId, startTime) => provider.moveClip(clip, trackId, startTime),
                  onAddTrack: (type) => provider.addNewTrack(type),
                  onUpdateClipTiming: (clip, start, end, resolve) => provider.updateClipTiming(clip, start, end, resolveCollisions: resolve),
                  onResolveCollisions: (id) => provider.forceResolveCollisions(id),
                  onStackSelected: () => provider.stackSelectedClips(),
                  onResetSelected: () => provider.resetSelectedClips(),
                  onAddKeyframe: () => provider.addKeyframeAtCurrentTime(),
                  onClearKeyframes: () => provider.clearKeyframes(),
                  isKeyframeAtCurrentTime: provider.isKeyframeAtCurrentTime,
                  showTextTracks: provider.showTextTracks,
                  showOverlayTracks: provider.showOverlayTracks,
                  onToggleTextTracks: provider.toggleTextTracks,
                  onToggleOverlayTracks: provider.toggleOverlayTracks,
                ),
              ),
            if (provider.isTimelineCollapsed)
              LinearProgressIndicator(
                value: provider.totalDuration.inMilliseconds > 0 
                    ? provider.currentTime.inMilliseconds / provider.totalDuration.inMilliseconds 
                    : 0.0,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: Colors.deepPurpleAccent,
                minHeight: 2,
              ),
            if (provider.isExporting)
              const LinearProgressIndicator(color: Colors.deepPurpleAccent, backgroundColor: Colors.white10),
            const Divider(height: 1, color: Colors.white10),
            BottomControlPanel(
              clip: provider.selectedTimelineClip,
              selectedOverlay: provider.selectedOverlay,
              selectedClipIds: provider.selectedClipIds,
              currentTime: provider.currentTime,
              onImportAudio: () => _pickAudio(context),
              onImportSubtitles: () => _pickSubtitles(context),
              onExport: () => _handleExport(context, provider),
              onAddClip: () => provider.addClip("New Text"),
              onNewProject: () => _handleNewProject(context, provider),
              onAddOverlay: (path) => provider.addOverlay(path),
              onUpdate: ({
                String? text,
                double? fontSize,
                double? x,
                double? y,
                double? letterSpacing,
                double? rotation,
                double? scale,
                double? opacity,
                bool? isShadowEnabled,
                bool? isBackgroundEnabled,
                int? color,
                int? strokeColor,
                double? strokeWidth,
                int? shadowColor,
                double? shadowBlur,
                double? shadowOffsetX,
                double? shadowOffsetY,
                int? backgroundColor,
                double? backgroundRadius,
                String? fontFamily,
                ClipAnimation? entranceAnimation,
                ClipAnimation? exitAnimation,
                ClipAnimation? loopAnimation,
                double? textOpacity,
                List<Keyframe>? keyframes,
              }) {
                provider.updateClips(
                  provider.selectedClipIds,
                  text: text,
                  fontSize: fontSize,
                  x: x,
                  y: y,
                  color: color,
                  strokeColor: strokeColor,
                  strokeWidth: strokeWidth,
                  shadowColor: shadowColor,
                  shadowBlur: shadowBlur,
                  shadowOffsetX: shadowOffsetX,
                  shadowOffsetY: shadowOffsetY,
                  backgroundColor: backgroundColor,
                  backgroundRadius: backgroundRadius,
                  letterSpacing: letterSpacing,
                  rotation: rotation,
                  scale: scale,
                  opacity: opacity,
                  textOpacity: textOpacity,
                  isShadowEnabled: isShadowEnabled,
                  isBackgroundEnabled: isBackgroundEnabled,
                  fontFamily: fontFamily,
                  entranceAnimation: entranceAnimation,
                  exitAnimation: exitAnimation,
                  loopAnimation: loopAnimation,
                  keyframes: keyframes,
                );
              },
              onApplyPreset: (preset) {
                for (var id in provider.selectedClipIds) {
                  provider.applyPreset(id, preset);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
