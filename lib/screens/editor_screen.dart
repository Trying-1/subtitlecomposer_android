import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/editor_provider.dart';
import '../widgets/preview/video_preview.dart';
import '../widgets/timeline/timeline_editor.dart';
import '../widgets/controls/bottom_control_panel.dart';
import '../services/audio_service.dart';
import '../models/editor_models.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final AudioService _audioService = AudioService();

  Future<void> _pickAudio(BuildContext context, EditorProvider provider) async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result != null && context.mounted) {
      provider.loadAudio(result.files.single.path!);
    }
  }

  Future<void> _pickSubtitles(BuildContext context, EditorProvider provider) async {
    final result = await FilePicker.pickFiles();
    if (result != null && context.mounted) {
      final path = result.files.single.path!;
      final format = path.endsWith('.json') ? 'json' : 'ass';
      provider.loadSubtitles(path, format);
    }
  }

  Future<void> _pickPlainText(BuildContext context, EditorProvider provider) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null && context.mounted) {
      provider.importPlainText(result.files.single.path!);
    }
  }

  Future<void> _extractAudioFromVideo(BuildContext context, EditorProvider provider) async {
    final audioPath = await _audioService.pickVideoAndExtractAudio();
    if (audioPath != null) {
      provider.loadAudio(audioPath);
    }
  }

  void _showPasteSubtitlesDialog(BuildContext context, EditorProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Paste Subtitles', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Paste your paragraph here...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              filled: true,
              fillColor: Colors.black26,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.generateSubtitlesFromText(controller.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('GENERATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddTextDialog(BuildContext context, EditorProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Text', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter text here...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              filled: true,
              fillColor: Colors.black26,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                provider.addClip(val.trim());
              }
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addClip(controller.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ADD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, EditorProvider provider) async {
    final path = await provider.exportVideo();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video exported to gallery'),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: provider.isTimelineCollapsed ? 1 : 6,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: VideoPreview(),
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
                onSplit: () => provider.selectedClipIds.isNotEmpty ? provider.splitClip(provider.selectedClipIds.first) : null,
                onMerge: () => provider.mergeSelectedClips(),
                onSplitToWords: () => provider.splitSelectedClipToWords(),
                onDelete: () => provider.deleteSelectedClips(),
                onActionStart: () => provider.saveState(),
                onUndo: () => provider.undo(),
                onRedo: () => provider.redo(),
                canUndo: provider.canUndo,
                canRedo: provider.canRedo,
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
                  onSplit: () => provider.selectedClipIds.isNotEmpty ? provider.splitClip(provider.selectedClipIds.first) : null,
                  onMerge: () => provider.mergeSelectedClips(),
                  onSplitToWords: () => provider.splitSelectedClipToWords(),
                  onDelete: () => provider.deleteSelectedClips(),
                  onActionStart: () => provider.saveState(),
                  onUndo: () => provider.undo(),
                  onRedo: () => provider.redo(),
                  canUndo: provider.canUndo,
                  canRedo: provider.canRedo,
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
              onImportAudio: () => _pickAudio(context, provider),
              onExtractAudio: () => _extractAudioFromVideo(context, provider),
              onImportSubtitles: () => _pickSubtitles(context, provider),
              onImportPlainText: () => _pickPlainText(context, provider),
              onPasteSubtitles: () => _showPasteSubtitlesDialog(context, provider),
              onExport: () => _handleExport(context, provider),
              onAddClip: () => _showAddTextDialog(context, provider),
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
                TextCase? textCase,
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
                  textCase: textCase,
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
