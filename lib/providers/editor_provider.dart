import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/editor_models.dart';
import '../services/native_bridge.dart';
import '../utils/subtitle_parser.dart';
import '../utils/animation_presets.dart';
import 'package:hive/hive.dart';

class HistoryState {
  final List<Track> tracks;
  final List<Track> overlayTracks;
  final double aspectRatio;
  final int backgroundColor;
  final String? backgroundImagePath;
  final double backgroundScale;
  final double backgroundRotation;
  final double backgroundX;
  final double backgroundY;
  final int backgroundFillMode;

  HistoryState({
    required this.tracks,
    required this.overlayTracks,
    required this.aspectRatio,
    required this.backgroundColor,
    this.backgroundImagePath,
    required this.backgroundScale,
    required this.backgroundRotation,
    required this.backgroundX,
    required this.backgroundY,
    required this.backgroundFillMode,
  });

  HistoryState clone() {
    return HistoryState(
      tracks: tracks.map((t) => t.copyWith(clips: t.clips.map((c) => c.copyWith()).toList())).toList(),
      overlayTracks: overlayTracks.map((t) => t.copyWith(overlays: t.overlays.map((c) => c.copyWith()).toList())).toList(),
      aspectRatio: aspectRatio,
      backgroundColor: backgroundColor,
      backgroundImagePath: backgroundImagePath,
      backgroundScale: backgroundScale,
      backgroundRotation: backgroundRotation,
      backgroundX: backgroundX,
      backgroundY: backgroundY,
      backgroundFillMode: backgroundFillMode,
    );
  }
}

class EditorProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final NativeBridge _bridge = NativeBridge();
  
  List<Track> _tracks = [];
  List<Track> _overlayTracks = [];
  Duration _currentTime = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isExporting = false;
  Set<String> _selectedClipIds = {};
  bool _isMultiSelectMode = false;
  double _zoomLevel = 1.0; // 1.0 = 50 pixels per second
  String? _audioPath;
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

  final List<HistoryState> _undoStack = [];
  final List<HistoryState> _redoStack = [];
  static const int _maxHistory = 50;

  List<Track> get tracks => _tracks;
  List<Track> get overlayTracks => _overlayTracks;
  Duration get currentTime => _currentTime;
  int get backgroundColor => _backgroundColor;
  String? get backgroundImagePath => _backgroundImagePath;
  double get backgroundScale => _backgroundScale;
  double get backgroundRotation => _backgroundRotation;
  double get backgroundX => _backgroundX;
  double get backgroundY => _backgroundY;
  int get backgroundFillMode => _backgroundFillMode;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _isPlaying;
  bool get isExporting => _isExporting;
  Set<String> get selectedClipIds => _selectedClipIds;
  bool get isMultiSelectMode => _isMultiSelectMode;
  bool get isAllSelected {
    final allIds = _tracks.expand((t) => t.clips).map((c) => c.id).toSet();
    final allOverlayIds = _overlayTracks.expand((t) => t.overlays).map((c) => c.id).toSet();
    final totalIds = allIds.length + allOverlayIds.length;
    return totalIds > 0 && _selectedClipIds.length == totalIds;
  }
  String? get selectedClipId => _selectedClipIds.isNotEmpty ? _selectedClipIds.first : null;
  double get zoomLevel => _zoomLevel;
  double get aspectRatio => _aspectRatio;
  bool get isTimelineCollapsed => _isTimelineCollapsed;
  bool get showTextTracks => _showTextTracks;
  bool get showOverlayTracks => _showOverlayTracks;

  void setZoomLevel(double level) {
    _zoomLevel = level.clamp(0.1, 10.0);
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

  void setBackgroundColor(int color) {
    saveState();
    _backgroundColor = color;
    _syncToNative();
    notifyListeners();
  }

  void setBackgroundImage(String? path) {
    saveState();
    _backgroundImagePath = path;
    _syncToNative();
    notifyListeners();
  }

  void setBackgroundScale(double scale) {
    _backgroundScale = scale;
    _syncToNative();
    notifyListeners();
  }

  void setBackgroundRotation(double rotation) {
    _backgroundRotation = rotation;
    _syncToNative();
    notifyListeners();
  }

  void setBackgroundX(double x) {
    _backgroundX = x;
    _syncToNative();
    notifyListeners();
  }

  void setBackgroundY(double y) {
    _backgroundY = y;
    _syncToNative();
    notifyListeners();
  }

  void setBackgroundFillMode(int mode) {
    saveState();
    _backgroundFillMode = mode;
    _syncToNative();
    notifyListeners();
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
      aspectRatio: _aspectRatio,
      backgroundColor: _backgroundColor,
      backgroundImagePath: _backgroundImagePath,
      backgroundScale: _backgroundScale,
      backgroundRotation: _backgroundRotation,
      backgroundX: _backgroundX,
      backgroundY: _backgroundY,
      backgroundFillMode: _backgroundFillMode,
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
    _aspectRatio = state.aspectRatio;
    _backgroundColor = state.backgroundColor;
    _backgroundImagePath = state.backgroundImagePath;
    _backgroundScale = state.backgroundScale;
    _backgroundRotation = state.backgroundRotation;
    _backgroundX = state.backgroundX;
    _backgroundY = state.backgroundY;
    _backgroundFillMode = state.backgroundFillMode;
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

  void selectClip(String? id) {
    if (id == null) {
      _selectedClipIds = {};
    } else {
      if (_isMultiSelectMode) {
        toggleClipSelection(id);
      } else {
        _selectedClipIds = {id};
        final clip = selectedTimelineClip;
        if (clip != null) {
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
    final allIds = _tracks.expand((t) => t.clips).map((c) => c.id).toSet();
    final allOverlayIds = _overlayTracks.expand((t) => t.overlays).map((c) => c.id).toSet();
    final totalIds = {...allIds, ...allOverlayIds};
    
    if (totalIds.isEmpty) return;

    if (_selectedClipIds.length == totalIds.length) {
      _selectedClipIds = {};
    } else {
      _selectedClipIds = totalIds;
    }
    notifyListeners();
  }

  void selectClipAt(double x, double y, {bool deselectIfEmpty = true}) {
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

    if (bestMatch != null) {
      selectClip(bestMatch.id);
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
    String? fontFamily,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    List<Keyframe>? keyframes,
    TextCase? textCase,
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
    String? fontFamily,
    ClipAnimation? entranceAnimation,
    ClipAnimation? exitAnimation,
    ClipAnimation? loopAnimation,
    double? textOpacity,
    List<Keyframe>? keyframes,
    TextCase? textCase,
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
            entranceAnimation: entranceAnimation,
            exitAnimation: exitAnimation,
            loopAnimation: loopAnimation,
            keyframes: updatedKeyframes,
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

    _bridge.updateClips([...allClips, ...allOverlays]);
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
        _audioPath = state['audioPath'];

        _tracks = (state['tracks'] as List? ?? []).map((t) => Track.fromJson(Map<String, dynamic>.from(t))).toList();
        _overlayTracks = (state['overlayTracks'] as List? ?? []).map((t) => Track.fromJson(Map<String, dynamic>.from(t))).toList();
        
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
        'audioPath': _audioPath,
        'tracks': _tracks.map((t) => t.toJson()).toList(),
        'overlayTracks': _overlayTracks.map((t) => t.toJson()).toList(),
      };
      box.put('project_state', state);
    } catch (e) {
      print("Error persisting project: $e");
    }
  }

  EditorProvider() {
    _init();
  }

  void _init() async {
    _audioPlayer.positionStream.listen((pos) {
      _currentTime = pos;
      _bridge.seekTo(pos.inMilliseconds);
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      _totalDuration = dur ?? Duration.zero;
      notifyListeners();
    });

    await _loadPersistedProject();
  }

  Future<void> loadAudio(String path) async {
    _audioPath = path;
    await _audioPlayer.setFilePath(path);
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
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void addClip(String text) {
    saveState();
    final startTime = _currentTime;
    final endTime = _currentTime + const Duration(seconds: 2);
    
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

  void addOverlay(String imagePath) {
    saveState();
    final newOverlay = OverlayClip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      startTime: _currentTime,
      endTime: _currentTime + const Duration(seconds: 1),
      originalTrackId: _overlayTracks.isNotEmpty ? _overlayTracks[0].id : 'overlay_main',
    );

    if (_overlayTracks.isEmpty) {
      _overlayTracks = [Track(id: 'overlay_main', name: 'Overlays', type: TrackType.overlay, overlays: [newOverlay])];
    } else {
      _overlayTracks[0].overlays.add(newOverlay);
    }
    
    _syncToNative();
    selectClip(newOverlay.id);
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
    } else {
      _overlayTracks.add(Track(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Overlay Track ${_overlayTracks.length + 1}',
        type: TrackType.overlay,
        overlays: [],
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
    final trackList = isOverlay ? _overlayTracks : _tracks;

    for (int i = 0; i < trackList.length; i++) {
        final List<TimelineClip> clipsOnTrack = isOverlay ? trackList[i].overlays : trackList[i].clips;
        final idx = clipsOnTrack.indexWhere((c) => c.id == clip.id);
        if (idx != -1) {
            currentTrackIdx = i;
            clipIdx = idx;
            break;
        }
    }
    
    if (currentTrackIdx != -1) {
        final TimelineClip foundClip = isOverlay 
           ? trackList[currentTrackIdx].overlays.removeAt(clipIdx) as TimelineClip
           : trackList[currentTrackIdx].clips.removeAt(clipIdx) as TimelineClip;
           
        final startTime = newStart ?? foundClip.startTime;
        final endTime = newEnd ?? foundClip.endTime;
        
        final updatedClip = isOverlay
            ? (foundClip as OverlayClip).copyWith(startTime: startTime, endTime: endTime)
            : (foundClip as SubtitleClip).copyWith(startTime: startTime, endTime: endTime);

        if (resolveCollisions) {
            _resolveCollisions(updatedClip, currentTrackIdx);
        } else {
            if (isOverlay) {
                trackList[currentTrackIdx].overlays.insert(clipIdx, updatedClip as OverlayClip);
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

    if (trackIdx != -1) {
      final clip = isOverlay 
          ? _overlayTracks[trackIdx].overlays.removeAt(clipIdx)
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

    const double gap = 0.08;
    final double totalHeight = (selectedClips.length - 1) * gap;
    final double startY = (1.0 - totalHeight) / 2;

    for (int i = 0; i < selectedClips.length; i++) {
        final clip = selectedClips[i];
        final updatedClip = clip.copyWith(
          endTime: maxEndTime,
          x: 0.5,
          y: startY + (i * gap),
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

    List<SubtitleClip> clipsToReset = [];
    for (var track in _tracks) {
      for (var clip in track.clips) {
        if (_selectedClipIds.contains(clip.id)) {
          clipsToReset.add(clip);
        }
      }
    }

    for (var track in _tracks) {
      track.clips.removeWhere((c) => _selectedClipIds.contains(c.id));
    }

    for (var clip in clipsToReset) {
      final resetClip = clip.copyWith(
        startTime: clip.originalStartTime,
        endTime: clip.originalEndTime,
      );

      String targetTrackId = clip.originalTrackId ?? 'main';
      int trackIdx = _tracks.indexWhere((t) => t.id == targetTrackId);
      
      if (trackIdx == -1) {
        trackIdx = 0;
        if (_tracks.isEmpty) {
          _tracks.add(Track(id: 'main', name: 'Main Track', clips: []));
        }
      }

      _resolveCollisions(resetClip, trackIdx);
    }

    _syncToNative();
    notifyListeners();
  }

  void _resolveCollisions(dynamic clip, int initialTrackIdx) {
    final bool isOverlay = clip is OverlayClip;
    final trackList = isOverlay ? _overlayTracks : _tracks;
    final trackType = isOverlay ? TrackType.overlay : TrackType.text;

    int targetTrackIdx = initialTrackIdx;
    bool hasCollision = true;

    while (hasCollision) {
        hasCollision = false;
        if (targetTrackIdx >= trackList.length) {
            addNewTrack(trackType);
        }

        final track = trackList[targetTrackIdx];
        final List<TimelineClip> clipsToCompare = isOverlay ? track.overlays : track.clips;
        
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
    final trackList = isOverlayMove ? _overlayTracks : _tracks;

    final Map<String, int> clipToCurrentTrackIndex = {};
    for (int i = 0; i < trackList.length; i++) {
      final List<TimelineClip> clipsOnTrack = isOverlayMove ? trackList[i].overlays : trackList[i].clips;
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
        final List<TimelineClip> clipsOnTrack = isOverlayMove ? track.overlays : track.clips;
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
        addNewTrack(isOverlayMove ? TrackType.overlay : TrackType.text);
      }

      final startTime = c.startTime + timeOffset;
      final duration = c.endTime - c.startTime;
      final updatedClip = isOverlayMove 
          ? (c as OverlayClip).copyWith(startTime: startTime, endTime: startTime + duration)
          : (c as SubtitleClip).copyWith(startTime: startTime, endTime: startTime + duration);

      _resolveCollisions(updatedClip, newTrackIdx);
    }

    _syncToNative();
    notifyListeners();
  }

  void seek(Duration pos) {
    _audioPlayer.seek(pos);
  }

  Future<String?> exportVideo() async {
    if (_tracks.isEmpty) return null;
    
    _isExporting = true;
    notifyListeners();

    try {
      final allClips = [
        ..._tracks.expand((t) => t.clips).map((c) {
          final map = c.toJson();
          map['isText'] = true;
          return map;
        }),
        ..._overlayTracks.expand((t) => t.overlays).map((c) {
          final map = c.toJson();
          map['isText'] = false;
          map['imagePath'] = c.imagePath;
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
        durationMs: _totalDuration.inMilliseconds,
        clips: allClips,
        audioPath: _audioPath,
        backgroundColor: _backgroundColor,
        backgroundImagePath: _backgroundImagePath,
        bgScale: _backgroundScale,
        bgRotation: _backgroundRotation,
        bgX: _backgroundX,
        bgY: _backgroundY,
        bgFillMode: _backgroundFillMode,
      );
      
      return result;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
