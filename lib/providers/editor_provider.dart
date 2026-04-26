import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/editor_models.dart';
import '../services/native_bridge.dart';
import '../utils/subtitle_parser.dart';
import '../utils/animation_presets.dart';

class EditorProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final NativeBridge _bridge = NativeBridge();
  
  List<Track> _tracks = [];
  Duration _currentTime = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isExporting = false;
  Set<String> _selectedClipIds = {};
  bool _isMultiSelectMode = false;
  double _zoomLevel = 1.0; // 1.0 = 50 pixels per second
  String? _audioPath;
  double _aspectRatio = 16 / 9;
  int _backgroundColor = 0xFF000000;
  String? _backgroundImagePath;
  double _backgroundScale = 1.0;
  double _backgroundRotation = 0.0;
  double _backgroundX = 0.0;
  double _backgroundY = 0.0;
  int _backgroundFillMode = 0; // 0: cover, 1: fit, 2: center
  bool _isTimelineCollapsed = false;

  List<Track> get tracks => _tracks;
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
    return allIds.isNotEmpty && _selectedClipIds.length == allIds.length;
  }
  String? get selectedClipId => _selectedClipIds.isNotEmpty ? _selectedClipIds.first : null;
  double get zoomLevel => _zoomLevel;
  double get aspectRatio => _aspectRatio;
  bool get isTimelineCollapsed => _isTimelineCollapsed;

  void setZoomLevel(double level) {
    _zoomLevel = level.clamp(0.1, 10.0);
    notifyListeners();
  }

  void toggleTimelineCollapse() {
    _isTimelineCollapsed = !_isTimelineCollapsed;
    notifyListeners();
  }

  void setAspectRatio(double ratio) {
    _aspectRatio = ratio;
    _syncToNative();
    notifyListeners();
  }

  void setBackgroundColor(int color) {
    _backgroundColor = color;
    _syncToNative();
    notifyListeners();
  }

  void setBackgroundImage(String? path) {
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

  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    if (!_isMultiSelectMode && _selectedClipIds.length > 1) {
      // Opt-in: Keep only the first one when turning off multi-select? 
      // Or just keep them. Let's keep them but next tap will clear.
    }
    notifyListeners();
  }

  SubtitleClip? get selectedClip {
    if (_selectedClipIds.isEmpty) return null;
    try {
      final firstId = _selectedClipIds.first;
      return _tracks.expand((t) => t.clips).firstWhere((c) => c.id == firstId);
    } catch (_) {
      return null;
    }
  }

  void selectClip(String? id) {
    if (id == null) {
      _selectedClipIds = {};
    } else {
      if (_isMultiSelectMode) {
        toggleClipSelection(id);
      } else {
        _selectedClipIds = {id};
        final clip = selectedClip;
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
    if (allIds.isEmpty) return;

    if (_selectedClipIds.length == allIds.length) {
      _selectedClipIds = {};
    } else {
      _selectedClipIds = allIds;
    }
    notifyListeners();
  }

  void selectClipAt(double x, double y, {bool deselectIfEmpty = true}) {
    SubtitleClip? bestMatch;
    int highestTrack = -1;
    double closestDistSq = 1.0;

    for (int i = 0; i < _tracks.length; i++) {
      for (var clip in _tracks[i].clips) {
        if (_currentTime >= clip.startTime && _currentTime < clip.endTime) {
          final dx = clip.x - x;
          final dy = clip.y - y;
          final distSq = dx * dx + dy * dy;
          
          // Dynamic threshold based on font size (approximate)
          final threshold = 0.05 + (clip.fontSize / 1000) * clip.scale; 

          if (distSq < threshold * threshold) {
            // Prioritize higher track index (layered on top)
            if (i >= highestTrack) {
              if (i > highestTrack || distSq < closestDistSq) {
                highestTrack = i;
                bestMatch = clip;
                closestDistSq = distSq;
              }
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
    );
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
  }) {
    final idSet = ids.toSet();
    for (var track in _tracks) {
      for (int i = 0; i < track.clips.length; i++) {
        final clip = track.clips[i];
        if (idSet.contains(clip.id)) {
          track.clips[i] = clip.copyWith(
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
    final allClips = _tracks.expand((t) => t.clips).map((c) => c.toJson()).toList();
    _bridge.updateClips(allClips);
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
  }

  EditorProvider() {
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
  }

  Future<void> loadAudio(String path) async {
    _audioPath = path;
    await _audioPlayer.setFilePath(path);
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

  void togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void addClip(String text) {
    final newClip = SubtitleClip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      startTime: _currentTime,
      endTime: _currentTime + const Duration(seconds: 2),
      y: 0.5, // Center by default for manual clips
      originalTrackId: _tracks.isNotEmpty ? _tracks[0].id : 'main',
    );

    if (_tracks.isEmpty) {
      _tracks = [Track(id: 'main', name: 'Main Track', clips: [newClip])];
    } else {
      _tracks[0].clips.add(newClip);
    }
    
    _syncToNative();
    selectClip(newClip.id);
    notifyListeners();
  }

  void addNewTrack() {
    _tracks.add(Track(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Track ${_tracks.length + 1}',
      clips: [],
    ));
    notifyListeners();
  }

  void updateClipTiming(SubtitleClip clip, Duration? newStart, Duration? newEnd, {bool resolveCollisions = true}) {
    if (newStart == null && newEnd == null) return;

    int currentTrackIdx = -1;
    int clipIdx = -1;

    for (int i = 0; i < _tracks.length; i++) {
        final idx = _tracks[i].clips.indexWhere((c) => c.id == clip.id);
        if (idx != -1) {
            currentTrackIdx = i;
            clipIdx = idx;
            break;
        }
    }

    if (currentTrackIdx != -1) {
        final foundClip = _tracks[currentTrackIdx].clips.removeAt(clipIdx);
        final startTime = newStart ?? foundClip.startTime;
        final endTime = newEnd ?? foundClip.endTime;
        
        final updatedClip = foundClip.copyWith(
            startTime: startTime,
            endTime: endTime,
        );

        if (resolveCollisions) {
            _resolveCollisions(updatedClip, currentTrackIdx);
        } else {
            _tracks[currentTrackIdx].clips.insert(clipIdx, updatedClip);
            _syncToNative();
            notifyListeners();
        }
    }
  }

  void forceResolveCollisions(String clipId) {
    int trackIdx = -1;
    int clipIdx = -1;
    for (int i = 0; i < _tracks.length; i++) {
      final idx = _tracks[i].clips.indexWhere((c) => c.id == clipId);
      if (idx != -1) {
        trackIdx = i;
        clipIdx = idx;
        break;
      }
    }
    if (trackIdx != -1) {
      final clip = _tracks[trackIdx].clips.removeAt(clipIdx);
      _resolveCollisions(clip, trackIdx);
    }
  }

  void stackSelectedClips() {
    if (_selectedClipIds.isEmpty) return;

    // 1. Gather all selected clips
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

    // 2. Sort by start time
    selectedClips.sort((a, b) => a.startTime.compareTo(b.startTime));

    // 3. Find max end time
    Duration maxEndTime = Duration.zero;
    for (var clip in selectedClips) {
        if (clip.endTime > maxEndTime) maxEndTime = clip.endTime;
    }

    // 4. Remove them from current tracks first to avoid duplicate IDs during re-insertion
    for (var track in _tracks) {
        track.clips.removeWhere((c) => _selectedClipIds.contains(c.id));
    }

    // 5. Place them in sequential tracks starting from baseTrackIndex
    // AND align them vertically in the preview column-style.
    const double gap = 0.08;
    final double totalHeight = (selectedClips.length - 1) * gap;
    final double startY = (1.0 - totalHeight) / 2;

    for (int i = 0; i < selectedClips.length; i++) {
        final clip = selectedClips[i];
        final updatedClip = clip.copyWith(
          endTime: maxEndTime,
          x: 0.5, // Center horizontally
          y: startY + (i * gap), // Stack vertically
        );
        
        // Target track: baseTrackIndex + (selectedClips.length - 1 - i)
        // This puts the EARLIEST clip on the BOTTOM-most track of the stack (layered on top)
        int targetTrackIdx = baseTrackIndex + (selectedClips.length - 1 - i);

        // Ensure track exists
        while (_tracks.length <= targetTrackIdx) {
            _tracks.add(Track(
                id: DateTime.now().millisecondsSinceEpoch.toString() + _tracks.length.toString(),
                name: 'Track ${_tracks.length + 1}',
                clips: [],
            ));
        }

        // We use _resolveCollisions strictly to ensure we don't overlap with UNSELECTED clips
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

    // 1. Remove them from current positions
    for (var track in _tracks) {
      track.clips.removeWhere((c) => _selectedClipIds.contains(c.id));
    }

    // 2. Revert timing and move to original tracks
    for (var clip in clipsToReset) {
      final resetClip = clip.copyWith(
        startTime: clip.originalStartTime,
        endTime: clip.originalEndTime,
      );

      String targetTrackId = clip.originalTrackId ?? 'main';
      int trackIdx = _tracks.indexWhere((t) => t.id == targetTrackId);
      
      if (trackIdx == -1) {
        trackIdx = 0; // Fallback to first track if original is gone
        if (_tracks.isEmpty) {
          _tracks.add(Track(id: 'main', name: 'Main Track', clips: []));
        }
      }

      // Re-insert and resolve collisions strictly
      _resolveCollisions(resetClip, trackIdx);
    }

    _syncToNative();
    notifyListeners();
  }

  void _resolveCollisions(SubtitleClip clip, int initialTrackIdx) {
    int targetTrackIdx = initialTrackIdx;
    bool hasCollision = true;

    while (hasCollision) {
        hasCollision = false;
        if (targetTrackIdx >= _tracks.length) {
            _tracks.add(Track(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: 'Track ${_tracks.length + 1}',
              clips: [],
            ));
        }

        final track = _tracks[targetTrackIdx];
        for (var existingClip in track.clips) {
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

    _tracks[targetTrackIdx].clips.add(clip);
    _syncToNative();
    notifyListeners();
  }

  void moveClip(SubtitleClip clip, String targetTrackId, Duration? newStartTime) {
    // Determine if this is a batch move
    final isPartOfSelection = _selectedClipIds.contains(clip.id);
    final clipIdsToMove = isPartOfSelection ? _selectedClipIds.toSet() : {clip.id};

    // 1. Find the current track indices for all clips to move
    final Map<String, int> clipToCurrentTrackIndex = {};
    for (int i = 0; i < _tracks.length; i++) {
      for (var c in _tracks[i].clips) {
        if (clipIdsToMove.contains(c.id)) {
          clipToCurrentTrackIndex[c.id] = i;
        }
      }
    }

    if (!clipToCurrentTrackIndex.containsKey(clip.id)) return;

    // 2. Calculate the track index offset based on the primary clip
    final targetTrackIndex = _tracks.indexWhere((t) => t.id == targetTrackId);
    if (targetTrackIndex == -1) return;
    
    final primaryCurrentIndex = clipToCurrentTrackIndex[clip.id]!;
    final trackOffset = targetTrackIndex - primaryCurrentIndex;

    // 3. Collect all clips to move, removing them from their current tracks
    final List<SubtitleClip> clipsMoved = [];
    for (var clipId in clipIdsToMove) {
      final currTrackIdx = clipToCurrentTrackIndex[clipId];
      if (currTrackIdx != null) {
        final track = _tracks[currTrackIdx];
        final index = track.clips.indexWhere((c) => c.id == clipId);
        if (index != -1) {
          clipsMoved.add(track.clips.removeAt(index));
        }
      }
    }

    // 4. Determine time offset if newStartTime is provided (though usually locked per user request)
    final Duration timeOffset = newStartTime != null 
        ? newStartTime - clip.startTime
        : Duration.zero;

    // 5. Place them in their new tracks
    for (var c in clipsMoved) {
      final oldTrackIdx = clipToCurrentTrackIndex[c.id]!;
      int newTrackIdx = oldTrackIdx + trackOffset;

      // Ensure we don't go below 0
      if (newTrackIdx < 0) newTrackIdx = 0;

      // Dynamically add tracks if we go above
      while (newTrackIdx >= _tracks.length) {
        addNewTrack();
      }

      final startTime = c.startTime + timeOffset;
      final duration = c.endTime - c.startTime;
      final updatedClip = c.copyWith(
        startTime: startTime,
        endTime: startTime + duration,
      );

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
      final clipsJson = _tracks.expand((t) => t.clips).map((c) => c.toJson()).toList();
      
      final int w, h;
      if (_aspectRatio > 1.2) {
        // Landscape (16:9)
        w = 1920;
        h = 1080;
      } else if (_aspectRatio < 0.8) {
        // Vertical (9:16)
        w = 1080;
        h = 1920;
      } else {
        // Square (1:1)
        w = 1080;
        h = 1080;
      }

      final result = await _bridge.exportVideo(
        width: w,
        height: h,
        durationMs: _totalDuration.inMilliseconds,
        clips: clipsJson,
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
