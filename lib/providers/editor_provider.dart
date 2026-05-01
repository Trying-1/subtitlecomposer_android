import 'dart:io';
import 'dart:convert';
import 'dart:async';
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

class HistoryState {
  final List<Track> tracks;
  final List<Track> overlayTracks;
  final List<Track> backgroundTracks;
  final double aspectRatio;
  final int backgroundColor;
  final String? backgroundImagePath;
  final double backgroundScale;
  final double backgroundRotation;
  final double backgroundX;
  final double backgroundY;
  final int backgroundFillMode;
  final List<Duration> markers;

  HistoryState({
    required this.tracks,
    required this.overlayTracks,
    required this.backgroundTracks,
    required this.aspectRatio,
    required this.backgroundColor,
    this.backgroundImagePath,
    required this.backgroundScale,
    required this.backgroundRotation,
    required this.backgroundX,
    required this.backgroundY,
    required this.backgroundFillMode,
    required this.markers,
  });

  HistoryState clone() {
    return HistoryState(
      tracks: tracks.map((t) => t.copyWith(clips: t.clips.map((c) => c.copyWith()).toList())).toList(),
      overlayTracks: overlayTracks.map((t) => t.copyWith(overlays: t.overlays.map((c) => c.copyWith()).toList())).toList(),
      backgroundTracks: backgroundTracks.map((t) => t.copyWith(backgrounds: t.backgrounds.map((c) => c.copyWith()).toList())).toList(),
      aspectRatio: aspectRatio,
      backgroundColor: backgroundColor,
      backgroundImagePath: backgroundImagePath,
      backgroundScale: backgroundScale,
      backgroundRotation: backgroundRotation,
      backgroundX: backgroundX,
      backgroundY: backgroundY,
      backgroundFillMode: backgroundFillMode,
      markers: List.from(markers),
    );
  }
}

class EditorProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final NativeBridge _bridge = NativeBridge();
  final ForceAlignService _alignService = ForceAlignService();
  Timer? _playbackTimer;
  DateTime? _lastTick;
  final Map<String, AudioPlayer> _audioClipPlayers = {};

  EditorProvider() {
    _initAudioListeners();
    _init();
  }

  void _initAudioListeners() {
    _audioPlayer.positionStream.listen((pos) {
      // Main audio position is now synced via the master timer in _startPlayback
      // We only listen here for informational purposes or background sync
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (_audioPath != null) {
        // We no longer sync _isPlaying directly to the main player state
        // because the master timer controls the project playback state.
        if (state.processingState == ProcessingState.completed) {
          // Main audio finished, but we let the master timer continue 
          // if there are more clips later in the timeline.
          _audioPlayer.pause();
        }
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      if (_audioPath != null) {
        _totalDuration = dur ?? Duration.zero;
        notifyListeners();
      }
    });
  }
  
  List<Track> _tracks = [];
  List<Track> _overlayTracks = [];
  List<Track> _backgroundTracks = [];
  List<Track> _audioTracks = [];
  Duration _currentTime = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isExporting = false;
  Set<String> _selectedClipIds = {};
  bool _isMultiSelectMode = false;
  double _zoomLevel = 1.0; // 1.0 = 50 pixels per second
  String? _audioPath;
  String? get audioPath => _audioPath;
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
  bool _isImportingModel = false;
  final List<Duration> _markers = [];
  bool _isCollisionAdjustEnabled = false;
  bool _isPlayheadLocked = false;
  
  final ValueNotifier<Duration> playbackTime = ValueNotifier(Duration.zero);

  final List<HistoryState> _undoStack = [];
  final List<HistoryState> _redoStack = [];
  static const int _maxHistory = 50;

  List<Track> get tracks => _tracks;
  List<Track> get overlayTracks => _overlayTracks;
  List<Track> get backgroundTracks => _backgroundTracks;
  List<Track> get audioTracks => _audioTracks;
  Duration get currentTime => _currentTime;
  int get backgroundColor => selectedBackground?.color ?? _backgroundColor;
  String? get backgroundImagePath => selectedBackground?.imagePath ?? _backgroundImagePath;
  double get backgroundScale => selectedBackground?.scale ?? _backgroundScale;
  double get backgroundRotation => selectedBackground?.rotation ?? _backgroundRotation;
  double get backgroundX => selectedBackground?.x ?? _backgroundX;
  double get backgroundY => selectedBackground?.y ?? _backgroundY;
  int get backgroundFillMode => selectedBackground?.fillMode ?? _backgroundFillMode;

  Duration _clampTime(Duration time) {
    if (time < Duration.zero) return Duration.zero;
    final total = totalDuration;
    if (time > total) return total;
    return time;
  }
  Duration get totalDuration {
    // If we have a main audio, that defines the project boundaries strictly
    if (_audioPath != null) return _totalDuration;
    
    // Otherwise, fallback to dynamic duration based on clips
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
  bool get isImportingModel => _isImportingModel;
  
  void togglePlayheadLock() {
    _isPlayheadLocked = !_isPlayheadLocked;
    if (_isPlayheadLocked && _isPlaying) {
      togglePlay();
    }
    notifyListeners();
  }
  bool get isAllSelected {
    final allIds = _tracks.expand((t) => t.clips).map((c) => c.id).toSet();
    final allOverlayIds = _overlayTracks.expand((t) => t.overlays).map((c) => c.id).toSet();
    final allBackgroundIds = _backgroundTracks.expand((t) => t.backgrounds).map((c) => c.id).toSet();
    final totalIds = allIds.length + allOverlayIds.length + allBackgroundIds.length;
    return totalIds > 0 && _selectedClipIds.length == totalIds;
  }
  String? get selectedClipId => _selectedClipIds.isNotEmpty ? _selectedClipIds.first : null;
  double get zoomLevel => _zoomLevel;
  double get aspectRatio => _aspectRatio;
  bool get isTimelineCollapsed => _isTimelineCollapsed;
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
    _syncToNative();
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
      _syncToNative();
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
      _syncToNative();
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
      _syncToNative();
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
      _syncToNative();
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
      _syncToNative();
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
      _syncToNative();
      notifyListeners();
    }
  }

  void updateProjectSync({int? width, int? height}) {
    _bridge.updateProjectSettings(
      aspectRatio: _aspectRatio,
      backgroundColor: _backgroundColor, 
      backgroundImagePath: _backgroundImagePath, 
      bgScale: _backgroundScale,
      bgRotation: _backgroundRotation,
      bgX: _backgroundX,
      bgY: _backgroundY,
      bgFillMode: _backgroundFillMode,
      width: width,
      height: height,
    );
  }

  void saveState() {
    _undoStack.add(_captureState());
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    notifyListeners();
  }

  HistoryState _captureState() {
    return HistoryState(
      tracks: _tracks.map((t) => t.copyWith(clips: t.clips.map((c) => c.copyWith()).toList())).toList(),
      overlayTracks: _overlayTracks.map((t) => t.copyWith(overlays: t.overlays.map((c) => c.copyWith()).toList())).toList(),
      backgroundTracks: _backgroundTracks.map((t) => t.copyWith(backgrounds: t.backgrounds.map((c) => c.copyWith()).toList())).toList(),
      aspectRatio: _aspectRatio,
      backgroundColor: _backgroundColor,
      backgroundImagePath: _backgroundImagePath,
      backgroundScale: _backgroundScale,
      backgroundRotation: _backgroundRotation,
      backgroundX: _backgroundX,
      backgroundY: _backgroundY,
      backgroundFillMode: _backgroundFillMode,
      markers: List.from(_markers),
    );
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    final currentState = _captureState();
    _redoStack.add(currentState);

    final prevState = _undoStack.removeLast();
    _applyState(prevState);
    
    _syncToNative();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    final currentState = _captureState();
    _undoStack.add(currentState);

    final nextState = _redoStack.removeLast();
    _applyState(nextState);

    _syncToNative();
    notifyListeners();
  }

  void _applyState(HistoryState state) {
    _tracks = state.tracks;
    _overlayTracks = state.overlayTracks;
    _backgroundTracks = state.backgroundTracks;
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
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    if (!_isMultiSelectMode && _selectedClipIds.length > 1) {
      // Opt-in: Keep only the first one when turning off multi-select? 
    }
    notifyListeners();
  }

  TimelineClip? get selectedTimelineClip {
    if (_selectedClipIds.isEmpty) return null;
    try {
      final firstId = _selectedClipIds.first;
      // Search in text tracks
      for (var track in _tracks) {
        for (var clip in track.clips) {
          if (clip.id == firstId) return clip;
        }
      }
      // Search in overlay tracks
      for (var track in _overlayTracks) {
        for (var clip in track.overlays) {
          if (clip.id == firstId) return clip;
        }
      }
      // Search in background tracks
      for (var track in _backgroundTracks) {
        for (var clip in track.backgrounds) {
          if (clip.id == firstId) return clip;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
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

  void selectClip(String? id, {bool toggle = true}) {
    if (id == null) {
      _selectedClipIds = {};
    } else {
      if (_isMultiSelectMode && toggle) {
        toggleClipSelection(id);
      } else {
        if (!_isMultiSelectMode || !_selectedClipIds.contains(id)) {
          _selectedClipIds = _isMultiSelectMode ? (Set.from(_selectedClipIds)..add(id)) : {id};
        }
        final clip = selectedTimelineClip;
        if (clip != null && !_isPlayheadLocked) {
          final center = Duration(
            milliseconds: (clip.startTime.inMilliseconds + clip.endTime.inMilliseconds) ~/ 2,
          );
          seek(center);
        }
      }
    }
    notifyListeners();
  }

  void toggleClipSelection(String id) {
    if (_selectedClipIds.contains(id)) {
      _selectedClipIds.remove(id);
    } else {
      _selectedClipIds.add(id);
    }
    notifyListeners();
  }

  void selectClips(Iterable<String> ids) {
    _selectedClipIds = Set.from(ids);
    notifyListeners();
  }

  void toggleSelectAll() {
    final allTextIds = _tracks.expand((t) => t.clips).map((c) => c.id).toSet();
    
    if (allTextIds.isEmpty) return;

    // Check if all text clips are currently selected
    bool areAllTextSelected = _selectedClipIds.containsAll(allTextIds);

    if (areAllTextSelected) {
      // If all text clips are selected, deselect them
      _selectedClipIds = _selectedClipIds.where((id) => !allTextIds.contains(id)).toSet();
    } else {
      // If not all text clips are selected, select all of them (keeping other types like audio selected if they were)
      _selectedClipIds = {..._selectedClipIds, ...allTextIds};
    }
    notifyListeners();
  }

  void selectClipAt(double x, double y, {bool deselectIfEmpty = true, bool toggle = true}) {
    TimelineClip? bestMatch;
    int highestTrack = -1;
    double closestDistSq = 1.0;

    // Search in text tracks
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

    // Search in overlay tracks (overlays are usually on top of text)
    for (int i = 0; i < _overlayTracks.length; i++) {
      for (var clip in _overlayTracks[i].overlays) {
        if (_currentTime >= clip.startTime && _currentTime < clip.endTime) {
          final dx = clip.x - x;
          final dy = clip.y - y;
          final distSq = dx * dx + dy * dy;
          final threshold = 0.1 * clip.scale; // Overlays use base scale for threshold
          if (distSq < threshold * threshold) {
            // Overlays always win over text if they overlap at same depth, but here we just check track index
            // Overlay index start from top of text
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

    // Search in background tracks - DISABLED for preview window selection
    // Users should select backgrounds from the timeline to avoid accidental drags
    /*
    for (int i = 0; i < _backgroundTracks.length; i++) {
      for (var clip in _backgroundTracks[i].backgrounds) {
        if (_currentTime >= clip.startTime && _currentTime < clip.endTime) {
          if (bestMatch == null) {
              bestMatch = clip;
          }
        }
      }
    }
    */

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
  void moveClips(Iterable<String> ids, double dx, double dy) {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();

    // Text tracks
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

    // Overlay tracks
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

    _syncToNative();
    notifyListeners();
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
  }) {
    final idSet = ids.toSet();
    final isPropertyUpdate = x != null || y != null || scale != null || rotation != null || opacity != null;
    
    // Update text tracks
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
            blendMode: blendMode,
            fontFamily: fontFamily,
            entranceAnimation: entranceAnimation,
            exitAnimation: exitAnimation,
            loopAnimation: loopAnimation,
            keyframes: updatedKeyframes,
          );
        }
      }
    }

    // Update overlay tracks
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
            keyframes: updatedKeyframes,
          );
        }
      }
    }
    
    // Update background tracks
    for (var track in _backgroundTracks) {
      for (int i = 0; i < track.backgrounds.length; i++) {
        final clip = track.backgrounds[i];
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

          track.backgrounds[i] = clip.copyWith(
            x: x,
            y: y,
            rotation: rotation,
            scale: scale,
            opacity: opacity,
            color: color,
            imagePath: imagePath,
            fillMode: fillMode,
            entranceAnimation: entranceAnimation,
            exitAnimation: exitAnimation,
            loopAnimation: loopAnimation,
            keyframes: updatedKeyframes,
          );
        }
      }
    }

    // Update audio tracks
    for (var track in _audioTracks) {
      for (int i = 0; i < track.audioClips.length; i++) {
        final clip = track.audioClips[i];
        if (idSet.contains(clip.id)) {
          track.audioClips[i] = clip.copyWith(
            volume: volume,
          );
        }
      }
    }
    
    _syncToNative();
    notifyListeners();
  }

  void applyPreset(String clipId, AnimationPreset preset) {
    updateClip(
      clipId,
      entranceAnimation: preset.entrance,
      exitAnimation: preset.exit,
    );
  }

  void _syncToNative() {
    final allClips = _tracks.expand((t) => t.clips).map((c) {
      final map = c.toJson();
      map['isText'] = true;
      return map;
    }).toList();

    final allOverlays = _overlayTracks.expand((t) => t.overlays).map((c) {
      final map = c.toJson();
      map['isText'] = false;
      map['imagePath'] = c.imagePath;
      return map;
    }).toList();

    final allBackgrounds = _backgroundTracks.expand((t) => t.backgrounds).map((c) {
      final map = c.toJson();
      map['isBackground'] = true;
      map['isText'] = false; // Background clips are not text
      return map;
    }).toList();

    _bridge.updateClips([...allBackgrounds, ...allOverlays, ...allClips]);
    _bridge.updateProjectSettings(
      aspectRatio: _aspectRatio,
      backgroundColor: backgroundColor,
      backgroundImagePath: backgroundImagePath,
      bgScale: backgroundScale,
      bgRotation: backgroundRotation,
      bgX: backgroundX,
      bgY: backgroundY,
      bgFillMode: backgroundFillMode,
    );
    _persistProject();
  }

  Future<void> _loadPersistedProject() async {
    try {
      final box = Hive.box('project_box');
      final data = box.get('project_state');
      if (data != null) {
        final Map<String, dynamic> state = Map<String, dynamic>.from(data);
        
        _aspectRatio = state['aspectRatio'] ?? 16 / 9;
        _backgroundColor = state['backgroundColor'] ?? 0xFF000000;
        _backgroundImagePath = state['backgroundImagePath'];
        _backgroundScale = (state['backgroundScale'] as num?)?.toDouble() ?? 1.0;
        _backgroundRotation = (state['backgroundRotation'] as num?)?.toDouble() ?? 0.0;
        _backgroundX = (state['backgroundX'] as num?)?.toDouble() ?? 0.0;
        _backgroundY = (state['backgroundY'] as num?)?.toDouble() ?? 0.0;
        _backgroundFillMode = state['backgroundFillMode'] ?? 0;
        _whisperModelPath = state['whisperModelPath'];
        _audioPath = state['audioPath'];

        _tracks = (state['tracks'] as List? ?? []).map((t) => Track.fromJson(Map<String, dynamic>.from(t))).toList();
        _overlayTracks = (state['overlayTracks'] as List? ?? []).map((t) => Track.fromJson(Map<String, dynamic>.from(t))).toList();
        _backgroundTracks = (state['backgroundTracks'] as List? ?? []).map((t) => Track.fromJson(Map<String, dynamic>.from(t))).toList();
        
        if (_audioPath != null) {
          try {
             await _audioPlayer.setFilePath(_audioPath!);
             _totalDuration = _audioPlayer.duration ?? Duration.zero;
          } catch(e) {
            print("Error loading persisted audio: $e");
          }
        }
      }
    } catch (e) {
      print("Error loading project: $e");
    } finally {
      _isInitialized = true;
      _syncToNative();
      notifyListeners();
    }
  }

  void _persistProject() {
    if (!_isInitialized) return;
    try {
      final box = Hive.box('project_box');
      final state = {
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
        'tracks': _tracks.map((t) => t.toJson()).toList(),
        'overlayTracks': _overlayTracks.map((t) => t.toJson()).toList(),
        'backgroundTracks': _backgroundTracks.map((t) => t.toJson()).toList(),
      };
      box.put('project_state', state);
    } catch (e) {
      print("Error persisting project: $e");
    }
  }

  void _init() async {
    await _loadPersistedProject();
  }

  Future<void> loadAudio(String path) async {
    _audioPath = path;
    await _audioPlayer.setFilePath(path);
    
    // Add to timeline as main audio segment
    final durationMs = await _bridge.getVideoDuration(path);
    final duration = Duration(milliseconds: durationMs);
    
    // Remove existing main audio clips if any
    for (var track in _audioTracks) {
      track.audioClips.removeWhere((c) => c.isMainAudio);
    }
    
    final mainClip = AudioClip(
      id: 'main_audio_${DateTime.now().millisecondsSinceEpoch}',
      audioPath: path,
      startTime: Duration.zero,
      endTime: duration,
      isMainAudio: true,
      sourceDurationMs: durationMs,
    );
    
    if (_audioTracks.isEmpty) {
      _audioTracks.add(Track(id: 'audio_track_0', name: 'Audio 1', type: TrackType.audio, audioClips: []));
    }
    _audioTracks[0].audioClips.insert(0, mainClip);
    
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
    
    _selectedClipIds = {};
    _syncToNative();
    notifyListeners();
  }

  void splitClip(String id) {
    saveState();
    TimelineClip? clip;
    int trackIdx = -1;
    bool isOverlay = false;
    
    for (int i = 0; i < _tracks.length; i++) {
      final idx = _tracks[i].clips.indexWhere((c) => c.id == id);
      if (idx != -1) {
        clip = _tracks[i].clips[idx];
        trackIdx = i;
        break;
      }
    }
    
    if (clip == null) {
      for (int i = 0; i < _overlayTracks.length; i++) {
        final idx = _overlayTracks[i].overlays.indexWhere((c) => c.id == id);
        if (idx != -1) {
          clip = _overlayTracks[i].overlays[idx];
          trackIdx = i;
          isOverlay = true;
          break;
        }
      }
    }

    bool isBackground = false;
    if (clip == null) {
      for (int i = 0; i < _backgroundTracks.length; i++) {
        final idx = _backgroundTracks[i].backgrounds.indexWhere((c) => c.id == id);
        if (idx != -1) {
          clip = _backgroundTracks[i].backgrounds[idx];
          trackIdx = i;
          isBackground = true;
          break;
        }
      }
    }
    
    if (clip == null) return;
    
    // Playhead must be inside the clip and not at the very edges
    if (_currentTime <= clip.startTime || _currentTime >= clip.endTime) return;
    
    final oldEndTime = clip.endTime;
    final splitTime = _currentTime;
    
    if (isOverlay) {
      final oldClip = clip as OverlayClip;
      final newClip = oldClip.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: splitTime,
        endTime: oldEndTime,
      );
      
      final list = _overlayTracks[trackIdx].overlays;
      final idx = list.indexWhere((c) => c.id == id);
      list[idx] = oldClip.copyWith(endTime: splitTime);
      list.insert(idx + 1, newClip);
    } else if (isBackground) {
      final oldClip = clip as BackgroundClip;
      final newClip = oldClip.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: splitTime,
        endTime: oldEndTime,
      );
      
      final list = _backgroundTracks[trackIdx].backgrounds;
      final idx = list.indexWhere((c) => c.id == id);
      list[idx] = oldClip.copyWith(endTime: splitTime);
      list.insert(idx + 1, newClip);
    } else {
      final oldClip = clip as SubtitleClip;
      final newClip = oldClip.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: splitTime,
        endTime: oldEndTime,
      );
      
      final list = _tracks[trackIdx].clips;
      final idx = list.indexWhere((c) => c.id == id);
      list[idx] = oldClip.copyWith(endTime: splitTime);
      list.insert(idx + 1, newClip);
    }
    
    _syncToNative();
    notifyListeners();
  }

  void resetProject() {
    _tracks = [];
    _overlayTracks = [];
    _backgroundTracks = [];
    _audioPath = null;
    _currentTime = Duration.zero;
    _totalDuration = Duration.zero;
    _selectedClipIds = {};
    
    // Reset background and aspect ratio
    _aspectRatio = 16 / 9;
    _backgroundColor = 0xFFFFFFFF;
    _backgroundImagePath = null;
    _backgroundScale = 1.0;
    _backgroundRotation = 0.0;
    _backgroundX = 0.0;
    _backgroundY = 0.0;
    _backgroundFillMode = 0;

    _audioPlayer.stop();
    
    _syncToNative();
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
    
    // Sync to native
    await _bridge.updateClips(clips.map((c) => c.toJson()).toList());
    notifyListeners();
  }

  Future<void> importPlainText(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    await generateSubtitlesFromText(content);
  }

  Future<void> generateSubtitlesFromText(String content) async {
    saveState();
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    final List<SubtitleClip> clips = [];
    Duration currentStart = Duration.zero;
    const duration = Duration(milliseconds: 500);

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
    
    // Update total duration if needed
    if (currentStart > _totalDuration) {
      _totalDuration = currentStart;
    }

    _syncToNative();
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
    _stopPlayback();
    _isPlaying = true;
    _lastTick = DateTime.now();

    if (_currentTime >= totalDuration) {
      _currentTime = Duration.zero;
    }

    // Start main audio if present
    if (_audioPath != null) {
      _audioPlayer.seek(_currentTime);
      _audioPlayer.play();
    }

    _bridge.setPlaying(true);

    int tickCount = 0;
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final diff = now.difference(_lastTick!);
      _lastTick = now;

      _currentTime += diff;
      tickCount++;
      
      final duration = totalDuration;
      if (_currentTime >= duration) {
        _currentTime = duration;
        _stopPlayback();
        return;
      }

      // Sync Main Audio less frequently
      if (_audioPath != null && tickCount % 3 == 0) {
        // If the playhead is beyond main audio duration, pause it
        if (_currentTime >= _totalDuration) {
          if (_audioPlayer.playing) _audioPlayer.pause();
        } else {
          // Subtle sync to keep it aligned with master clock
          final mainPos = _audioPlayer.position;
          final syncDiff = (mainPos.inMilliseconds - _currentTime.inMilliseconds).abs();
          if (syncDiff > 250) {
            _audioPlayer.seek(_currentTime);
          }
          if (!_audioPlayer.playing) _audioPlayer.play();
        }
      }

      if (tickCount % 4 == 0) {
        _syncAudioClipPlayers();
      }
      
      playbackTime.value = _currentTime;
    });
    
    _resumeAllAudioClips();
    notifyListeners();
  }

  void _stopPlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _bridge.setPlaying(false);
    _bridge.seekTo(_currentTime.inMilliseconds); // Final sync
    playbackTime.value = _currentTime;
    
    if (_audioPath != null) {
      _audioPlayer.pause();
    }
    
    _pauseAllAudioClips();
    notifyListeners();
  }

  void _pauseAllAudioClips() {
    for (var player in _audioClipPlayers.values) {
      player.pause();
    }
  }

  void _resumeAllAudioClips() {
    _syncAudioClipPlayers();
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
    
    _syncToNative();
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
    selectClip(newOverlay.id);
  }

  Future<void> addBackgroundClip({String? imagePath, int color = 0xFFFFFFFF}) async {
    saveState();
    int duration = 0;
    if (imagePath != null) {
      duration = await _bridge.getVideoDuration(imagePath);
    }
    
    final newClip = BackgroundClip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      color: color,
      startTime: _currentTime,
      endTime: _currentTime + const Duration(seconds: 5),
      sourceDurationMs: duration,
      originalTrackId: _backgroundTracks.isNotEmpty ? _backgroundTracks[0].id : 'bg_main',
    );

    if (_backgroundTracks.isEmpty) {
      _backgroundTracks = [Track(id: 'bg_main', name: 'Backgrounds', type: TrackType.background, backgrounds: [])];
    }
    
    _resolveCollisions(newClip, 0);
    selectClip(newClip.id);
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
    
    _syncToNative();
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
    
    // Select the first word of the split
    _selectedClipIds = {newClips[0].id};
    
    _syncToNative();
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
    } else {
      _backgroundTracks.add(Track(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Background Track ${_backgroundTracks.length + 1}',
        type: TrackType.background,
        backgrounds: [],
      ));
    }
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
    
    final trackList = isOverlay ? _overlayTracks : (isBackground ? _backgroundTracks : _tracks);

    for (int i = 0; i < trackList.length; i++) {
        final List<TimelineClip> clipsOnTrack;
        if (isOverlay) {
          clipsOnTrack = trackList[i].overlays;
        } else if (isBackground) {
          clipsOnTrack = trackList[i].backgrounds;
        } else if (clip is AudioClip) {
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
        } else if (clip is AudioClip) {
          foundClip = trackList[currentTrackIdx].audioClips.removeAt(clipIdx);
        } else {
          foundClip = trackList[currentTrackIdx].clips.removeAt(clipIdx);
        }
           
        final startTime = _clampTime(newStart ?? foundClip.startTime);
        final endTime = _clampTime(newEnd ?? foundClip.endTime);
        
        final TimelineClip updatedClip;
        if (isOverlay) {
          updatedClip = (foundClip as OverlayClip).copyWith(startTime: startTime, endTime: endTime);
        } else if (isBackground) {
          updatedClip = (foundClip as BackgroundClip).copyWith(startTime: startTime, endTime: endTime);
        } else if (foundClip is AudioClip) {
          updatedClip = (foundClip as AudioClip).copyWith(startTime: startTime, endTime: endTime);
        } else {
          updatedClip = (foundClip as SubtitleClip).copyWith(startTime: startTime, endTime: endTime);
        }

        if (_isCollisionAdjustEnabled) {
          _handleCollisionPush(trackList[currentTrackIdx], updatedClip);
        }

        if (resolveCollisions) {
            _resolveCollisions(updatedClip, currentTrackIdx);
        } else {
            if (isOverlay) {
                trackList[currentTrackIdx].overlays.insert(clipIdx, updatedClip as OverlayClip);
            } else if (isBackground) {
                trackList[currentTrackIdx].backgrounds.insert(clipIdx, updatedClip as BackgroundClip);
            } else if (updatedClip is AudioClip) {
                trackList[currentTrackIdx].audioClips.insert(clipIdx, updatedClip as AudioClip);
            } else {
                trackList[currentTrackIdx].clips.insert(clipIdx, updatedClip as SubtitleClip);
            }
            _syncToNative();
            notifyListeners();
        }
    }
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
    
    _syncToNative();
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

    _syncToNative();
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
    _syncToNative();
    notifyListeners();
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

    _syncToNative();
    notifyListeners();
  }

  void seek(Duration pos) {
    if (_isPlayheadLocked) return;
    _currentTime = pos;
    if (_audioPath != null) {
      _audioPlayer.seek(pos);
    }
    
    // Always sync audio clips regardless of main audio
    _syncAudioClipPlayers(forceSeek: true);
    
    _bridge.seekTo(pos.inMilliseconds);
    _lastTick = DateTime.now();
    notifyListeners();
  }

  void _syncAudioClipPlayers({bool forceSeek = false}) {
    for (var track in _audioTracks) {
      for (var clip in track.audioClips) {
        // Skip main audio clip since it's handled by _audioPlayer directly
        if (clip.isMainAudio) continue;
        
        final player = _getOrCreatePlayerForClip(clip);
        if (_currentTime >= clip.startTime && _currentTime < clip.endTime) {
          final targetOffset = _currentTime - clip.startTime;
          
          if (forceSeek) {
             player.seek(targetOffset);
          } else if (!_isPlaying) {
             // If not playing, we can afford to sync more precisely when the playhead moves
             final currentPos = player.position;
             final diff = (currentPos.inMilliseconds - targetOffset.inMilliseconds).abs();
             if (diff > 100) player.seek(targetOffset);
          }
          
          if (_isPlaying) {
            if (!player.playing) {
              player.setVolume(clip.volume);
              player.seek(targetOffset); // Initial sync when starting
              player.play();
            }
          }
        } else {
          if (player.playing) player.pause();
        }
      }
    }
  }

  AudioPlayer _getOrCreatePlayerForClip(AudioClip clip) {
    if (!_audioClipPlayers.containsKey(clip.id)) {
      final player = AudioPlayer();
      player.setFilePath(clip.audioPath).catchError((e) {
        print("Error loading audio clip: $e");
      });
      player.setVolume(clip.volume);
      _audioClipPlayers[clip.id] = player;
    }
    return _audioClipPlayers[clip.id]!;
  }

  void play() {
    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
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
      
      final int w, h;
      if (_aspectRatio > 1.2) {
        w = 1920; h = 1080;
      } else if (_aspectRatio < 0.8) {
        w = 1080; h = 1920;
      } else {
        w = 1080; h = 1080;
      }

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

  Future<void> addAudioClip(String path) async {
    saveState();
    final id = 'audio_${DateTime.now().millisecondsSinceEpoch}';
    
    // Get actual duration from file using native bridge
    final durationMs = await _bridge.getVideoDuration(path);
    final duration = durationMs > 0 ? Duration(milliseconds: durationMs) : const Duration(seconds: 5);
    
    final clip = AudioClip(
      id: id,
      audioPath: path,
      startTime: _clampTime(_currentTime),
      endTime: _clampTime(_currentTime + duration),
      sourceDurationMs: durationMs,
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
    notifyListeners();
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
      _syncToNative();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
      _persistProject();
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
}
