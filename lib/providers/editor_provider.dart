import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/transliteration_utils.dart';
import '../models/editor_models.dart';
import '../services/native_bridge.dart';
import '../utils/subtitle_parser.dart';
import '../utils/animation_presets.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/force_align_service.dart';
import '../services/project_service.dart';
import 'package:uuid/uuid.dart';
import '../utils/toast_utils.dart';
import '../models/editor_models.dart';

class HistoryState {
  final List<Track> tracks;
  final List<Track> overlayTracks;
  final List<Track> backgroundTracks;
  final List<Track> audioTracks;
  final double aspectRatio;
  final int backgroundColor;
  final String? backgroundImagePath;
  final double backgroundScale;
  final double backgroundRotation;
  final double backgroundX;
  final double backgroundY;
  final int backgroundFillMode;
  final List<Duration> markers;
  final double mainAudioVolume;

  HistoryState({
    required this.tracks,
    required this.overlayTracks,
    required this.backgroundTracks,
    required this.audioTracks,
    required this.aspectRatio,
    required this.backgroundColor,
    this.backgroundImagePath,
    required this.backgroundScale,
    required this.backgroundRotation,
    required this.backgroundX,
    required this.backgroundY,
    required this.backgroundFillMode,
    required this.markers,
    required this.mainAudioVolume,
  });

  HistoryState clone() {
    return HistoryState(
      tracks: tracks.map((t) => t.copyWith(clips: t.clips.map((c) => c.copyWith()).toList())).toList(),
      overlayTracks: overlayTracks.map((t) => t.copyWith(overlays: t.overlays.map((c) => c.copyWith()).toList())).toList(),
      backgroundTracks: backgroundTracks.map((t) => t.copyWith(backgrounds: t.backgrounds.map((c) => c.copyWith()).toList())).toList(),
      audioTracks: audioTracks.map((t) => t.copyWith(audioClips: t.audioClips.map((c) => c.copyWith()).toList())).toList(),
      aspectRatio: aspectRatio,
      backgroundColor: backgroundColor,
      backgroundImagePath: backgroundImagePath,
      backgroundScale: backgroundScale,
      backgroundRotation: backgroundRotation,
      backgroundX: backgroundX,
      backgroundY: backgroundY,
      backgroundFillMode: backgroundFillMode,
      markers: List.from(markers),
      mainAudioVolume: mainAudioVolume,
    );
  }
}

class EditorProvider extends ChangeNotifier {
  final NativeBridge _bridge = NativeBridge();
  final ForceAlignService _alignService = ForceAlignService();
  Timer? _playbackTimer;
  DateTime? _lastTick;

  bool _hasUnsavedChanges = false;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  String _projectId = const Uuid().v4();
  String _projectName = "Untitled Project";

