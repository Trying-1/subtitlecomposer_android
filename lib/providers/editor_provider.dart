import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/editor_models.dart';
import '../services/native_bridge.dart';
import '../utils/subtitle_parser.dart';
import '../utils/animation_presets.dart';
import 'package:hive/hive.dart';

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
    double? textOpacity,
  }) {
    final idSet = ids.toSet();
    
    // Update text tracks
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
            textOpacity: textOpacity,
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

    // Update overlay tracks
    for (var track in _overlayTracks) {
      for (int i = 0; i < track.overlays.length; i++) {
        final clip = track.overlays[i];
        if (idSet.contains(clip.id)) {
          track.overlays[i] = clip.copyWith(
            x: x,
            y: y,
            rotation: rotation,
            scale: scale,
            opacity: opacity,
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

  void addOverlay(String imagePath) {
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

  void addNewTrack(TrackType type) {
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