  EditorProvider() {
    _init();
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  List<Track> _tracks = [];
  List<Track> _overlayTracks = [];
  List<Track> _backgroundTracks = [];
  List<Track> _audioTracks = [];
  Duration _currentTime = Duration.zero;
  Duration? _focusStart;
  Duration? _focusEnd;
  Duration _totalDuration = Duration.zero;
  Duration _mainMediaDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isExporting = false;
  Set<String> _selectedClipIds = {};
  bool _isMultiSelectMode = false;
  double _zoomLevel = 10.0; // 10.0 = max zoom (500 pixels per second)
  String? _audioPath;
  String? get audioPath => _audioPath;
  double _mainAudioVolume = 1.0;
  double get mainAudioVolume => _mainAudioVolume;
  
  // Timeline Colors
  int _textTimelineColor = 0xFFFF9800; // Orange
  int _audioTimelineColor = 0xFF009688; // Teal
  int _overlayTimelineColor = 0xFF03A9F4; // Sky Blue
  int _backgroundTimelineColor = 0xFFFFEB3B; // Yellow

  int get textTimelineColor => _textTimelineColor;
  int get audioTimelineColor => _audioTimelineColor;
  int get overlayTimelineColor => _overlayTimelineColor;
  int get backgroundTimelineColor => _backgroundTimelineColor;
  double _aspectRatio = 16 / 9;
  int _backgroundColor = 0xFFFFFFFF;
  String? _backgroundImagePath;
  double _backgroundScale = 1.0;
  double _backgroundRotation = 0.0;
  double _backgroundX = 0.0;
  double _backgroundY = 0.0;
  int _backgroundFillMode = 0; // 0: cover, 1: fit, 2: center
  bool _isTimelineCollapsed = false;
  bool _isInitialized = false;
  bool _showTextTracks = true;
  bool _showOverlayTracks = true;
  bool _showBackgroundTracks = true;
  bool _showAudioTracks = true;
  String? _whisperModelPath;
  String? _lastUsedDirectory;
  String? get lastUsedDirectory => _lastUsedDirectory;
  bool _isImportingModel = false;
  final List<Duration> _markers = [];
  bool _isCollisionAdjustEnabled = false;
  bool _isPlayheadLocked = false;
  bool _isControlPanelCollapsed = true; // Start collapsed by default
  int _activeTabIndex = 0;
  bool _stackInDifferentTracks = true;
  bool get stackInDifferentTracks => _stackInDifferentTracks;
  set stackInDifferentTracks(bool val) {
    _stackInDifferentTracks = val;
    notifyListeners();
  }

  bool _showPanControls = true;
  bool get showPanControls => _showPanControls;
  void toggleShowPanControls() {
    _showPanControls = !_showPanControls;
    notifyListeners();
  }

  // Preview Zoom/Pan Mode
  bool _isPreviewZoomMode = false;
  double _previewZoom = 1.0;
  Offset _previewOffset = Offset.zero;

  bool get isPreviewZoomMode => _isPreviewZoomMode;
  double get previewZoom => _previewZoom;
  Offset get previewOffset => _previewOffset;

  void togglePreviewZoomMode() {
    _isPreviewZoomMode = !_isPreviewZoomMode;
    notifyListeners();
  }

  void resetPreviewZoom() {
    _previewZoom = 1.0;
    _previewOffset = Offset.zero;
    notifyListeners();
  }

  void updatePreviewZoom(double scaleDelta) {
    _previewZoom = (_previewZoom * scaleDelta).clamp(0.5, 10.0);
    notifyListeners();
  }

  void updatePreviewOffset(Offset delta) {
    _previewOffset += delta;
    notifyListeners();
  }

  void setPreviewZoom(double zoom) {
    _previewZoom = zoom.clamp(0.5, 10.0);
    notifyListeners();
  }

  void setPreviewOffset(Offset offset) {
    _previewOffset = offset;
    notifyListeners();
  }
  
  List<double> _customAspectRatios = [];
  List<CustomLayout> _customLayouts = [];
  List<CustomLayout> get customLayouts => _customLayouts;
  List<double> get customAspectRatios => _customAspectRatios;

  final ValueNotifier<Duration> playbackTime = ValueNotifier(Duration.zero);

  final List<HistoryState> _undoStack = [];
  final List<HistoryState> _redoStack = [];
  static const int _maxHistory = 50;

  List<Track> get tracks => _tracks;
  List<Track> get overlayTracks => _overlayTracks;
  List<Track> get backgroundTracks => _backgroundTracks;
  List<Track> get audioTracks => _audioTracks;
  Duration get currentTime => _currentTime;
  Duration? get focusStart => _focusStart;
  Duration? get focusEnd => _focusEnd;
  bool get isFocusModeEnabled => _focusStart != null && _focusEnd != null;

  void setFocusStart(Duration? time) {
    _focusStart = time;
    if (_focusEnd != null && _focusStart != null && _focusStart! >= _focusEnd!) {
      _focusEnd = null;
    }
    notifyListeners();
  }

  void setFocusEnd(Duration? time) {
    if (_focusStart == null) {
      _focusStart = Duration.zero;
    }
    if (time != null && time > _focusStart!) {
      _focusEnd = time;
    } else {
      _focusEnd = null;
    }
    notifyListeners();
  }

  void clearFocusRange() {
    _focusStart = null;
    _focusEnd = null;
    notifyListeners();
  }
  int get backgroundColor => selectedBackground?.color ?? _backgroundColor;
  String? get backgroundImagePath => selectedBackground?.imagePath ?? _backgroundImagePath;
  double get backgroundScale => selectedBackground?.scale ?? _backgroundScale;
  double get backgroundRotation => selectedBackground?.rotation ?? _backgroundRotation;
  double get backgroundX => selectedBackground?.x ?? _backgroundX;
  double get backgroundY => selectedBackground?.y ?? _backgroundY;
  int get backgroundFillMode => selectedBackground?.fillMode ?? _backgroundFillMode;

  Duration _clampTime(Duration time) {
    if (time < Duration.zero) return Duration.zero;
    return time;
  }
  Duration get totalDuration {
    if (_audioPath != null) return _totalDuration;
    
    int maxMs = 5000; 
    
    for (var t in _tracks) {
      for (var c in t.clips) {
        if (c.endTime.inMilliseconds > maxMs) maxMs = c.endTime.inMilliseconds;
      }
    }
    for (var t in _overlayTracks) {
      for (var c in t.overlays) {
        if (c.endTime.inMilliseconds > maxMs) maxMs = c.endTime.inMilliseconds;
      }
    }
    for (var t in _backgroundTracks) {
      for (var c in t.backgrounds) {
        if (c.endTime.inMilliseconds > maxMs) maxMs = c.endTime.inMilliseconds;
      }
    }
    for (var t in _audioTracks) {
      for (var c in t.audioClips) {
        if (c.endTime.inMilliseconds > maxMs) maxMs = c.endTime.inMilliseconds;
      }
    }
    return Duration(milliseconds: maxMs);
  }
  bool get isPlaying => _isPlaying;
  AudioClip? get selectedAudio {
    if (selectedClipId == null) return null;
    for (var track in _audioTracks) {
      for (var clip in track.audioClips) {
        if (clip.id == selectedClipId) return clip;
      }
    }
    return null;
  }
  bool get isExporting => _isExporting;
  Set<String> get selectedClipIds => _selectedClipIds;
  bool get isMultiSelectMode => _isMultiSelectMode;
  String? get whisperModelPath => _whisperModelPath;
  bool get isPlayheadLocked => _isPlayheadLocked;
  int get activeTabIndex => _activeTabIndex;

  List<TimelineClip> getSelectedClips() {
    final List<TimelineClip> selected = [];
    for (var track in _tracks) {
      for (var clip in track.clips) {
        if (_selectedClipIds.contains(clip.id)) selected.add(clip);
      }
    }
    for (var track in _overlayTracks) {
      for (var clip in track.overlays) {
        if (_selectedClipIds.contains(clip.id)) selected.add(clip);
      }
    }
    for (var track in _backgroundTracks) {
      for (var clip in track.backgrounds) {
        if (_selectedClipIds.contains(clip.id)) selected.add(clip);
      }
    }
    for (var track in _audioTracks) {
      for (var clip in track.audioClips) {
        if (_selectedClipIds.contains(clip.id)) selected.add(clip);
      }
    }
    return selected;
  }
  bool get isImportingModel => _isImportingModel;
  
  void togglePlayheadLock() {
    _isPlayheadLocked = !_isPlayheadLocked;
    if (_isPlayheadLocked && _isPlaying) {
      togglePlay();
    }
    notifyListeners();
  }
  bool get isAllSelected {
    final allIds = {
      ..._tracks.expand((t) => t.clips).map((c) => c.id),
      ..._overlayTracks.expand((t) => t.overlays).map((c) => c.id),
      ..._backgroundTracks.expand((t) => t.backgrounds).map((c) => c.id),
      ..._audioTracks.expand((t) => t.audioClips).map((c) => c.id),
    };
    return allIds.isNotEmpty && _selectedClipIds.containsAll(allIds);
  }
  String? get selectedClipId => _selectedClipIds.isNotEmpty ? _selectedClipIds.first : null;
  double get zoomLevel => _zoomLevel;
  double get aspectRatio => _aspectRatio;
  bool get isTimelineCollapsed => _isTimelineCollapsed;
  bool get isControlPanelCollapsed => _isControlPanelCollapsed;
  bool get showTextTracks => _showTextTracks;
  bool get showOverlayTracks => _showOverlayTracks;
  bool get showBackgroundTracks => _showBackgroundTracks;
  bool get showAudioTracks => _showAudioTracks;
  List<Duration> get markers => _markers;
  bool get isCollisionAdjustEnabled => _isCollisionAdjustEnabled;

  void toggleCollisionAdjust() {
    _isCollisionAdjustEnabled = !_isCollisionAdjustEnabled;
    notifyListeners();
  }

  String get projectId => _projectId;
  String get projectName => _projectName;

  void setProjectName(String name) {
    _projectName = name;
    notifyListeners();
  }

  Future<void> saveProject() async {
    if (_tracks.isEmpty && 
        _overlayTracks.isEmpty && 
        _backgroundTracks.isEmpty && 
        _audioTracks.isEmpty && 
        _audioPath == null) {
      return;
    }

    final project = Project(
      id: _projectId,
      name: _projectName,
      videoPath: _audioPath,
      videoWidth: 1920,
      videoHeight: 1080,
      aspectRatio: _aspectRatio,
      backgroundColor: _backgroundColor,
      backgroundImagePath: _backgroundImagePath,
      backgroundScale: _backgroundScale,
      backgroundRotation: _backgroundRotation,
      backgroundX: _backgroundX,
      backgroundY: _backgroundY,
      backgroundFillMode: _backgroundFillMode,
      tracks: [
        ..._tracks,
        ..._overlayTracks,
        ..._backgroundTracks,
        ..._audioTracks,
      ],
      textTimelineColor: _textTimelineColor,
      audioTimelineColor: _audioTimelineColor,
      overlayTimelineColor: _overlayTimelineColor,
      backgroundTimelineColor: _backgroundTimelineColor,
      lastModified: DateTime.now(),
    );
    await ProjectService.saveProject(project);
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  Future<void> loadProject(String id) async {
    final project = ProjectService.getProject(id);
    if (project != null) {
      _projectId = project.id;
      _projectName = project.name;
      _aspectRatio = project.aspectRatio;
      _backgroundColor = project.backgroundColor == 0xFF000000 ? 0xFFFFFFFF : project.backgroundColor;
      _backgroundImagePath = project.backgroundImagePath;
      _backgroundScale = project.backgroundScale;
      _backgroundRotation = project.backgroundRotation;
      _backgroundX = project.backgroundX;
      _backgroundY = project.backgroundY;
      _backgroundFillMode = project.backgroundFillMode;
      _textTimelineColor = project.textTimelineColor;
      _audioTimelineColor = project.audioTimelineColor;
      _overlayTimelineColor = project.overlayTimelineColor;
      _backgroundTimelineColor = project.backgroundTimelineColor;
      
      _tracks = [];
      _overlayTracks = [];
      _backgroundTracks = [];
      _audioTracks = [];
      
      for (var track in project.tracks) {
        switch (track.type) {
          case TrackType.text:
            _tracks.add(track);
            break;
          case TrackType.overlay:
            _overlayTracks.add(track);
            break;
          case TrackType.background:
            _backgroundTracks.add(track);
            break;
          case TrackType.audio:
            _audioTracks.add(track);
            break;
        }
      }
      
      if (project.videoPath != null) {
        await loadAudio(project.videoPath!);
      }
      
      syncToNative();
      _repairWaveforms(); // Run in background
      notifyListeners();
    }
  }

  Future<void> _repairWaveforms() async {
    bool changed = false;
    for (var track in _audioTracks) {
      for (int i = 0; i < track.audioClips.length; i++) {
        final clip = track.audioClips[i];
        if (clip.waveform == null || clip.waveform!.isEmpty) {
          final waveform = await _generateWaveform(clip.audioPath);
          if (waveform.isNotEmpty) {
            track.audioClips[i] = clip.copyWith(waveform: waveform);
            changed = true;
          }
        }
      }
    }
    if (changed) notifyListeners();
  }

  void createNewProject() {
    _projectId = const Uuid().v4();
    _projectName = "New Project ${DateTime.now().hour}:${DateTime.now().minute}";
    _tracks = [];
    _overlayTracks = [];
    _backgroundTracks = [];
    _audioTracks = [];
    _audioPath = null;
    _currentTime = Duration.zero;
    _totalDuration = Duration.zero;
    _selectedClipIds = {};
    _undoStack.clear();
    _redoStack.clear();
    
    _aspectRatio = 16 / 9;
    _backgroundColor = 0xFFFFFFFF;
    _backgroundImagePath = null;
    _backgroundScale = 1.0;
    _backgroundRotation = 0.0;
    _backgroundX = 0.0;
    _backgroundY = 0.0;
    _backgroundFillMode = 0;

    syncToNative();
    notifyListeners();
  }

  void setZoomLevel(double level) {
    _zoomLevel = level.clamp(0.0, 10.0);
    notifyListeners();
  }

  void toggleTimelineCollapse() {
    _isTimelineCollapsed = !_isTimelineCollapsed;
    notifyListeners();
  }

  void setAspectRatio(double ratio) {
    saveState();
    _aspectRatio = ratio;
    syncToNative();
    notifyListeners();
  }

  void toggleTextTracks() {
    _showTextTracks = !_showTextTracks;
    notifyListeners();
  }

  void toggleOverlayTracks() {
    _showOverlayTracks = !_showOverlayTracks;
    notifyListeners();
  }

  void toggleBackgroundTracks() {
    _showBackgroundTracks = !_showBackgroundTracks;
    notifyListeners();
  }

  void toggleAudioTracks() {
    _showAudioTracks = !_showAudioTracks;
    notifyListeners();
  }

  void setBackgroundColor(int color) {
    _backgroundColor = color;
    final selected = selectedBackground;
    if (selected != null) {
      updateClip(selected.id, color: color);
    } else {
      addBackgroundClip(color: color);
    }
    updateProjectSync();
    notifyListeners();
  }

  void setBackgroundImage(String? path) {
    final selected = selectedBackground;
    if (selected != null) {
      updateClip(selected.id, imagePath: path);
    } else if (path != null) {
      addBackgroundClip(imagePath: path);
    } else {
      saveState();
      _backgroundImagePath = null;
      syncToNative();
      notifyListeners();
    }
  }

  void setBackgroundScale(double scale) {
    final selected = selectedBackground;
    if (selected != null) {
      updateClip(selected.id, scale: scale);
    } else {
      saveState();
      _backgroundScale = scale;
      syncToNative();
      notifyListeners();
    }
  }

  void setBackgroundRotation(double rotation) {
    final selected = selectedBackground;
    if (selected != null) {
      updateClip(selected.id, rotation: rotation);
    } else {
      saveState();
      _backgroundRotation = rotation;
      syncToNative();
      notifyListeners();
    }
  }

  void setBackgroundX(double x) {
    final selected = selectedBackground;
    if (selected != null) {
      updateClip(selected.id, x: x);
    } else {
      saveState();
      _backgroundX = x;
      syncToNative();
      notifyListeners();
    }
  }

  void setBackgroundY(double y) {
    final selected = selectedBackground;
    if (selected != null) {
      updateClip(selected.id, y: y);
    } else {
      saveState();
      _backgroundY = y;
      syncToNative();
      notifyListeners();
    }
  }

  void setBackgroundFillMode(int mode) {
    final selected = selectedBackground;
    if (selected != null) {
      updateClip(selected.id, fillMode: mode);
    } else {
      saveState();
      _backgroundFillMode = mode;
      syncToNative();
      notifyListeners();
    }
  }

  int lastRenderWidth = 0;
  int lastRenderHeight = 0;

  void updateProjectSync({int? width, int? height}) {
    if (width != null) lastRenderWidth = width;
    if (height != null) lastRenderHeight = height;
    
    _bridge.updateProjectSettings(
      aspectRatio: _aspectRatio,
      backgroundColor: backgroundColor,
      backgroundImagePath: backgroundImagePath,
      width: width,
      height: height,
      bgScale: backgroundScale,
      bgRotation: backgroundRotation,
      bgX: backgroundX,
      bgY: backgroundY,
      bgFillMode: backgroundFillMode,
    );
  }

  Future<List<double>> _generateWaveform(String path) async {
    try {
      debugPrint('Generating waveform for: $path');
      final rawPcm = await _bridge.decodeAudioToPcm(path);
      if (rawPcm == null || rawPcm.isEmpty) {
        debugPrint('Waveform generation failed: PCM is null or empty');
        return [];
      }
      debugPrint('PCM decoded: ${rawPcm.length} samples');
      const int sampleRate = 16000; // Native side decodes to 16kHz mono
      const int pointsPerSecond = 50; 
      final durationSec = rawPcm.length / sampleRate.toDouble();
      final totalPoints = (durationSec * pointsPerSecond).toInt().clamp(50, 2000);
      
      if (totalPoints <= 0) return [];
      
      final int samplesPerBucket = (rawPcm.length / totalPoints).floor();
      if (samplesPerBucket <= 0) return [];

      final List<double> waveform = [];
      for (int i = 0; i < totalPoints; i++) {
        double max = 0;
        final start = i * samplesPerBucket;
        final end = (i + 1) * samplesPerBucket;
        for (int j = start; j < end && j < rawPcm.length; j++) {
          final val = rawPcm[j].abs();
          if (val > max) max = val;
        }
        waveform.add(max);
      }

      // Normalize waveform to ensure visibility
      if (waveform.isNotEmpty) {
        double peak = 0;
        for (var v in waveform) {
          if (v > peak) peak = v;
        }
        if (peak > 0) {
          for (int i = 0; i < waveform.length; i++) {
            waveform[i] = waveform[i] / peak;
          }
        }
      }

      return waveform;
    } catch (e) {
      debugPrint('Error generating waveform: $e');
      return [];
    }
  }

  void saveState() {
    _undoStack.add(_captureState());
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _markDirty();
    _saveProject();
    notifyListeners();
  }

  HistoryState _captureState() {
    return HistoryState(
      tracks: _tracks.map((t) => t.copyWith(clips: t.clips.map((c) => c.copyWith()).toList())).toList(),
      overlayTracks: _overlayTracks.map((t) => t.copyWith(overlays: t.overlays.map((c) => c.copyWith()).toList())).toList(),
      backgroundTracks: _backgroundTracks.map((t) => t.copyWith(backgrounds: t.backgrounds.map((c) => c.copyWith()).toList())).toList(),
      audioTracks: _audioTracks.map((t) => t.copyWith(audioClips: t.audioClips.map((c) => c.copyWith()).toList())).toList(),
      aspectRatio: _aspectRatio,
      backgroundColor: _backgroundColor,
      backgroundImagePath: _backgroundImagePath,
      backgroundScale: _backgroundScale,
      backgroundRotation: _backgroundRotation,
      backgroundX: _backgroundX,
      backgroundY: _backgroundY,
      backgroundFillMode: _backgroundFillMode,
      markers: List.from(_markers),
      mainAudioVolume: _mainAudioVolume,
    );
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    final currentState = _captureState();
    _redoStack.add(currentState);

    final prevState = _undoStack.removeLast();
    _applyState(prevState);
    syncToNative();
    _markDirty();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    final currentState = _captureState();
    _undoStack.add(currentState);

    final nextState = _redoStack.removeLast();
    _applyState(nextState);
    syncToNative();
    _markDirty();
    notifyListeners();
  }

  void _applyState(HistoryState state) {
    _tracks = state.tracks;
    _overlayTracks = state.overlayTracks;
    _backgroundTracks = state.backgroundTracks;
    _audioTracks = state.audioTracks;
    _aspectRatio = state.aspectRatio;
    _backgroundColor = state.backgroundColor;
    _backgroundImagePath = state.backgroundImagePath;
    _backgroundScale = state.backgroundScale;
    _backgroundRotation = state.backgroundRotation;
    _backgroundX = state.backgroundX;
    _backgroundY = state.backgroundY;
    _backgroundFillMode = state.backgroundFillMode;
    _markers.clear();
    _markers.addAll(state.markers);
    _mainAudioVolume = state.mainAudioVolume;
    _bridge.setMainAudioVolume(_mainAudioVolume);
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    notifyListeners();
  }

  List<TimelineClip> get selectedTimelineClips {
    if (_selectedClipIds.isEmpty) return [];
    final List<TimelineClip> selected = [];
    for (var track in _tracks) {
      selected.addAll(track.clips.where((c) => _selectedClipIds.contains(c.id)));
    }
    for (var track in _overlayTracks) {
      selected.addAll(track.overlays.where((c) => _selectedClipIds.contains(c.id)));
    }
    for (var track in _backgroundTracks) {
      selected.addAll(track.backgrounds.where((c) => _selectedClipIds.contains(c.id)));
    }
    return selected;
  }

  TimelineClip? get selectedTimelineClip {
    final clips = selectedTimelineClips;
    return clips.isNotEmpty ? clips.first : null;
  }

  SubtitleClip? get selectedClip {
    final clip = selectedTimelineClip;
    return clip is SubtitleClip ? clip : null;
  }

  OverlayClip? get selectedOverlay {
    final clip = selectedTimelineClip;
    return clip is OverlayClip ? clip : null;
  }

  BackgroundClip? get selectedBackground {
    final clip = selectedTimelineClip;
    return clip is BackgroundClip ? clip : null;
  }

  TrackType? _getClipType(String id) {
    for (var t in _tracks) {
      if (t.clips.any((c) => c.id == id)) return TrackType.text;
    }
    for (var t in _audioTracks) {
      if (t.audioClips.any((c) => c.id == id)) return TrackType.audio;
    }
    for (var t in _overlayTracks) {
      if (t.overlays.any((c) => c.id == id)) return TrackType.overlay;
    }
    for (var t in _backgroundTracks) {
      if (t.backgrounds.any((c) => c.id == id)) return TrackType.background;
    }
    return null;
  }

  void selectClip(String? id, {bool toggle = true}) {
    if (id == null) {
      _selectedClipIds = {};
    } else {
      final newType = _getClipType(id);
      
      if (_selectedClipIds.isNotEmpty) {
        final firstId = _selectedClipIds.first;
        final firstType = _getClipType(firstId);
        
        if (firstType != newType) {
          // Deselect previous type if new selection is different
          _selectedClipIds = {id};
        } else {
          if (_isMultiSelectMode && toggle) {
            toggleClipSelection(id);
            return; // toggleClipSelection handles notifyListeners
          } else {
            if (!_isMultiSelectMode || !_selectedClipIds.contains(id)) {
              _selectedClipIds = _isMultiSelectMode ? (Set.from(_selectedClipIds)..add(id)) : {id};
            }
          }
        }
      } else {
        _selectedClipIds = {id};
      }

      /* 
      // Removed auto-seek on selection to prevent playhead drift during precision editing.
      // If needed, we can re-enable this only if the playhead is outside the clip bounds.
      final clip = selectedTimelineClip;
      if (clip != null && !_isPlayheadLocked) {
        final center = Duration(
          milliseconds: (clip.startTime.inMilliseconds + clip.endTime.inMilliseconds) ~/ 2,
        );
        seekTo(center);
      }
      */
    }
    notifyListeners();
  }

  void toggleClipSelection(String id) {
    if (_selectedClipIds.contains(id)) {
      _selectedClipIds.remove(id);
    } else {
      final newType = _getClipType(id);
      if (_selectedClipIds.isNotEmpty) {
        final firstId = _selectedClipIds.first;
        final firstType = _getClipType(firstId);
        if (firstType != newType) {
          _selectedClipIds = {id};
        } else {
          _selectedClipIds.add(id);
        }
      } else {
        _selectedClipIds.add(id);
      }
    }
    notifyListeners();
  }

  void selectClips(Iterable<String> ids) {
    _selectedClipIds = Set.from(ids);
    notifyListeners();
  }

  void toggleSelectAll() {
    final allIds = {
      ..._tracks.expand((t) => t.clips).map((c) => c.id),
      ..._overlayTracks.expand((t) => t.overlays).map((c) => c.id),
      ..._backgroundTracks.expand((t) => t.backgrounds).map((c) => c.id),
      ..._audioTracks.expand((t) => t.audioClips).map((c) => c.id),
    };
    
    if (allIds.isEmpty) return;

    if (isAllSelected) {
      // Deselect only the clips that are currently in the timeline
      _selectedClipIds = _selectedClipIds.where((id) => !allIds.contains(id)).toSet();
    } else {
      // Add all current clips to selection
      _selectedClipIds = {..._selectedClipIds, ...allIds};
      _isMultiSelectMode = true; // Automatically enable multi-select
    }
    notifyListeners();
  }

  void selectClipAt(double x, double y, {bool deselectIfEmpty = true, bool toggle = true}) {
    TimelineClip? bestMatch;
    int highestTrack = -1;
    double closestDistSq = 1.0;

    for (int i = 0; i < _tracks.length; i++) {
      for (var clip in _tracks[i].clips) {
        if (_currentTime >= clip.startTime && _currentTime < clip.endTime) {
          final dx = clip.x - x;
          final dy = clip.y - y;
          final distSq = dx * dx + dy * dy;
          final threshold = 0.05 + (clip.fontSize / 1000) * clip.scale; 
          if (distSq < threshold * threshold) {
            if (i >= highestTrack) {
              highestTrack = i;
              bestMatch = clip;
              closestDistSq = distSq;
            }
          }
        }
      }
    }

    for (int i = 0; i < _overlayTracks.length; i++) {
      for (var clip in _overlayTracks[i].overlays) {
        if (_currentTime >= clip.startTime && _currentTime < clip.endTime) {
          final dx = clip.x - x;
          final dy = clip.y - y;
          final distSq = dx * dx + dy * dy;
          final threshold = 0.1 * clip.scale; 
          if (distSq < threshold * threshold) {
            int overlayEffectiveTrack = i + _tracks.length;
            if (overlayEffectiveTrack >= highestTrack) {
              highestTrack = overlayEffectiveTrack;
              bestMatch = clip;
              closestDistSq = distSq;
            }
          }
        }
      }
    }

    if (bestMatch != null) {
      selectClip(bestMatch.id, toggle: toggle);
    } else if (deselectIfEmpty) {
      selectClip(null);
    }
  }

  void updateClip(String id, {
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
    String? fontFamily,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    List<Keyframe>? keyframes,
    TextCase? textCase,
    String? imagePath,
    int? fillMode,
    CustomBlendMode? blendMode,
    bool silent = false,
  }) {
    updateClips([id],
      text: text,
      x: x,
      y: y,
      fontSize: fontSize,
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
      isShadowEnabled: isShadowEnabled,
      isBackgroundEnabled: isBackgroundEnabled,
      fontFamily: fontFamily,
      entranceAnimation: entranceAnimation,
      exitAnimation: exitAnimation,
      loopAnimation: loopAnimation,
      keyframes: keyframes,
      textCase: textCase,
      imagePath: imagePath,
      fillMode: fillMode,
      blendMode: blendMode,
      silent: silent,
    );
  }

  String _applyCasing(String text, TextCase casing) {
    switch (casing) {
      case TextCase.upper:
        return text.toUpperCase();
      case TextCase.lower:
        return text.toLowerCase();
      case TextCase.title:
        if (text.isEmpty) return text;
        final words = text.trim().split(RegExp(r'\s+'));
        return words.map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
      case TextCase.none:
      default:
        return text;
    }
  }
  void moveClips(Iterable<String> ids, double dx, double dy, {bool silent = false}) {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();

    for (var track in _tracks) {
      for (int i = 0; i < track.clips.length; i++) {
        final clip = track.clips[i];
        if (idSet.contains(clip.id)) {
          track.clips[i] = clip.copyWith(
            x: (clip.x + dx).clamp(-0.5, 1.5),
            y: (clip.y + dy).clamp(-0.5, 1.5),
          );
        }
      }
    }

    for (var track in _overlayTracks) {
      for (int i = 0; i < track.overlays.length; i++) {
        final clip = track.overlays[i];
        if (idSet.contains(clip.id)) {
          track.overlays[i] = clip.copyWith(
            x: (clip.x + dx).clamp(-0.5, 1.5),
            y: (clip.y + dy).clamp(-0.5, 1.5),
          );
        }
      }
    }

    for (var track in _backgroundTracks) {
      for (int i = 0; i < track.backgrounds.length; i++) {
        final clip = track.backgrounds[i];
        if (idSet.contains(clip.id)) {
          track.backgrounds[i] = clip.copyWith(
            x: (clip.x + dx).clamp(-0.5, 1.5),
            y: (clip.y + dy).clamp(-0.5, 1.5),
          );
        }
      }
    }

    if (!silent) {
      syncToNative();
      notifyListeners();
    } else {
      _bridge.updateClips(getAllClipsJson());
    }
  }

  List<Map<String, dynamic>> getAllClipsJson() {
    final allClips = _tracks.expand((t) => t.clips).map((c) => c.toJson()).toList();
    final allOverlays = _overlayTracks.expand((t) => t.overlays).map((c) => c.toJson()).toList();
    final allBackgrounds = _backgroundTracks.expand((t) => t.backgrounds).map((c) => c.toJson()).toList();
    return [...allBackgrounds, ...allOverlays, ...allClips];
  }


  void updateClips(Iterable<String> ids, {
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
    String? fontFamily,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    double? textOpacity,
    List<Keyframe>? keyframes,
    TextCase? textCase,
    String? imagePath,
    int? fillMode,
    double? volume,
    CustomBlendMode? blendMode,
    bool? isGlowEnabled,
    bool? isBendingEnabled,
    bool? isReflectionEnabled,
    int? glowColor,
    double? glowSize,
    double? bendingAmount,
    double? reflectionOffset,
    double? reflectionOpacity,
    int? reflectionColor,
    bool? isGradientEnabled,
    int? gradientColor1,
    int? gradientColor2,
    double? gradientAngle,
    bool silent = false,
  }) {
    final idSet = ids.toSet();
    final isPropertyUpdate = x != null || y != null || scale != null || rotation != null || opacity != null;
    
    for (var track in _tracks) {
      for (int i = 0; i < track.clips.length; i++) {
        final clip = track.clips[i];
        if (idSet.contains(clip.id)) {
          List<Keyframe>? updatedKeyframes = keyframes ?? clip.keyframes;
          
          if (isPropertyUpdate && keyframes == null && clip.keyframes.isNotEmpty) {
            final relPosSec = (_currentTime - clip.startTime).inMilliseconds / 1000.0;
            final newKeyframes = List<Keyframe>.from(clip.keyframes);
            final index = newKeyframes.indexWhere((k) => (k.timeOffset - relPosSec).abs() < 0.05);
            
            final keyframe = Keyframe(
              timeOffset: relPosSec,
              x: x ?? clip.x,
              y: y ?? clip.y,
              scale: scale ?? clip.scale,
              rotation: rotation ?? clip.rotation,
              opacity: opacity ?? clip.opacity,
            );

            if (index >= 0) {
              newKeyframes[index] = keyframe;
            } else {
              newKeyframes.add(keyframe);
              newKeyframes.sort((a, b) => a.timeOffset.compareTo(b.timeOffset));
            }
            updatedKeyframes = newKeyframes;
          }

          track.clips[i] = clip.copyWith(
            text: textCase != null ? _applyCasing(clip.text, textCase) : text,
            x: x,
            y: y,
            fontSize: fontSize,
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
            isStrokeEnabled: isStrokeEnabled,
            isGlowEnabled: isGlowEnabled,
            isBendingEnabled: isBendingEnabled,
            isReflectionEnabled: isReflectionEnabled,
            glowColor: glowColor,
            glowSize: glowSize,
            bendingAmount: bendingAmount,
            reflectionOffset: reflectionOffset,
            reflectionOpacity: reflectionOpacity,
            reflectionColor: reflectionColor,
            blendMode: blendMode,
            fontFamily: fontFamily,
            entranceAnimation: entranceAnimation,
            exitAnimation: exitAnimation,
            loopAnimation: loopAnimation,
            isGradientEnabled: isGradientEnabled,
            gradientColor1: gradientColor1,
            gradientColor2: gradientColor2,
            gradientAngle: gradientAngle,
            keyframes: updatedKeyframes,
          );
        }
      }
    }

    for (var track in _overlayTracks) {
      for (int i = 0; i < track.overlays.length; i++) {
        final clip = track.overlays[i];
        if (idSet.contains(clip.id)) {
          List<Keyframe>? updatedKeyframes = keyframes ?? clip.keyframes;

          if (isPropertyUpdate && keyframes == null && clip.keyframes.isNotEmpty) {
            final relPosSec = (_currentTime - clip.startTime).inMilliseconds / 1000.0;
            final newKeyframes = List<Keyframe>.from(clip.keyframes);
            final index = newKeyframes.indexWhere((k) => (k.timeOffset - relPosSec).abs() < 0.05);

            final keyframe = Keyframe(
              timeOffset: relPosSec,
              x: x ?? clip.x,
              y: y ?? clip.y,
              scale: scale ?? clip.scale,
              rotation: rotation ?? clip.rotation,
              opacity: opacity ?? clip.opacity,
            );

            if (index >= 0) {
              newKeyframes[index] = keyframe;
            } else {
              newKeyframes.add(keyframe);
              newKeyframes.sort((a, b) => a.timeOffset.compareTo(b.timeOffset));
            }
            updatedKeyframes = newKeyframes;
          }

          track.overlays[i] = clip.copyWith(
            x: x,
            y: y,
            rotation: rotation,
            scale: scale,
            opacity: opacity,
            isShadowEnabled: isShadowEnabled,
            shadowColor: shadowColor,
            shadowBlur: shadowBlur,
            shadowOffsetX: shadowOffsetX,
            shadowOffsetY: shadowOffsetY,
            isStrokeEnabled: isStrokeEnabled,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            imagePath: imagePath,
            entranceAnimation: entranceAnimation,
            exitAnimation: exitAnimation,
            loopAnimation: loopAnimation,
            isGlowEnabled: isGlowEnabled,
            glowColor: glowColor,
            glowSize: glowSize,
            isBendingEnabled: isBendingEnabled,
            bendingAmount: bendingAmount,
            isReflectionEnabled: isReflectionEnabled,
            reflectionOffset: reflectionOffset,
            reflectionOpacity: reflectionOpacity,
            reflectionColor: reflectionColor,
            keyframes: updatedKeyframes,
          );
        }
      }
    }
    
    for (var track in _backgroundTracks) {
      for (int i = 0; i < track.backgrounds.length; i++) {
        final clip = track.backgrounds[i];
        if (idSet.contains(clip.id)) {
          List<Keyframe>? updatedKeyframes = keyframes ?? clip.keyframes;
          double? finalScale = scale;
          int? finalFillMode = fillMode;

          if (fillMode == 3 || fillMode == 4) {
            final assetW = clip.assetWidth;
            final assetH = clip.assetHeight;
            final rot = (rotation ?? clip.rotation).abs() % 180;
            final isSwapped = rot > 45 && rot < 135;

            if (assetW > 0 && assetH > 0) {
              final effectiveW = isSwapped ? assetH : assetW;
              final effectiveH = isSwapped ? assetW : assetH;

              if (fillMode == 3) {
                finalScale = (1080 * _aspectRatio) / effectiveW;
              } else {
                finalScale = 1080 / effectiveH;
              }
              finalFillMode = 2; // Switch to Center mode for manual scale
            }
          }

          if (isPropertyUpdate && keyframes == null && clip.keyframes.isNotEmpty) {
            final relPosSec = (_currentTime - clip.startTime).inMilliseconds / 1000.0;
            final newKeyframes = List<Keyframe>.from(clip.keyframes);
            final index = newKeyframes.indexWhere((k) => (k.timeOffset - relPosSec).abs() < 0.05);

            final keyframe = Keyframe(
              timeOffset: relPosSec,
              x: x ?? clip.x,
              y: y ?? clip.y,
              scale: finalScale ?? clip.scale,
              rotation: rotation ?? clip.rotation,
              opacity: opacity ?? clip.opacity,
            );

            if (index >= 0) {
              newKeyframes[index] = keyframe;
            } else {
              newKeyframes.add(keyframe);
              newKeyframes.sort((a, b) => a.timeOffset.compareTo(b.timeOffset));
            }
            updatedKeyframes = newKeyframes;
          }

          track.backgrounds[i] = clip.copyWith(
            x: x,
            y: y,
            rotation: rotation,
            scale: finalScale,
            opacity: opacity,
            color: color,
            imagePath: imagePath,
            fillMode: finalFillMode,
            entranceAnimation: entranceAnimation,
            exitAnimation: exitAnimation,
            loopAnimation: loopAnimation,
            keyframes: updatedKeyframes,
          );
        }
      }
    }

    for (var track in _audioTracks) {
      for (int i = 0; i < track.audioClips.length; i++) {
        final clip = track.audioClips[i];
        if (idSet.contains(clip.id)) {
          if (clip.isMainAudio && volume != null) {
            _mainAudioVolume = volume;
            _bridge.setMainAudioVolume(volume);
          }
          track.audioClips[i] = clip.copyWith(
            volume: volume,
          );
        }
      }
    }
    
    if (!silent) {
      syncToNative();
      _markDirty();
      notifyListeners();
    } else {
      _bridge.updateClips(getAllClipsJson());
    }
  }

  void applyPreset(String clipId, AnimationPreset preset) {
    updateClip(
      clipId,
      entranceAnimation: preset.entrance,
      exitAnimation: preset.exit,
    );
  }

  void syncToNative() {
    // Combine all and ensure unique clips (by ID + type) to prevent native engine glitches
    final Map<String, Map<String, dynamic>> uniqueClips = {};
    
    // Create copies of tracks to prevent ConcurrentModificationError during expansion
    final tracksCopy = List<Track>.from(_tracks);
    final overlayTracksCopy = List<Track>.from(_overlayTracks);
    final backgroundTracksCopy = List<Track>.from(_backgroundTracks);

    final allClips = tracksCopy.expand((t) => t.clips).map((c) {
      final map = c.toJson();
      map['isText'] = true;
      return map;
    }).toList();

    final allOverlays = overlayTracksCopy.expand((t) => t.overlays).map((c) {
      final map = c.toJson();
      map['isText'] = false;
      map['imagePath'] = c.imagePath;
      return map;
    }).toList();

    final allBackgrounds = backgroundTracksCopy.expand((t) => t.backgrounds).map((c) {
      final map = c.toJson();
      map['isBackground'] = true;
      map['isText'] = false;
      map['isOverlay'] = false;
      return map;
    }).toList();

    for (var m in [...allBackgrounds, ...allOverlays, ...allClips]) {
      final typePrefix = m['isBackground'] == true ? "bg_" : (m['isOverlay'] == true ? "ov_" : "tx_");
      uniqueClips[typePrefix + m['id'].toString()] = m;
    }

    _recalculateTotalDuration();
    _bridge.setTotalDuration(_totalDuration.inMilliseconds);

    _bridge.updateClips(uniqueClips.values.toList());
    _bridge.updateProjectSettings(
      aspectRatio: _aspectRatio,
      backgroundColor: _backgroundColor,
      backgroundImagePath: _backgroundImagePath,
      bgScale: _backgroundScale,
      bgRotation: _backgroundRotation,
      bgX: _backgroundX,
      bgY: _backgroundY,
      bgFillMode: _backgroundFillMode,
    );
    _pushAudioToNative();
  }

  void _pushAudioToNative() {
    final List<String> ids = [];
    final List<String> paths = [];
    final List<int> starts = [];
    final List<int> ends = [];
    final List<double> vols = [];

    for (var track in _audioTracks) {
      for (var clip in track.audioClips) {
        ids.add(clip.id);
        paths.add(clip.audioPath);
        starts.add(clip.startTime.inMilliseconds);
        ends.add(clip.endTime.inMilliseconds);
        vols.add(clip.volume);
      }
    }

    _bridge.setAudioClips(
      ids: ids,
      paths: paths,
      starts: starts,
      ends: ends,
      vols: vols,
    );
    _bridge.setMainAudioVolume(_mainAudioVolume);
  }

  void setMainAudioVolume(double volume) {
    _mainAudioVolume = volume;
    
    // Update the volume of the main audio clip in the tracks as well
    for (var track in _audioTracks) {
      for (int i = 0; i < track.audioClips.length; i++) {
        if (track.audioClips[i].isMainAudio) {
          track.audioClips[i] = track.audioClips[i].copyWith(volume: volume);
        }
      }
    }
    
    _bridge.setMainAudioVolume(_mainAudioVolume);
    _pushAudioToNative(); // This pushes the updated clip volumes to C++
    _saveProject();
    notifyListeners();
  }

  void setTimelineColor(String type, int color) {
    switch (type) {
      case 'text': _textTimelineColor = color; break;
      case 'audio': _audioTimelineColor = color; break;
      case 'overlay': _overlayTimelineColor = color; break;
      case 'background': _backgroundTimelineColor = color; break;
    }
    saveState();
    notifyListeners();
  }

  Future<void> _loadPersistedProject() async {
    try {
      final box = Hive.box('project_box');
      final data = box.get('project_state');
      if (data != null) {
        final Map<String, dynamic> state = Map<String, dynamic>.from(data);
        
        _aspectRatio = state['aspectRatio'] ?? 16 / 9;
        _backgroundColor = state['backgroundColor'] ?? 0xFFFFFFFF;
        _backgroundImagePath = state['backgroundImagePath'];
        _backgroundScale = (state['backgroundScale'] as num?)?.toDouble() ?? 1.0;
        _backgroundRotation = (state['backgroundRotation'] as num?)?.toDouble() ?? 0.0;
        _backgroundX = (state['backgroundX'] as num?)?.toDouble() ?? 0.0;
        _backgroundY = (state['backgroundY'] as num?)?.toDouble() ?? 0.0;
        _backgroundFillMode = state['backgroundFillMode'] ?? 0;
        _whisperModelPath = state['whisperModelPath'];
        _audioPath = state['audioPath'];
        _mainAudioVolume = (state['mainAudioVolume'] as num?)?.toDouble() ?? 1.0;

        _tracks = (state['tracks'] as List? ?? []).map((t) => Track.fromJson(Map<String, dynamic>.from(t))).toList();
        _overlayTracks = (state['overlayTracks'] as List? ?? []).map((t) => Track.fromJson(Map<String, dynamic>.from(t))).toList();
        _backgroundTracks = (state['backgroundTracks'] as List? ?? []).map((t) => Track.fromJson(Map<String, dynamic>.from(t))).toList();
        _audioTracks = (state['audioTracks'] as List? ?? []).map((t) => Track.fromJson(Map<String, dynamic>.from(t))).toList();
      }
    } catch (e) {
      print("Error loading project: $e");
    } finally {
      _isInitialized = true;
      syncToNative();
      notifyListeners();
    }
  }


  void _init() async {
    await _bridge.initAudioEngine();
    _loadSettings();
    await _loadPersistedProject();
  }

  void _saveProject() {
    try {
      final box = Hive.box('project_box');
      final Map<String, dynamic> state = {
        'aspectRatio': _aspectRatio,
        'backgroundColor': _backgroundColor,
        'backgroundImagePath': _backgroundImagePath,
        'backgroundScale': _backgroundScale,
        'backgroundRotation': _backgroundRotation,
        'backgroundX': _backgroundX,
        'backgroundY': _backgroundY,
        'backgroundFillMode': _backgroundFillMode,
        'whisperModelPath': _whisperModelPath,
        'audioPath': _audioPath,
        'mainAudioVolume': _mainAudioVolume,
        'tracks': _tracks.map((t) => t.toJson()).toList(),
        'overlayTracks': _overlayTracks.map((t) => t.toJson()).toList(),
        'backgroundTracks': _backgroundTracks.map((t) => t.toJson()).toList(),
        'audioTracks': _audioTracks.map((t) => t.toJson()).toList(),
      };
      box.put('project_state', state);
    } catch (e) {
      print("Error saving project: $e");
    }
  }

  void _loadSettings() {
    try {
      final box = Hive.box('settings_box');
      final ratios = box.get('custom_aspect_ratios');
      if (ratios != null) {
        _customAspectRatios = List<double>.from(ratios);
      }
      final layouts = box.get('custom_layouts');
      if (layouts != null) {
        final List<dynamic> list = layouts;
        _customLayouts = list.map((l) => CustomLayout.fromJson(Map<String, dynamic>.from(l))).toList();
      }
      _lastUsedDirectory = box.get('last_used_directory');
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  void addCustomAspectRatio(double ratio) {
    if (!_customAspectRatios.any((r) => (r - ratio).abs() < 0.001)) {
      _customAspectRatios.add(ratio);
      _saveSettings();
      notifyListeners();
    }
  }

  void removeCustomAspectRatio(double ratio) {
    _customAspectRatios.removeWhere((r) => (r - ratio).abs() < 0.001);
    _saveSettings();
    notifyListeners();
  }

  void _saveSettings() {
    try {
      final box = Hive.box('settings_box');
      box.put('custom_aspect_ratios', _customAspectRatios);
      box.put('custom_layouts', _customLayouts.map((l) => l.toJson()).toList());
      box.put('last_used_directory', _lastUsedDirectory);
    } catch (e) {
      debugPrint("Error saving settings: $e");
    }
  }

  void updateLastUsedDirectory(String? path) {
    if (path == null) return;
    final dir = p.dirname(path);
    if (_lastUsedDirectory != dir) {
      _lastUsedDirectory = dir;
      _saveSettings();
      notifyListeners();
    }
  }

  Future<void> loadAudio(String path) async {
    _audioPath = path;
    _bridge.setMainAudio(path);
    
    final durationMs = await _bridge.getVideoDuration(path);
    final duration = Duration(milliseconds: durationMs);
    _mainMediaDuration = duration;
    _totalDuration = duration;
    
    for (var track in _audioTracks) {
      track.audioClips.removeWhere((c) => c.isMainAudio);
    }
    
    // Generate waveform data
    final waveform = await _generateWaveform(path);
    
    final mainClip = AudioClip(
      id: 'main_audio_${DateTime.now().millisecondsSinceEpoch}',
      audioPath: path,
      startTime: Duration.zero,
      endTime: duration,
      isMainAudio: true,
      volume: _mainAudioVolume,
      sourceDurationMs: durationMs,
      waveform: waveform,
    );
    
    if (_audioTracks.isEmpty) {
      _audioTracks.add(Track(id: 'audio_track_0', name: 'Audio 1', type: TrackType.audio, audioClips: []));
    }
    _audioTracks[0].audioClips.insert(0, mainClip);
    
    _pushAudioToNative();
    notifyListeners();
  }

  void deleteSelectedClips() {
    if (_selectedClipIds.isEmpty) return;
    saveState();
    
    for (var track in _tracks) {
      track.clips.removeWhere((c) => _selectedClipIds.contains(c.id));
    }
    for (var track in _overlayTracks) {
      track.overlays.removeWhere((c) => _selectedClipIds.contains(c.id));
    }
    for (var track in _backgroundTracks) {
      track.backgrounds.removeWhere((c) => _selectedClipIds.contains(c.id));
    }
    for (var track in _audioTracks) {
      track.audioClips.removeWhere((c) => _selectedClipIds.contains(c.id));
    }
    
    _selectedClipIds = {};
    syncToNative();
    notifyListeners();
  }

  void splitClip(String id) {
    // Defensive sync: ensure _currentTime matches the visual playhead
    _currentTime = playbackTime.value;
    _splitClipInternal(id, _currentTime);
    syncToNative();
    notifyListeners();
  }

  void splitSelectedClipsAtPlayhead() {
    if (_selectedClipIds.isEmpty) return;
    
    // Defensive sync: ensure _currentTime matches the visual playhead.
    _currentTime = playbackTime.value;
    
    saveState();
    
    final idsToSplit = List<String>.from(_selectedClipIds);
    bool anySplit = false;
    
    for (var id in idsToSplit) {
      if (_splitClipInternal(id, _currentTime)) {
        anySplit = true;
      }
    }
    
    if (anySplit) {
      syncToNative();
      notifyListeners();
    }
  }


  bool _splitClipInternal(String id, Duration splitTime) {
    TimelineClip? clip;
    int trackIdx = -1;
    int clipIdx = -1;
    int type = 0; // 0: subtitle, 1: overlay, 2: background, 3: audio
    
    for (int i = 0; i < _tracks.length; i++) {
      final idx = _tracks[i].clips.indexWhere((c) => c.id == id);
      if (idx != -1) {
        clip = _tracks[i].clips[idx];
        trackIdx = i;
        clipIdx = idx;
        type = 0;
        break;
      }
    }
    
    if (clip == null) {
      for (int i = 0; i < _overlayTracks.length; i++) {
        final idx = _overlayTracks[i].overlays.indexWhere((c) => c.id == id);
        if (idx != -1) {
          clip = _overlayTracks[i].overlays[idx];
          trackIdx = i;
          clipIdx = idx;
          type = 1;
          break;
        }
      }
    }

    if (clip == null) {
      for (int i = 0; i < _backgroundTracks.length; i++) {
        final idx = _backgroundTracks[i].backgrounds.indexWhere((c) => c.id == id);
        if (idx != -1) {
          clip = _backgroundTracks[i].backgrounds[idx];
          trackIdx = i;
          clipIdx = idx;
          type = 2;
          break;
        }
      }
    }
    
    if (clip == null) {
      for (int i = 0; i < _audioTracks.length; i++) {
        final idx = _audioTracks[i].audioClips.indexWhere((c) => c.id == id);
        if (idx != -1) {
          clip = _audioTracks[i].audioClips[idx];
          trackIdx = i;
          clipIdx = idx;
          type = 3;
          break;
        }
      }
    }
    
    if (clip == null) return false;
    
    if (splitTime <= clip.startTime || splitTime >= clip.endTime) {
      return false;
    }
    
    final oldEndTime = clip.endTime;
    final splitOffsetSec = (splitTime - clip.startTime).inMicroseconds / 1000000.0;
    
    // Helper to split keyframes
    List<Keyframe> splitKeyframes(List<Keyframe> original, bool isSecondHalf) {
      if (isSecondHalf) {
        return original
            .where((k) => k.timeOffset >= splitOffsetSec)
            .map((k) => k.copyWith(timeOffset: k.timeOffset - splitOffsetSec))
            .toList();
      } else {
        return original
            .where((k) => k.timeOffset < splitOffsetSec)
            .toList();
      }
    }

    if (type == 1) { // Overlay
      final oldClip = clip as OverlayClip;
      final newClip = oldClip.copyWith(
        id: '${DateTime.now().millisecondsSinceEpoch}_${id}_2',
        startTime: splitTime,
        endTime: oldEndTime,
        keyframes: splitKeyframes(oldClip.keyframes, true),
      );
      
      _overlayTracks[trackIdx].overlays[clipIdx] = oldClip.copyWith(
        endTime: splitTime,
        keyframes: splitKeyframes(oldClip.keyframes, false),
      );
      _overlayTracks[trackIdx].overlays.insert(clipIdx + 1, newClip);
    } else if (type == 2) { // Background
      final oldClip = clip as BackgroundClip;
      final newClip = oldClip.copyWith(
        id: '${DateTime.now().millisecondsSinceEpoch}_${id}_2',
        startTime: splitTime,
        endTime: oldEndTime,
        keyframes: splitKeyframes(oldClip.keyframes, true),
      );
      
      _backgroundTracks[trackIdx].backgrounds[clipIdx] = oldClip.copyWith(
        endTime: splitTime,
        keyframes: splitKeyframes(oldClip.keyframes, false),
      );
      _backgroundTracks[trackIdx].backgrounds.insert(clipIdx + 1, newClip);
    } else if (type == 3) { // Audio
      final oldClip = clip as AudioClip;
      final newClip = oldClip.copyWith(
        id: '${DateTime.now().millisecondsSinceEpoch}_${id}_2',
        startTime: splitTime,
        endTime: oldEndTime,
        // Audio might need sourceStartTime adjustment if implemented, but for now we follow the pattern
      );
      
      _audioTracks[trackIdx].audioClips[clipIdx] = oldClip.copyWith(endTime: splitTime);
      _audioTracks[trackIdx].audioClips.insert(clipIdx + 1, newClip);
    } else { // Subtitle (0)
      final oldClip = clip as SubtitleClip;
      final newClip = oldClip.copyWith(
        id: '${DateTime.now().millisecondsSinceEpoch}_${id}_2',
        startTime: splitTime,
        endTime: oldEndTime,
        keyframes: splitKeyframes(oldClip.keyframes, true),
      );
      
      _tracks[trackIdx].clips[clipIdx] = oldClip.copyWith(
        endTime: splitTime,
        keyframes: splitKeyframes(oldClip.keyframes, false),
      );
      _tracks[trackIdx].clips.insert(clipIdx + 1, newClip);
    }
    
    return true;
  }

  void resetProject() {
    _tracks = [];
    _overlayTracks = [];
    _backgroundTracks = [];
    _audioPath = null;
    _currentTime = Duration.zero;
    _totalDuration = Duration.zero;
    _selectedClipIds = {};
    
    _aspectRatio = 16 / 9;
    _backgroundColor = 0xFFFFFFFF;
    _backgroundImagePath = null;
    _backgroundScale = 1.0;
    _backgroundRotation = 0.0;
    _backgroundX = 0.0;
    _backgroundY = 0.0;
    _backgroundFillMode = 0;

    syncToNative();
    notifyListeners();
  }

  Future<void> loadSubtitles(String path, String format) async {
    final file = File(path);
    final content = await file.readAsString();
    List<SubtitleClip> clips;
    
    if (format == 'json') {
      clips = SubtitleParser.parseJson(content);
    } else {
      clips = SubtitleParser.parseAss(content);
    }

    _tracks = [Track(id: 'main', clips: clips.map((c) => c.copyWith(originalTrackId: 'main')).toList())];
    
    await _bridge.updateClips(clips.map((c) => c.toJson()).toList());
    notifyListeners();
  }

  Future<void> importPlainText(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    await generateSubtitlesFromText(content);
  }

  Future<void> generateSubtitlesFromText(String content, {bool stackInDifferentTracks = false}) async {
    saveState();
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    _tracks = [];
    Duration currentStart = Duration.zero;
    const duration = Duration(milliseconds: 500);

    if (stackInDifferentTracks) {
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        final clipId = DateTime.now().millisecondsSinceEpoch.toString() + i.toString();
        final startTime = currentStart;
        final endTime = startTime + duration;

        final clip = SubtitleClip(
          id: clipId,
          text: word,
          startTime: startTime,
          endTime: endTime,
          x: 0.5,
          y: 0.5,
          originalTrackId: 'track_$i',
          originalStartTime: startTime,
          originalEndTime: endTime,
        );

        _tracks.add(Track(
          id: 'track_$i',
          name: 'Track ${i + 1}',
          clips: [clip],
        ));

        currentStart += duration;
        if (endTime > _totalDuration) _totalDuration = endTime;
      }
    } else {
      final List<SubtitleClip> clips = [];
      for (var word in words) {
        final clipId = DateTime.now().millisecondsSinceEpoch.toString() + clips.length.toString();
        clips.add(SubtitleClip(
          id: clipId,
          text: word,
          startTime: currentStart,
          endTime: currentStart + duration,
          x: 0.5,
          y: 0.5,
          originalTrackId: 'main',
          originalStartTime: currentStart,
          originalEndTime: currentStart + duration,
        ));
        currentStart += duration;
      }
      _tracks = [Track(id: 'main', name: 'Main Track', clips: clips)];
      if (currentStart > _totalDuration) _totalDuration = currentStart;
    }

    syncToNative();
    notifyListeners();
  }

  Future<void> generateSentencesFromText(String content, {bool stackInDifferentTracks = true}) async {
    saveState();
    // Split by newlines; each line is one segment
    final lines = content.split(RegExp(r'\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    
    _tracks = [];
    Duration currentStart = Duration.zero;
    const duration = Duration(milliseconds: 2000);

    if (stackInDifferentTracks) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final clipId = DateTime.now().millisecondsSinceEpoch.toString() + i.toString();
        final startTime = currentStart;
        final endTime = startTime + duration;

        final clip = SubtitleClip(
          id: clipId,
          text: line,
          startTime: startTime,
          endTime: endTime,
          x: 0.5,
          y: 0.5,
          originalTrackId: 'track_$i',
          originalStartTime: startTime,
          originalEndTime: endTime,
        );

        _tracks.add(Track(
          id: 'track_$i',
          name: 'Track ${i + 1}',
          clips: [clip],
        ));

        currentStart += duration;
        if (endTime > _totalDuration) _totalDuration = endTime;
      }
    } else {
      final List<SubtitleClip> clips = [];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final clipId = DateTime.now().millisecondsSinceEpoch.toString() + i.toString();
        clips.add(SubtitleClip(
          id: clipId,
          text: line,
          startTime: currentStart,
          endTime: currentStart + duration,
          x: 0.5,
          y: 0.5,
          originalTrackId: 'main',
          originalStartTime: currentStart,
          originalEndTime: currentStart + duration,
        ));
        currentStart += duration;
      }
      _tracks = [Track(id: 'main', name: 'Main Track', clips: clips)];
      if (currentStart > _totalDuration) _totalDuration = currentStart;
    }

    syncToNative();
    notifyListeners();
  }

  void togglePlay() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_isPlaying) return;
    _isPlaying = true;
    _lastTick = DateTime.now();

    if (isFocusModeEnabled) {
      if (_currentTime < _focusStart! || _currentTime >= _focusEnd!) {
        _currentTime = _focusStart!;
        _bridge.seekTo(_currentTime.inMilliseconds);
        _bridge.seekAudioEngine(_currentTime.inMilliseconds);
        playbackTime.value = _currentTime;
      }
    }

    _bridge.setPlaying(true);
    _bridge.startAudioEngine();
    _bridge.seekAudioEngine(_currentTime.inMilliseconds);

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) async {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      final nativePosMs = await _bridge.getAudioPosition();
      
      // CRITICAL: Guard against stale async responses after playback stopped.
      if (!_isPlaying) return;
      
      _currentTime = Duration(milliseconds: nativePosMs);
      
      if (isFocusModeEnabled) {
        if (_currentTime >= _focusEnd! || _currentTime < _focusStart!) {
          seekTo(_focusStart!);
          return;
        }
      } else {
        final duration = totalDuration;
        if (_currentTime >= duration) {
          _currentTime = duration;
          _stopPlayback();
          return;
        }
      }

      playbackTime.value = _currentTime;
    });
    
    notifyListeners();
  }

  void _stopPlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _bridge.setPlaying(false);
    _bridge.stopAudioEngine();
    notifyListeners();
  }

  void seekTo(Duration time) {
    _currentTime = _clampTime(time);
    playbackTime.value = _currentTime;
    
    _bridge.seekTo(_currentTime.inMilliseconds);
    _bridge.seekAudioEngine(_currentTime.inMilliseconds);
    notifyListeners();
  }


  void addClip(String text) {
    saveState();
    final startTime = _currentTime;
    final endTime = _currentTime + const Duration(milliseconds: 200);
    
    // Find a track that is "free" at this time
    int targetTrackIdx = -1;
    for (int i = 0; i < _tracks.length; i++) {
        bool isBusy = false;
        for (var clip in _tracks[i].clips) {
            // Standard collision check: overlaps if (start < clip.end && end > clip.start)
            if (startTime < clip.endTime && endTime > clip.startTime) {
                isBusy = true;
                break;
            }
        }
        if (!isBusy) {
            targetTrackIdx = i;
            break;
        }
    }

    if (targetTrackIdx == -1) {
        // All tracks busy at this position, create a new track
        _tracks.add(Track(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Track ${_tracks.length + 1}',
          type: TrackType.text,
          clips: [],
        ));
        targetTrackIdx = _tracks.length - 1;
    }

    final newClip = SubtitleClip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      startTime: startTime,
      endTime: endTime,
      y: 0.5, // Center by default for manual clips
      originalTrackId: _tracks[targetTrackIdx].id,
      originalStartTime: startTime,
      originalEndTime: endTime,
    );

    _tracks[targetTrackIdx].clips.add(newClip);
    
    syncToNative();
    selectClip(newClip.id);
    notifyListeners();
  }

  Future<void> addOverlay(String imagePath) async {
    saveState();
    final duration = await _bridge.getVideoDuration(imagePath);
    final newOverlay = OverlayClip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      startTime: _currentTime,
      endTime: _currentTime + const Duration(seconds: 3),
      sourceDurationMs: duration,
      originalTrackId: _overlayTracks.isNotEmpty ? _overlayTracks[0].id : 'overlay_main',
    );

    if (_overlayTracks.isEmpty) {
      _overlayTracks = [Track(id: 'overlay_main', name: 'Overlays', type: TrackType.overlay, overlays: [])];
    }
    
    _resolveCollisions(newOverlay, 0);
    syncToNative();
    selectClip(newOverlay.id);
    notifyListeners();
  }

  Future<void> addBackgroundClip({String? imagePath, int color = 0xFFFFFFFF}) async {
    saveState();
    int duration = 0;
    int width = 0;
    int height = 0;
    
    if (imagePath != null) {
      duration = await _bridge.getVideoDuration(imagePath);
      final res = await _bridge.getAssetResolution(imagePath);
      width = res['width'] ?? 0;
      height = res['height'] ?? 0;
    }
    
    final contentDuration = _getContentDuration();
    var startTime = _currentTime;
    var endTime = _currentTime + const Duration(seconds: 5);
    
    if (contentDuration > Duration.zero) {
      if (startTime > contentDuration) startTime = contentDuration;
      if (endTime > contentDuration) endTime = contentDuration;
    }

    final newClip = BackgroundClip(
      id: "bg_${DateTime.now().millisecondsSinceEpoch}",
      imagePath: imagePath,
      color: color,
      startTime: startTime,
      endTime: endTime,
      sourceDurationMs: duration,
      assetWidth: width,
      assetHeight: height,
      originalTrackId: _backgroundTracks.isNotEmpty ? _backgroundTracks[0].id : 'bg_main',
    );

    if (_backgroundTracks.isEmpty) {
      _backgroundTracks = [Track(id: 'bg_main', name: 'Backgrounds', type: TrackType.background, backgrounds: [])];
    }
    
    _resolveCollisions(newClip, 0);
    syncToNative();
    selectClip(newClip.id);
    notifyListeners();
  }

  void mergeSelectedClips() {
    if (_selectedClipIds.length < 2) return;
    
    saveState();
    
    // Find target track and ensure all selected clips are on it
    Track? targetTrack;
    final List<SubtitleClip> selectedClips = [];
    
    for (final track in _tracks) {
      bool hasSome = false;
      bool hasAllFromSelection = true;
      final List<SubtitleClip> foundInTrack = [];
      
      for (final clip in track.clips) {
        if (_selectedClipIds.contains(clip.id)) {
          foundInTrack.add(clip);
          hasSome = true;
        }
      }
      
      if (hasSome) {
        if (targetTrack != null) {
          // Already found clips in another track, merging across tracks not supported
          return;
        }
        targetTrack = track;
        selectedClips.addAll(foundInTrack);
      }
    }
    
    if (targetTrack == null || selectedClips.length != _selectedClipIds.length) {
      return;
    }
    
    // Sort by start time to check consecutiveness
    selectedClips.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Check if they are consecutive in the track's sorted clips list
    final allClipsInTrack = List<SubtitleClip>.from(targetTrack.clips);
    allClipsInTrack.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    int firstIndex = allClipsInTrack.indexWhere((c) => c.id == selectedClips.first.id);
    for (int i = 0; i < selectedClips.length; i++) {
      if (allClipsInTrack[firstIndex + i].id != selectedClips[i].id) {
        // Not consecutive
        return;
      }
    }
    
    // Create merged clip
    final first = selectedClips.first;
    final last = selectedClips.last;
    
    final mergedClip = first.copyWith(
      text: selectedClips.map((c) => c.text).join(' '),
      endTime: last.endTime,
      id: "merged_${DateTime.now().millisecondsSinceEpoch}",
      keyframes: [...first.keyframes], // Keep first clip keyframes
    );
    
    // Remove old clips
    targetTrack.clips.removeWhere((c) => _selectedClipIds.contains(c.id));
    targetTrack.clips.add(mergedClip);
    targetTrack.clips.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    _selectedClipIds = {mergedClip.id};
    
    syncToNative();
    notifyListeners();
  }

  void splitSelectedClipToWords() {
    final clip = selectedTimelineClip;
    if (clip == null || clip is! SubtitleClip) return;
    
    final subtitleClip = clip as SubtitleClip;
    final words = subtitleClip.text.trim().split(RegExp(r'\s+'));
    if (words.length <= 1) return;
    
    saveState();
    
    final totalDuration = subtitleClip.duration;
    final durationPerWord = Duration(microseconds: (totalDuration.inMicroseconds / words.length).toInt());
    
    Track? targetTrack;
    for (final track in _tracks) {
      if (track.clips.any((c) => c.id == subtitleClip.id)) {
        targetTrack = track;
        break;
      }
    }
    if (targetTrack == null) return;

    final List<SubtitleClip> newClips = [];
    var currentStart = subtitleClip.startTime;
    
    for (var i = 0; i < words.length; i++) {
      final isLast = i == words.length - 1;
      final endTime = isLast ? subtitleClip.endTime : currentStart + durationPerWord;
      
      newClips.add(subtitleClip.copyWith(
        id: "word_${DateTime.now().millisecondsSinceEpoch}_$i",
        text: words[i],
        startTime: currentStart,
        endTime: endTime,
        keyframes: [], 
      ));
      
      currentStart = endTime;
    }
    
    // Replace old clip with new clips
    targetTrack.clips.removeWhere((c) => c.id == clip.id);
    targetTrack.clips.addAll(newClips);
    targetTrack.clips.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Select all child segments by default and enable multi-select
    _selectedClipIds = newClips.map((c) => c.id).toSet();
    _isMultiSelectMode = true;
    
    syncToNative();
    notifyListeners();
  }

  void burstSelectedClipToStackedWords() {
    final clip = selectedTimelineClip;
    if (clip == null || clip is! SubtitleClip) return;
    
    final subtitleClip = clip as SubtitleClip;
    final words = subtitleClip.text.trim().split(RegExp(r'\s+'));
    if (words.length <= 1) return;
    
    saveState();
    
    Track? targetTrack;
    int baseTrackIndex = 999;
    for (int i = 0; i < _tracks.length; i++) {
      if (_tracks[i].clips.any((c) => c.id == subtitleClip.id)) {
        targetTrack = _tracks[i];
        baseTrackIndex = i;
        break;
      }
    }
    if (targetTrack == null) return;

    final List<SubtitleClip> newClips = [];
    
    const double gap = 0.12;
    final double totalHeight = (words.length - 1) * gap;
    final double startY = (1.0 - totalHeight) / 2;
    
    final totalDuration = subtitleClip.duration;
    final durationPerWord = Duration(microseconds: (totalDuration.inMicroseconds / words.length).toInt());
    var currentStart = subtitleClip.startTime;
    
    for (var i = 0; i < words.length; i++) {
      final isLast = i == words.length - 1;
      final endTime = isLast ? subtitleClip.endTime : currentStart + durationPerWord;
      
      newClips.add(subtitleClip.copyWith(
        id: "burst_${DateTime.now().millisecondsSinceEpoch}_$i",
        text: words[i],
        x: 0.5,
        y: startY + (i * gap),
        startTime: currentStart,
        endTime: endTime,
        keyframes: [], 
      ));
      
      currentStart = endTime;
    }
    
    // Replace old clip with new clips in vertically stacked tracks
    targetTrack.clips.removeWhere((c) => c.id == clip.id);
    
    for (int i = 0; i < newClips.length; i++) {
        int targetTrackIdx = baseTrackIndex + (newClips.length - 1 - i);

        while (_tracks.length <= targetTrackIdx) {
            _tracks.add(Track(
                id: DateTime.now().millisecondsSinceEpoch.toString() + _tracks.length.toString(),
                name: 'Track ${_tracks.length + 1}',
                clips: [],
            ));
        }

        _resolveCollisions(newClips[i], targetTrackIdx);
    }
    
    // Select all the new words so they can be laid out
    _selectedClipIds = newClips.map((c) => c.id).toSet();
    _isMultiSelectMode = true;
    
    syncToNative();
    notifyListeners();
  }

  void addNewTrack(TrackType type) {
    saveState();
    if (type == TrackType.text) {
      _tracks.add(Track(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Track ${_tracks.length + 1}',
        type: TrackType.text,
        clips: [],
      ));
    } else if (type == TrackType.overlay) {
      _overlayTracks.add(Track(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Overlay Track ${_overlayTracks.length + 1}',
        type: TrackType.overlay,
        overlays: [],
      ));
    } else if (type == TrackType.background) {
      _backgroundTracks.add(Track(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Background Track ${_backgroundTracks.length + 1}',
        type: TrackType.background,
        backgrounds: [],
      ));
    } else if (type == TrackType.audio) {
      _audioTracks.add(Track(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Audio Track ${_audioTracks.length + 1}',
        type: TrackType.audio,
        audioClips: [],
      ));
    }
    notifyListeners();
  }

  void removeTrack(String id) {
    saveState();
    _tracks.removeWhere((t) => t.id == id && t.isEmpty);
    _overlayTracks.removeWhere((t) => t.id == id && t.isEmpty);
    _backgroundTracks.removeWhere((t) => t.id == id && t.isEmpty);
    _audioTracks.removeWhere((t) => t.id == id && t.isEmpty);
    
    // Ensure at least one track remains if it was the last one (optional, based on _cleanupEmptyTracks logic)
    if (_tracks.isEmpty) _tracks.add(Track(id: '${DateTime.now().millisecondsSinceEpoch}_t', name: 'Track 1', type: TrackType.text, clips: []));
    if (_overlayTracks.isEmpty) _overlayTracks.add(Track(id: '${DateTime.now().millisecondsSinceEpoch}_o', name: 'Overlay 1', type: TrackType.overlay, overlays: []));
    if (_backgroundTracks.isEmpty) _backgroundTracks.add(Track(id: '${DateTime.now().millisecondsSinceEpoch}_b', name: 'Background 1', type: TrackType.background, backgrounds: []));
    if (_audioTracks.isEmpty) _audioTracks.add(Track(id: '${DateTime.now().millisecondsSinceEpoch}_a', name: 'Audio 1', type: TrackType.audio, audioClips: []));

    syncToNative();
    notifyListeners();
  }

  bool get isKeyframeAtCurrentTime {
    final clip = selectedTimelineClip;
    if (clip == null) return false;
    final relPosSec = (_currentTime - clip.startTime).inMilliseconds / 1000.0;
    return clip.keyframes.any((k) => (k.timeOffset - relPosSec).abs() < 0.05);
  }

  void addKeyframeAtCurrentTime() {
    final clip = selectedTimelineClip;
    if (clip == null) return;

    final relPosMs = (_currentTime - clip.startTime).inMilliseconds;
    if (relPosMs < 0 || _currentTime > clip.endTime) return;

    final relPosSec = relPosMs / 1000.0;

    final newKeyframes = List<Keyframe>.from(clip.keyframes);
    final index = newKeyframes.indexWhere((k) => (k.timeOffset - relPosSec).abs() < 0.05);

    if (index >= 0) {
      newKeyframes.removeAt(index);
    } else {
      final keyframe = Keyframe(
        timeOffset: relPosSec,
        x: clip.x,
        y: clip.y,
        scale: clip.scale,
        rotation: clip.rotation,
        opacity: clip.opacity,
      );
      newKeyframes.add(keyframe);
      newKeyframes.sort((a, b) => a.timeOffset.compareTo(b.timeOffset));
    }

    updateClip(clip.id, keyframes: newKeyframes);
  }

  void clearKeyframes() {
    final clip = selectedTimelineClip;
    if (clip == null) return;
    updateClip(clip.id, keyframes: []);
  }

  void updateClipTiming(dynamic clip, Duration? newStart, Duration? newEnd, {bool resolveCollisions = true}) {
    if (newStart == null && newEnd == null) return;

    int currentTrackIdx = -1;
    int clipIdx = -1;
    final bool isOverlay = clip is OverlayClip;
    final bool isBackground = clip is BackgroundClip;
    final bool isAudio = clip is AudioClip;
    
    final trackList = isOverlay ? _overlayTracks : (isBackground ? _backgroundTracks : (isAudio ? _audioTracks : _tracks));

    for (int i = 0; i < trackList.length; i++) {
        final List<TimelineClip> clipsOnTrack;
        if (isOverlay) {
          clipsOnTrack = trackList[i].overlays;
        } else if (isBackground) {
          clipsOnTrack = trackList[i].backgrounds;
        } else if (isAudio) {
          clipsOnTrack = trackList[i].audioClips;
        } else {
          clipsOnTrack = trackList[i].clips;
        }
        
        final idx = clipsOnTrack.indexWhere((c) => c.id == clip.id);
        if (idx != -1) {
            currentTrackIdx = i;
            clipIdx = idx;
            break;
        }
    }
    
    if (currentTrackIdx != -1) {
        final TimelineClip foundClip;
        if (isOverlay) {
          foundClip = trackList[currentTrackIdx].overlays.removeAt(clipIdx);
        } else if (isBackground) {
          foundClip = trackList[currentTrackIdx].backgrounds.removeAt(clipIdx);
        } else if (isAudio) {
          foundClip = trackList[currentTrackIdx].audioClips.removeAt(clipIdx);
        } else {
          foundClip = trackList[currentTrackIdx].clips.removeAt(clipIdx);
        }
           
        var startTime = _clampTime(newStart ?? foundClip.startTime);
        var endTime = _clampTime(newEnd ?? foundClip.endTime);
        
        // Ensure startTime < endTime
        if (startTime >= endTime) {
          if (newStart != null) {
            startTime = endTime - const Duration(milliseconds: 100);
          } else {
            endTime = startTime + const Duration(milliseconds: 100);
          }
          startTime = _clampTime(startTime);
        }

        if (isBackground) {
          final contentDuration = _getContentDuration();
          if (contentDuration > Duration.zero) {
            if (endTime > contentDuration) endTime = contentDuration;
            if (startTime > contentDuration) startTime = contentDuration;
          }
        }

        final TimelineClip updatedClip;
        if (isOverlay) {
          updatedClip = (foundClip as OverlayClip).copyWith(startTime: startTime, endTime: endTime);
        } else if (isBackground) {
          updatedClip = (foundClip as BackgroundClip).copyWith(startTime: startTime, endTime: endTime);
        } else if (isAudio) {
          updatedClip = (foundClip as AudioClip).copyWith(startTime: startTime, endTime: endTime);
        } else {
          updatedClip = (foundClip as SubtitleClip).copyWith(startTime: startTime, endTime: endTime);
        }

        if (_isCollisionAdjustEnabled && !isAudio) {
          _handleCollisionPush(trackList[currentTrackIdx], updatedClip);
        }

        if (resolveCollisions) {
            _resolveCollisions(updatedClip, currentTrackIdx);
        } else {
            if (isOverlay) {
                trackList[currentTrackIdx].overlays.insert(clipIdx, updatedClip as OverlayClip);
            } else if (isBackground) {
                trackList[currentTrackIdx].backgrounds.insert(clipIdx, updatedClip as BackgroundClip);
            } else if (isAudio) {
                trackList[currentTrackIdx].audioClips.insert(clipIdx, updatedClip as AudioClip);
            } else {
                trackList[currentTrackIdx].clips.insert(clipIdx, updatedClip as SubtitleClip);
            }
        }

        // Real-time sync for preview
        syncToNative();
        notifyListeners();
    }
  }

  int getCurrentTrackIndex(TimelineClip clip) {
    final bool isOverlay = clip is OverlayClip;
    final bool isBackground = clip is BackgroundClip;
    final bool isAudio = clip is AudioClip;
    final trackList = isOverlay ? _overlayTracks : (isBackground ? _backgroundTracks : (isAudio ? _audioTracks : _tracks));

    for (int i = 0; i < trackList.length; i++) {
      final List<TimelineClip> clips;
      if (isOverlay) clips = trackList[i].overlays;
      else if (isBackground) clips = trackList[i].backgrounds;
      else if (isAudio) clips = trackList[i].audioClips;
      else clips = trackList[i].clips;

      if (clips.any((c) => c.id == clip.id)) return i;
    }
    return -1;
  }

  List<int> getAvailableTrackIndices(TimelineClip clip) {
    final bool isOverlay = clip is OverlayClip;
    final bool isBackground = clip is BackgroundClip;
    final bool isAudio = clip is AudioClip;
    final trackList = isOverlay ? _overlayTracks : (isBackground ? _backgroundTracks : (isAudio ? _audioTracks : _tracks));
    
    List<int> available = [];
    for (int i = 0; i < trackList.length; i++) {
      final List<TimelineClip> clips;
      if (isOverlay) clips = trackList[i].overlays;
      else if (isBackground) clips = trackList[i].backgrounds;
      else if (isAudio) clips = trackList[i].audioClips;
      else clips = trackList[i].clips;

      bool hasCollision = false;
      for (var existing in clips) {
        if (existing.id == clip.id) continue;
        if (clip.startTime < existing.endTime && existing.startTime < clip.endTime) {
          hasCollision = true;
          break;
        }
      }
      if (!hasCollision) {
        available.add(i);
      }
    }
    return available;
  }

  void forceResolveCollisions(String clipId) {
    int trackIdx = -1;
    int clipIdx = -1;
    bool isOverlay = false;
    
    for (int i = 0; i < _tracks.length; i++) {
      final idx = _tracks[i].clips.indexWhere((c) => c.id == clipId);
      if (idx != -1) {
        trackIdx = i;
        clipIdx = idx;
        break;
      }
    }
    
    if (trackIdx == -1) {
      for (int i = 0; i < _overlayTracks.length; i++) {
        final idx = _overlayTracks[i].overlays.indexWhere((c) => c.id == clipId);
        if (idx != -1) {
          trackIdx = i;
          clipIdx = idx;
          isOverlay = true;
          break;
        }
      }
    }

    bool isBackground = false;
    if (trackIdx == -1) {
      for (int i = 0; i < _backgroundTracks.length; i++) {
        final idx = _backgroundTracks[i].backgrounds.indexWhere((c) => c.id == clipId);
        if (idx != -1) {
          trackIdx = i;
          clipIdx = idx;
          isBackground = true;
          break;
        }
      }
    }

    if (trackIdx != -1) {
      final clip = isOverlay 
          ? _overlayTracks[trackIdx].overlays.removeAt(clipIdx)
          : isBackground
            ? _backgroundTracks[trackIdx].backgrounds.removeAt(clipIdx)
            : _tracks[trackIdx].clips.removeAt(clipIdx);
      _resolveCollisions(clip, trackIdx);
    }
  }

  void stackSelectedClips() {
    if (_selectedClipIds.isEmpty) return;

    // ONLY for Text Clips for now as per previous logic
    List<SubtitleClip> selectedClips = [];
    int baseTrackIndex = 999;

    for (int i = 0; i < _tracks.length; i++) {
        for (var clip in _tracks[i].clips) {
            if (_selectedClipIds.contains(clip.id)) {
                selectedClips.add(clip);
                if (i < baseTrackIndex) baseTrackIndex = i;
            }
        }
    }

    if (selectedClips.isEmpty) return;

    selectedClips.sort((a, b) => a.startTime.compareTo(b.startTime));

    Duration maxEndTime = Duration.zero;
    for (var clip in selectedClips) {
        if (clip.endTime > maxEndTime) maxEndTime = clip.endTime;
    }

    for (var track in _tracks) {
        track.clips.removeWhere((c) => _selectedClipIds.contains(c.id));
    }

    const double gap = 0.12; // Increased for better readability
    final double totalHeight = (selectedClips.length - 1) * gap;
    final double startY = (1.0 - totalHeight) / 2;

    for (int i = 0; i < selectedClips.length; i++) {
        final clip = selectedClips[i];
        final updatedClip = clip.copyWith(
          endTime: maxEndTime,
          x: 0.5,
          y: startY + (i * gap),
          keyframes: [], // Clear keyframes to ensure new position is respected
        );
        
        int targetTrackIdx = baseTrackIndex + (selectedClips.length - 1 - i);

        while (_tracks.length <= targetTrackIdx) {
            _tracks.add(Track(
                id: DateTime.now().millisecondsSinceEpoch.toString() + _tracks.length.toString(),
                name: 'Track ${_tracks.length + 1}',
                clips: [],
            ));
        }

        _resolveCollisions(updatedClip, targetTrackIdx);
    }
    
    syncToNative();
    notifyListeners();
  }

  void applyLayoutPreset(LayoutPreset preset) {
    if (_selectedClipIds.isEmpty) return;
    saveState();

    List<SubtitleClip> selectedClips = [];
    for (var track in _tracks) {
      for (var clip in track.clips) {
        if (_selectedClipIds.contains(clip.id)) {
          selectedClips.add(clip);
        }
      }
    }

    if (selectedClips.isEmpty) return;
    
    // Sort by original Y to maintain some order
    selectedClips.sort((a, b) => a.y.compareTo(b.y));

    final int count = selectedClips.length;

    switch (preset) {
      case LayoutPreset.column:
        const double gap = 0.12;
        final double totalHeight = (count - 1) * gap;
        final double startY = (1.0 - totalHeight) / 2;
        for (int i = 0; i < count; i++) {
          updateClip(selectedClips[i].id, x: 0.5, y: startY + (i * gap));
        }
        break;
      case LayoutPreset.grid:
        final int cols = count <= 4 ? 2 : (count <= 9 ? 3 : 4);
        final int rows = (count / cols).ceil();
        final double cellW = 1.0 / cols;
        final double cellH = 0.7 / rows; 
        for (int i = 0; i < count; i++) {
          final int r = i ~/ cols;
          final int c = i % cols;
          updateClip(selectedClips[i].id, 
            x: (c + 0.5) * cellW, 
            y: 0.15 + (r + 0.5) * cellH
          );
        }
        break;
      case LayoutPreset.bento:
        final List<Map<String, double>> bentoOffsets = [
          {'x': 0.3, 'y': 0.3}, {'x': 0.7, 'y': 0.35},
          {'x': 0.25, 'y': 0.65}, {'x': 0.65, 'y': 0.7},
          {'x': 0.5, 'y': 0.5}, {'x': 0.15, 'y': 0.45},
          {'x': 0.85, 'y': 0.55}, {'x': 0.4, 'y': 0.8},
        ];
        for (int i = 0; i < count; i++) {
          final offset = bentoOffsets[i % bentoOffsets.length];
          updateClip(selectedClips[i].id, x: offset['x'], y: offset['y']);
        }
        break;
      case LayoutPreset.random:
        final random = DateTime.now().millisecondsSinceEpoch;
        for (int i = 0; i < count; i++) {
          final rx = (((random + i * 789) % 70) + 15) / 100.0;
          final ry = (((random + i * 321) % 70) + 15) / 100.0;
          updateClip(selectedClips[i].id, x: rx, y: ry);
        }
        break;
      case LayoutPreset.staggered:
        for (int i = 0; i < count; i++) {
          final offset = (i % 2 == 0) ? -0.2 : 0.2;
          updateClip(selectedClips[i].id, x: 0.5 + offset, y: 0.15 + (i * (0.7 / count)));
        }
        break;
      case LayoutPreset.stairs:
        for (int i = 0; i < count; i++) {
          final stepX = 0.2 + (i * (0.6 / (count > 1 ? count - 1 : 1)));
          final stepY = 0.2 + (i * (0.6 / (count > 1 ? count - 1 : 1)));
          updateClip(selectedClips[i].id, x: stepX, y: stepY);
        }
        break;
      case LayoutPreset.wave:
        for (int i = 0; i < count; i++) {
          final px = 0.15 + (i * (0.7 / (count > 1 ? count - 1 : 1)));
          final py = 0.5 + math.sin(i * 0.8) * 0.25;
          updateClip(selectedClips[i].id, x: px, y: py);
        }
        break;
      case LayoutPreset.circle:
        final double radius = 0.3;
        for (int i = 0; i < count; i++) {
          final angle = (i / count) * 2.0 * math.pi;
          updateClip(selectedClips[i].id, 
            x: 0.5 + math.cos(angle) * radius, 
            y: 0.5 + math.sin(angle) * radius
          );
        }
        break;
      case LayoutPreset.spiral:
        for (int i = 0; i < count; i++) {
          final r = 0.05 + (i * 0.35 / count);
          final angle = i * 0.8;
          updateClip(selectedClips[i].id, 
            x: 0.5 + math.cos(angle) * r, 
            y: 0.5 + math.sin(angle) * r
          );
        }
        break;
      default:
        break;
    }

    syncToNative();
    notifyListeners();
  }

  void saveCurrentLayoutAsPreset(String name) {
    if (_selectedClipIds.isEmpty) return;
    
    List<SubtitleClip> selectedClips = [];
    for (var track in _tracks) {
      for (var clip in track.clips) {
        if (_selectedClipIds.contains(clip.id)) {
          selectedClips.add(clip);
        }
      }
    }
    
    if (selectedClips.isEmpty) return;
    
    // Sort to maintain logical order
    selectedClips.sort((a, b) => a.y.compareTo(b.y));
    
    final positions = selectedClips.map((c) => LayoutPosition(x: c.x, y: c.y)).toList();
    
    final layout = CustomLayout(
      id: const Uuid().v4(),
      name: name,
      positions: positions,
    );
    
    _customLayouts.add(layout);
    _saveSettings();
    notifyListeners();
    ToastUtils.show("Layout '$name' saved!");
  }

  void deleteCustomLayout(String id) {
    _customLayouts.removeWhere((l) => l.id == id);
    _saveSettings();
    notifyListeners();
  }

  void applyCustomLayout(CustomLayout layout) {
    if (_selectedClipIds.isEmpty) return;
    saveState();

    List<SubtitleClip> selectedClips = [];
    for (var track in _tracks) {
      for (var clip in track.clips) {
        if (_selectedClipIds.contains(clip.id)) {
          selectedClips.add(clip);
        }
      }
    }

    if (selectedClips.isEmpty) return;
    
    selectedClips.sort((a, b) => a.y.compareTo(b.y));

    for (int i = 0; i < selectedClips.length; i++) {
      if (i < layout.positions.length) {
        final pos = layout.positions[i];
        updateClip(selectedClips[i].id, x: pos.x, y: pos.y);
      }
    }

    syncToNative();
    notifyListeners();
  }

  void resetSelectedClips() {
    if (_selectedClipIds.isEmpty) return;

    List<TimelineClip> clipsToReset = [];
    
    // Collect from all tracks
    for (var track in _tracks) {
      for (var clip in track.clips) {
        if (_selectedClipIds.contains(clip.id)) clipsToReset.add(clip);
      }
    }
    for (var track in _overlayTracks) {
      for (var clip in track.overlays) {
        if (_selectedClipIds.contains(clip.id)) clipsToReset.add(clip);
      }
    }
    for (var track in _backgroundTracks) {
      for (var clip in track.backgrounds) {
        if (_selectedClipIds.contains(clip.id)) clipsToReset.add(clip);
      }
    }

    // Remove from all tracks
    for (var track in _tracks) {
      track.clips.removeWhere((c) => _selectedClipIds.contains(c.id));
    }
    for (var track in _overlayTracks) {
      track.overlays.removeWhere((c) => _selectedClipIds.contains(c.id));
    }
    for (var track in _backgroundTracks) {
      track.backgrounds.removeWhere((c) => _selectedClipIds.contains(c.id));
    }

    for (var clip in clipsToReset) {
      final startTime = clip.originalStartTime;
      final endTime = clip.originalEndTime;

      final dynamic resetClip;
      if (clip is SubtitleClip) {
        resetClip = clip.copyWith(
          startTime: startTime, 
          endTime: endTime,
          x: 0.5,
          y: 0.5,
          scale: 1.0,
          rotation: 0.0,
          keyframes: [],
        );
      } else if (clip is OverlayClip) {
        resetClip = clip.copyWith(
          startTime: startTime, 
          endTime: endTime,
          x: 0.5,
          y: 0.5,
          scale: 1.0,
          rotation: 0.0,
          keyframes: [],
        );
      } else if (clip is BackgroundClip) {
        resetClip = clip.copyWith(
          startTime: startTime, 
          endTime: endTime,
          x: 0.5,
          y: 0.5,
          scale: 1.0,
          rotation: 0.0,
          keyframes: [],
        );
      } else {
        resetClip = clip;
      }

      final String? targetTrackId = clip.originalTrackId;
      
      final trackList = clip is SubtitleClip ? _tracks : (clip is OverlayClip ? _overlayTracks : _backgroundTracks);
      int trackIdx = -1;
      if (targetTrackId != null) {
        trackIdx = trackList.indexWhere((t) => t.id == targetTrackId);
      }
      if (trackIdx == -1) trackIdx = 0;

      _resolveCollisions(resetClip, trackIdx);
    }

    syncToNative();
    notifyListeners();
  }

  void _handleCollisionPush(Track track, TimelineClip adjustedClip) {
    // Only adjust clips on the SAME track
    final isOverlay = adjustedClip is OverlayClip;
    final isBackground = adjustedClip is BackgroundClip;
    
    final List<dynamic> clipsOnTrack;
    if (isOverlay) {
      clipsOnTrack = track.overlays;
    } else if (isBackground) {
      clipsOnTrack = track.backgrounds;
    } else if (adjustedClip is AudioClip) {
      clipsOnTrack = track.audioClips;
    } else {
      clipsOnTrack = track.clips;
    }

    for (int i = 0; i < clipsOnTrack.length; i++) {
      var other = clipsOnTrack[i];
      if (other.id == adjustedClip.id) continue;

      // Check for overlap
      if (adjustedClip.startTime < other.endTime && adjustedClip.endTime > other.startTime) {
        // We have a collision. Adjust the 'other' clip.
        
        // Case 1: adjustedClip pushed into other from the LEFT (dragging adjustedClip's END later)
        if (adjustedClip.endTime > other.startTime && adjustedClip.startTime <= other.startTime) {
          final newOtherStart = adjustedClip.endTime;
          if (newOtherStart < other.endTime) {
             // Shrink from left
             clipsOnTrack[i] = _updateClip(other, newOtherStart, other.endTime);
          } else {
             // Other clip is completely eclipsed, set to minimum width
             clipsOnTrack[i] = _updateClip(other, adjustedClip.endTime, adjustedClip.endTime + const Duration(milliseconds: 10));
          }
        }
        // Case 2: adjustedClip pushed into other from the RIGHT (dragging adjustedClip's START earlier)
        else if (adjustedClip.startTime < other.endTime && adjustedClip.endTime >= other.endTime) {
          final newOtherEnd = adjustedClip.startTime;
          if (newOtherEnd > other.startTime) {
             // Shrink from right
             clipsOnTrack[i] = _updateClip(other, other.startTime, newOtherEnd);
          } else {
             // Other clip eclipsed
             clipsOnTrack[i] = _updateClip(other, adjustedClip.startTime - const Duration(milliseconds: 10), adjustedClip.startTime);
          }
        }
      }
    }
  }

  dynamic _updateClip(dynamic clip, Duration start, Duration end) {
    if (clip is OverlayClip) return clip.copyWith(startTime: start, endTime: end);
    if (clip is BackgroundClip) return clip.copyWith(startTime: start, endTime: end);
    if (clip is AudioClip) return clip.copyWith(startTime: start, endTime: end);
    return (clip as SubtitleClip).copyWith(startTime: start, endTime: end);
  }

  void _resolveCollisions(TimelineClip clip, int trackIdx) {
    final bool isOverlay = clip is OverlayClip;
    final bool isBackground = clip is BackgroundClip;
    final bool isAudio = clip is AudioClip;
    
    final trackList = isOverlay 
        ? _overlayTracks 
        : (isBackground ? _backgroundTracks : (isAudio ? _audioTracks : _tracks));
    final trackType = isOverlay 
        ? TrackType.overlay 
        : (isBackground ? TrackType.background : (isAudio ? TrackType.audio : TrackType.text));

    int targetTrackIdx = trackIdx;
    bool hasCollision = true;

    while (hasCollision) {
        hasCollision = false;
        if (targetTrackIdx >= trackList.length) {
            addNewTrack(trackType);
        }

        final track = trackList[targetTrackIdx];
        final List<TimelineClip> clipsToCompare;
        if (isOverlay) {
          clipsToCompare = track.overlays;
        } else if (isBackground) {
          clipsToCompare = track.backgrounds;
        } else if (isAudio) {
          clipsToCompare = track.audioClips;
        } else {
          clipsToCompare = track.clips;
        }
        
        for (var existingClip in clipsToCompare) {
            if (existingClip.id != clip.id) {
                if (clip.startTime < existingClip.endTime && existingClip.startTime < clip.endTime) {
                    hasCollision = true;
                    break;
                }
            }
        }

        if (hasCollision) {
            targetTrackIdx++;
        }
    }

    if (isOverlay) {
        trackList[targetTrackIdx].overlays.add(clip as OverlayClip);
    } else if (isBackground) {
        trackList[targetTrackIdx].backgrounds.add(clip as BackgroundClip);
    } else if (isAudio) {
        trackList[targetTrackIdx].audioClips.add(clip as AudioClip);
    } else {
        trackList[targetTrackIdx].clips.add(clip as SubtitleClip);
    }
    _markDirty();
  }

  void moveClip(dynamic clip, String targetTrackId, Duration? newStartTime) {
    final bool isSelected = _selectedClipIds.contains(clip.id);
    final clipIdsToMove = isSelected ? _selectedClipIds.toSet() : {clip.id};

    final bool isOverlayMove = clip is OverlayClip;
    final bool isBackgroundMove = clip is BackgroundClip;
    final bool isAudioMove = clip is AudioClip;
    
    final trackList = isOverlayMove 
        ? _overlayTracks 
        : (isBackgroundMove ? _backgroundTracks : (isAudioMove ? _audioTracks : _tracks));
    final trackType = isOverlayMove 
        ? TrackType.overlay 
        : (isBackgroundMove ? TrackType.background : (isAudioMove ? TrackType.audio : TrackType.text));

    final Map<String, int> clipToCurrentTrackIndex = {};
    for (int i = 0; i < trackList.length; i++) {
      final List<TimelineClip> clipsOnTrack;
      if (isOverlayMove) {
        clipsOnTrack = trackList[i].overlays;
      } else if (isBackgroundMove) {
        clipsOnTrack = trackList[i].backgrounds;
      } else if (isAudioMove) {
        clipsOnTrack = trackList[i].audioClips;
      } else {
        clipsOnTrack = trackList[i].clips;
      }
      
      for (var c in clipsOnTrack) {
        if (clipIdsToMove.contains(c.id)) {
          clipToCurrentTrackIndex[c.id] = i;
        }
      }
    }

    if (!clipToCurrentTrackIndex.containsKey(clip.id)) return;

    final targetTrackIndex = trackList.indexWhere((t) => t.id == targetTrackId);
    if (targetTrackIndex == -1) return;
    
    final primaryCurrentIndex = clipToCurrentTrackIndex[clip.id]!;
    final trackOffset = targetTrackIndex - primaryCurrentIndex;

    final List<dynamic> clipsMoved = [];
    for (var clipId in clipIdsToMove) {
      final currTrackIdx = clipToCurrentTrackIndex[clipId];
      if (currTrackIdx != null) {
        final track = trackList[currTrackIdx];
        final List<TimelineClip> clipsOnTrack;
        if (isOverlayMove) {
          clipsOnTrack = track.overlays;
        } else if (isBackgroundMove) {
          clipsOnTrack = track.backgrounds;
        } else if (isAudioMove) {
          clipsOnTrack = track.audioClips;
        } else {
          clipsOnTrack = track.clips;
        }

        final index = clipsOnTrack.indexWhere((c) => c.id == clipId);
        if (index != -1) {
          clipsMoved.add(clipsOnTrack.removeAt(index));
        }
      }
    }

    final Duration timeOffset = newStartTime != null 
        ? newStartTime - (clip as TimelineClip).startTime 
        : Duration.zero;

    for (var c in clipsMoved) {
      final oldTrackIdx = clipToCurrentTrackIndex[(c as TimelineClip).id]!;
      int newTrackIdx = oldTrackIdx + trackOffset;
      if (newTrackIdx < 0) newTrackIdx = 0;

      while (newTrackIdx >= trackList.length) {
        addNewTrack(trackType);
      }

      final duration = c.endTime - c.startTime;
      var startTime = _clampTime(c.startTime + timeOffset);
      var endTime = _clampTime(startTime + duration);
      
      // Ensure we maintain duration if possible by shifting start back if end was clamped
      if (endTime == totalDuration && (endTime - startTime) < duration) {
          startTime = _clampTime(endTime - duration);
      }
      
      final dynamic updatedClip;
      if (isOverlayMove) {
        updatedClip = (c as OverlayClip).copyWith(startTime: startTime, endTime: startTime + duration);
      } else if (isBackgroundMove) {
        updatedClip = (c as BackgroundClip).copyWith(startTime: startTime, endTime: startTime + duration);
      } else if (isAudioMove) {
        updatedClip = (c as AudioClip).copyWith(startTime: startTime, endTime: startTime + duration);
      } else {
        updatedClip = (c as SubtitleClip).copyWith(startTime: startTime, endTime: startTime + duration);
      }

      _resolveCollisions(updatedClip, newTrackIdx);
    }

    _cleanupEmptyTracks();
    syncToNative();
    notifyListeners();
  }

  void _cleanupEmptyTracks() {
    _tracks.removeWhere((t) => t.clips.isEmpty);
    if (_tracks.isEmpty) {
      _tracks.add(Track(id: DateTime.now().millisecondsSinceEpoch.toString(), name: 'Track 1', type: TrackType.text, clips: []));
    }

    _overlayTracks.removeWhere((t) => t.overlays.isEmpty);
    if (_overlayTracks.isEmpty) {
      _overlayTracks.add(Track(id: '${DateTime.now().millisecondsSinceEpoch}_o', name: 'Overlay 1', type: TrackType.overlay, overlays: []));
    }

    _backgroundTracks.removeWhere((t) => t.backgrounds.isEmpty);
    if (_backgroundTracks.isEmpty) {
      _backgroundTracks.add(Track(id: '${DateTime.now().millisecondsSinceEpoch}_b', name: 'Background 1', type: TrackType.background, backgrounds: []));
    }

    _audioTracks.removeWhere((t) => t.audioClips.isEmpty);
    if (_audioTracks.isEmpty) {
      _audioTracks.add(Track(id: '${DateTime.now().millisecondsSinceEpoch}_a', name: 'Audio 1', type: TrackType.audio, audioClips: []));
    }
  }

  void seek(Duration pos) {
    if (_isPlayheadLocked) return;
    _currentTime = pos;
    playbackTime.value = pos;
    
    _bridge.seekTo(pos.inMilliseconds);
    _bridge.seekAudioEngine(pos.inMilliseconds);
    _lastTick = DateTime.now();
    notifyListeners();
  }


  void play() {
    _bridge.startAudioEngine();
  }

  void pause() {
    _bridge.stopAudioEngine();
  }

  Future<String?> exportVideo() async {
    if (_tracks.isEmpty) return null;
    
    _isExporting = true;
    notifyListeners();

    try {
      final allClips = [
        ..._backgroundTracks.expand((t) => t.backgrounds).map((c) {
          final map = c.toJson();
          map['isBackground'] = true;
          map['isText'] = false;
          return map;
        }),
        ..._overlayTracks.expand((t) => t.overlays).map((c) {
          final map = c.toJson();
          map['isText'] = false;
          map['imagePath'] = c.imagePath;
          return map;
        }),
        ..._tracks.expand((t) => t.clips).map((c) {
          final map = c.toJson();
          map['isText'] = true;
          return map;
        }),
      ];
      
      int w, h;
      if (_aspectRatio >= 1.0) {
        // Landscape or Square: width is the larger dimension
        w = 1920;
        h = (1920 / _aspectRatio).round();
      } else {
        // Portrait: height is the larger dimension
        h = 1920;
        w = (1920 * _aspectRatio).round();
      }
      // Ensure even dimensions for encoder compatibility
      if (w % 2 != 0) w -= 1;
      if (h % 2 != 0) h -= 1;

      final result = await _bridge.exportVideo(
        width: w,
        height: h,
        durationMs: totalDuration.inMilliseconds,
        clips: allClips,
        audioTracks: _audioTracks.map((t) => t.toJson()).toList(),
        audioPath: _audioPath,
        backgroundColor: _backgroundColor,
        backgroundImagePath: _backgroundImagePath,
        bgScale: _backgroundScale,
        bgRotation: _backgroundRotation,
        bgX: _backgroundX,
        bgY: _backgroundY,
        bgFillMode: _backgroundFillMode,
        aspectRatio: _aspectRatio,
      );
      
      return result;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>?> transcribeAudioRaw({String? prompt, String? language}) async {
    if (_audioPath == null) return null;
    if (_whisperModelPath == null || !File(_whisperModelPath!).existsSync()) {
      throw Exception("No Whisper model found. Please import a model first.");
    }
    
    _isExporting = true; 
    notifyListeners();

    try {
      final int? ptr = await _bridge.initWhisper(_whisperModelPath!);
      if (ptr == null || ptr == 0) throw Exception("Failed to initialize Whisper engine");

      final initialPrompt = prompt ?? "Transcribe this audio.";
      final targetLanguage = language ?? "auto";
      final String? jsonResult = await _bridge.transcribeWhisper(ptr, _audioPath!, initialPrompt, targetLanguage);
      
      await _bridge.freeWhisper(ptr);

      if (jsonResult == null || jsonResult.contains("error")) {
        throw Exception("Transcription failed: $jsonResult");
      }

      final List<dynamic> data = jsonDecode(jsonResult);
      final List<Map<String, dynamic>> processedSegments = [];

      for (var item in data) {
        final startMs = (item['start'] as num).toInt();
        final endMs = (item['end'] as num).toInt();
        var text = item['text'] as String;
        
        if (text.trim().isEmpty) continue;

        if (initialPrompt.toLowerCase().contains("hinglish") || initialPrompt.toLowerCase().contains("romanized")) {
          text = TransliterationUtils.devanagariToRoman(text);
        }

        processedSegments.add({
          'start': startMs,
          'end': endMs,
          'text': text.trim()
        });
      }

      return processedSegments;
    } catch (e) {
      print("Transcription error: $e");
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> forceAlignText(String text) async {
    if (_audioPath == null) {
      throw Exception("Import audio first before aligning script");
    }

    _isImportingModel = true; // Use this flag to show loading
    notifyListeners();

    try {
      final segments = await _alignService.alignText(text, _audioPath!);
      if (segments.isNotEmpty) {
        applyTranscriptionClips(segments);
      } else {
        throw Exception("No speech detected in audio or alignment failed.");
      }
    } catch (e) {
      print("Force Align Error: $e");
      rethrow; // Re-throw to be caught by the UI if needed
    } finally {
      _isImportingModel = false;
      notifyListeners();
    }
  }

  Future<void> addBulkAudioClips(String path) async {
    final selected = getSelectedClips();
    if (selected.isEmpty) return;
    
    saveState();
    
    final durationMs = await _bridge.getVideoDuration(path);
    final duration = durationMs > 0 ? Duration(milliseconds: durationMs) : const Duration(seconds: 1);
    
    for (var targetClip in selected) {
      final startTime = targetClip.startTime;
      final id = 'audio_${DateTime.now().millisecondsSinceEpoch}_${targetClip.id}';
      
      final clip = AudioClip(
        id: id,
        audioPath: path,
        startTime: startTime,
        endTime: startTime + duration,
        sourceDurationMs: durationMs,
      );

      // Find a track or create new
      Track? targetTrack;
      for (var track in _audioTracks) {
        bool hasCollision = false;
        for (var existing in track.audioClips) {
          if (clip.startTime < existing.endTime && clip.endTime > existing.startTime) {
            hasCollision = true;
            break;
          }
        }
        if (!hasCollision) {
          targetTrack = track;
          break;
        }
      }

      if (targetTrack == null) {
        targetTrack = Track(
          id: 'audio_track_${_audioTracks.length}',
          type: TrackType.audio,
          audioClips: [],
        );
        _audioTracks.add(targetTrack);
      }
      targetTrack.audioClips.add(clip);
    }

    _pushAudioToNative();
    notifyListeners();
    ToastUtils.show('Bulk SFX applied successfully');
  }

  Future<void> addAudioClip(String path) async {
    if (_isMultiSelectMode && _selectedClipIds.length > 1) {
      return addBulkAudioClips(path);
    }
    saveState();
    final id = 'audio_${DateTime.now().millisecondsSinceEpoch}';
    
    // Get actual duration from file using native bridge
    final durationMs = await _bridge.getVideoDuration(path);
    final duration = durationMs > 0 ? Duration(milliseconds: durationMs) : const Duration(seconds: 5);
    
    // Generate waveform data
    final waveform = await _generateWaveform(path);
    
    final clip = AudioClip(
      id: id,
      audioPath: path,
      startTime: _clampTime(_currentTime),
      endTime: _clampTime(_currentTime + duration),
      sourceDurationMs: durationMs,
      waveform: waveform,
    );

    // Find a track without collision or create new
    Track? targetTrack;
    for (var track in _audioTracks) {
      bool hasCollision = false;
      for (var existing in track.audioClips) {
        // Simple overlap check
        if (clip.startTime < existing.endTime && clip.endTime > existing.startTime) {
          hasCollision = true;
          break;
        }
      }
      if (!hasCollision) {
        targetTrack = track;
        break;
      }
    }

    if (targetTrack == null) {
      targetTrack = Track(
        id: 'audio_track_${_audioTracks.length}', 
        name: 'Audio ${_audioTracks.length + 1}', 
        type: TrackType.audio, 
        audioClips: []
      );
      _audioTracks.add(targetTrack);
    }
    
    targetTrack.audioClips.add(clip);
    _selectedClipIds = {id};
    _pushAudioToNative();
    notifyListeners();
    ToastUtils.show('SFX added successfully');
  }

  void applyTranscriptionClips(List<Map<String, dynamic>> data, {bool replaceExisting = true}) {
    saveState(); 

    if (replaceExisting) {
      _tracks.clear();
    }

    final List<SubtitleClip> newClips = [];
    for (var item in data) {
      final startMs = (item['start'] as num).toInt();
      final endMs = (item['end'] as num).toInt();
      final text = item['text'] as String;
      
      if (text.trim().isEmpty) continue;

      newClips.add(SubtitleClip(
        id: "clip_${DateTime.now().millisecondsSinceEpoch}_${newClips.length}",
        text: text.trim(),
        startTime: Duration(milliseconds: startMs),
        endTime: Duration(milliseconds: endMs),
      ));
    }

    if (newClips.isNotEmpty) {
      final newTrack = Track(
        id: "track_${DateTime.now().millisecondsSinceEpoch}",
        clips: newClips,
      );
      _tracks.add(newTrack);
      syncToNative();
      notifyListeners();
    }
  }


  Future<void> importModel(String originalPath) async {
    _isImportingModel = true;
    notifyListeners();
    try {
      final file = File(originalPath);
      if (!file.existsSync()) throw Exception("Source model file not found at $originalPath");

      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory(p.join(appDir.path, 'whisper_models'));
      if (!modelsDir.existsSync()) {
        await modelsDir.create(recursive: true);
      }

      final fileName = p.basename(originalPath);
      final newPath = p.join(modelsDir.path, fileName);
      
      // Copy the file
      await file.copy(newPath);
      
      _whisperModelPath = newPath;
      _markDirty();
      notifyListeners();
    } catch (e) {
      print("Error importing model: $e");
      rethrow;
    } finally {
      _isImportingModel = false;
      notifyListeners();
    }
  }

  void addMarker() {
    if (!_markers.any((m) => (m.inMilliseconds - _currentTime.inMilliseconds).abs() < 50)) {
      _markers.add(_currentTime);
      _markers.sort();
      notifyListeners();
    }
  }

  void removeMarker(Duration time) {
    _markers.removeWhere((m) => (m.inMilliseconds - time.inMilliseconds).abs() < 100);
    notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  void toggleControlPanelCollapse() {
    _isControlPanelCollapsed = !_isControlPanelCollapsed;
    notifyListeners();
  }

  void setControlPanelCollapsed(bool collapsed) {
    _isControlPanelCollapsed = collapsed;
    notifyListeners();
  }

  void setActiveTabIndex(int index) {
    _activeTabIndex = index;
    _isControlPanelCollapsed = false;
    notifyListeners();
  }

  Duration _getContentDuration() {
    Duration maxEnd = _mainMediaDuration;
    for (var track in _tracks) {
      for (var clip in track.clips) if (clip.endTime > maxEnd) maxEnd = clip.endTime;
    }
    for (var track in _overlayTracks) {
      for (var clip in track.overlays) if (clip.endTime > maxEnd) maxEnd = clip.endTime;
    }
    for (var track in _audioTracks) {
      for (var clip in track.audioClips) if (clip.endTime > maxEnd) maxEnd = clip.endTime;
    }
    return maxEnd;
  }

  void _recalculateTotalDuration() {
    Duration maxEnd = _mainMediaDuration;
    for (var track in _tracks) {
      for (var clip in track.clips) if (clip.endTime > maxEnd) maxEnd = clip.endTime;
    }
    for (var track in _overlayTracks) {
      for (var clip in track.overlays) if (clip.endTime > maxEnd) maxEnd = clip.endTime;
    }
    for (var track in _audioTracks) {
      for (var clip in track.audioClips) if (clip.endTime > maxEnd) maxEnd = clip.endTime;
    }
    for (var track in _backgroundTracks) {
      for (var clip in track.backgrounds) if (clip.endTime > maxEnd) maxEnd = clip.endTime;
    }
    
    _totalDuration = maxEnd;
    if (_totalDuration < const Duration(seconds: 1)) {
      _totalDuration = const Duration(seconds: 5);
    }
  }

  void applyOverlayMotionPreset(String clipId, String presetId) {
    saveState();
    _recalculateTotalDuration();
    final totalSec = _totalDuration.inMilliseconds / 1000.0;
    final endKeyframeTime = (totalSec - 0.001).clamp(0.0, totalSec);
    
    for (var track in _overlayTracks) {
      final index = track.overlays.indexWhere((c) => c.id == clipId);
      if (index != -1) {
        var clip = track.overlays[index];
        
        List<Keyframe> keyframes = [];
        
        switch (presetId) {
          case 'left_to_right':
            keyframes = [
              Keyframe(timeOffset: 0, x: -0.05),
              Keyframe(timeOffset: endKeyframeTime, x: 1.05),
            ];
            break;
          case 'right_to_left':
            keyframes = [
              Keyframe(timeOffset: 0, x: 1.05),
              Keyframe(timeOffset: endKeyframeTime, x: -0.05),
            ];
            break;
          case 'top_to_bottom':
            keyframes = [
              Keyframe(timeOffset: 0, y: -0.05),
              Keyframe(timeOffset: endKeyframeTime, y: 1.05),
            ];
            break;
          case 'bottom_to_top':
            keyframes = [
              Keyframe(timeOffset: 0, y: 1.05),
              Keyframe(timeOffset: endKeyframeTime, y: -0.05),
            ];
            break;
          case 'zoom_in':
            keyframes = [
              Keyframe(timeOffset: 0, scale: 0.1),
              Keyframe(timeOffset: endKeyframeTime, scale: 1.5),
            ];
            break;
          case 'zoom_out':
            keyframes = [
              Keyframe(timeOffset: 0, scale: 2.0),
              Keyframe(timeOffset: endKeyframeTime, scale: 1.0),
            ];
            break;
          case 'diagonal_tl_br':
            keyframes = [
              Keyframe(timeOffset: 0, x: -0.05, y: -0.05),
              Keyframe(timeOffset: endKeyframeTime, x: 1.05, y: 1.05),
            ];
            break;
          case 'diagonal_bl_tr':
            keyframes = [
              Keyframe(timeOffset: 0, x: -0.05, y: 1.05),
              Keyframe(timeOffset: endKeyframeTime, x: 1.05, y: -0.05),
            ];
            break;
        }
        
        if (keyframes.isNotEmpty) {
          track.overlays[index] = clip.copyWith(
            startTime: Duration.zero,
            endTime: _totalDuration,
            keyframes: keyframes,
            entranceAnimation: const ClipAnimation(),
            exitAnimation: const ClipAnimation(),
          );
        }
        break;
      }
    }
    syncToNative();
    notifyListeners();
  }
    
  void replaceOverlayAsset(String clipId, String newPath) {
    saveState();
    for (var track in _overlayTracks) {
      final index = track.overlays.indexWhere((c) => c.id == clipId);
      if (index != -1) {
        var clip = track.overlays[index];
        track.overlays[index] = clip.copyWith(imagePath: newPath);
        break;
      }
    }
    syncToNative();
    notifyListeners();
  }
}
