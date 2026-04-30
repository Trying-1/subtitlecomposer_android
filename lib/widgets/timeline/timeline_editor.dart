import 'package:flutter/material.dart';
import '../../models/editor_models.dart';

class TimelineEditor extends StatefulWidget {
  final List<Track> tracks;
  final List<Track> overlayTracks;
  final List<Track> backgroundTracks;
  final List<Track> audioTracks;
  final Duration currentTime;
  final ValueNotifier<Duration>? playbackTime;
  final Duration totalDuration;
  final Function(Duration) onSeek;
  final Set<String> selectedClipIds;
  final Function(String?) onSelect;
  final Function(String) onToggleSelect;
  final bool isMultiSelectMode;
  final VoidCallback onToggleMultiSelect;
  final bool isAllSelected;
  final VoidCallback onToggleSelectAll;
  final double zoomLevel;
  final Function(double) onZoomChanged;
  final Function(dynamic, String, Duration?) onMoveClip; // dynamic to support both clip types
  final Function(TrackType) onAddTrack;
  final Function(dynamic, Duration?, Duration?, bool) onUpdateClipTiming;
  final Function(String) onResolveCollisions;
  final VoidCallback onStackSelected;
  final VoidCallback onResetSelected;
  final VoidCallback onSplit;
  final VoidCallback onMerge;
  final VoidCallback onSplitToWords;
  final VoidCallback onDelete;
  final VoidCallback onActionStart; // For undo saving
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final bool isKeyframeAtCurrentTime;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final bool showTextTracks;
  final bool showOverlayTracks;
  final bool showBackgroundTracks;
  final bool showAudioTracks;
  final VoidCallback onToggleTextTracks;
  final VoidCallback onToggleOverlayTracks;
  final VoidCallback onToggleBackgroundTracks;
  final VoidCallback onToggleAudioTracks;
  final VoidCallback? onAddKeyframe;
  final VoidCallback? onClearKeyframes;
  final List<Duration> markers;
  final VoidCallback onAddMarker;
  final VoidCallback onClearMarkers;
  final bool isCollisionAdjustEnabled;
  final VoidCallback onToggleCollisionAdjust;
  final VoidCallback onAddText;

  const TimelineEditor({
    super.key,
    required this.tracks,
    required this.overlayTracks,
    required this.backgroundTracks,
    required this.audioTracks,
    required this.currentTime,
    this.playbackTime,
    required this.totalDuration,
    required this.onSeek,
    required this.selectedClipIds,
    required this.onSelect,
    required this.onToggleSelect,
    required this.isMultiSelectMode,
    required this.onToggleMultiSelect,
    required this.isAllSelected,
    required this.onToggleSelectAll,
    required this.zoomLevel,
    required this.onZoomChanged,
    required this.onMoveClip,
    required this.onAddTrack,
    required this.onUpdateClipTiming,
    required this.onResolveCollisions,
    required this.onStackSelected,
    required this.onResetSelected,
    required this.onSplit,
    required this.onMerge,
    required this.onSplitToWords,
    required this.onDelete,
    required this.onActionStart,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.onAddKeyframe,
    this.onClearKeyframes,
    this.isKeyframeAtCurrentTime = false,
    this.showTextTracks = true,
    this.showOverlayTracks = true,
    this.showBackgroundTracks = true,
    this.showAudioTracks = true,
    required this.onToggleTextTracks,
    required this.onToggleOverlayTracks,
    required this.onToggleBackgroundTracks,
    required this.onToggleAudioTracks,
    required this.markers,
    required this.onAddMarker,
    required this.onClearMarkers,
    required this.isCollisionAdjustEnabled,
    required this.onToggleCollisionAdjust,
    required this.onAddText,
  });

  @override
  State<TimelineEditor> createState() => _TimelineEditorState();
}

class _TimelineEditorState extends State<TimelineEditor> {
  bool _isScrollingLocked = false;
  double _dragAccumulatedDelta = 0;
  Duration? _initialClipStartTime;
  Duration? _initialClipEndTime;
  String? _activeEdgeClipId;
  bool? _activeEdgeIsLeft;
  double _baseZoomLevel = 1.0;

  double _lastPPS = 50.0;
  double get _pixelsPerSecond => _lastPPS;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth - 40; 
        double pps = 50.0 * widget.zoomLevel;
        
        if (widget.zoomLevel < 0.05) {
          final totalSeconds = widget.totalDuration.inMilliseconds / 1000.0;
          if (totalSeconds > 0) {
            pps = availableWidth / totalSeconds;
          }
        }
        _lastPPS = pps;

        final timelineWidth = (widget.totalDuration.inMilliseconds / 1000) * pps + 100;

        return Container(
          color: const Color(0xFF16161E),
          child: Column(
            children: [
              _buildControlHeader(context),
              if (!widget.isCollapsed)
                Expanded(
                  child: GestureDetector(
                    onScaleStart: (details) {
                      _baseZoomLevel = widget.zoomLevel;
                    },
                    onScaleUpdate: (details) {
                      if (details.pointerCount >= 2) {
                        final newZoom = (_baseZoomLevel * details.scale).clamp(0.0, 5.0);
                        widget.onZoomChanged(newZoom);
                      }
                    },
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: _isScrollingLocked ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        width: timelineWidth,
                        child: Column(
                          children: [
                            _buildTimeRuler(),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => widget.onSelect(null),
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (widget.showTextTracks) ...[
                                        _buildSectionHeader("TEXT"),
                                        ...widget.tracks.map((track) => _buildTrackRow(track)),
                                        _buildEmptySpaceDragTarget(TrackType.text),
                                      ],
                                      if (widget.showOverlayTracks) ...[
                                        const SizedBox(height: 16),
                                        _buildSectionHeader("OVERLAYS"),
                                        ...widget.overlayTracks.map((track) => _buildTrackRow(track)),
                                        _buildEmptySpaceDragTarget(TrackType.overlay),
                                      ],
                                      if (widget.showBackgroundTracks) ...[
                                        const SizedBox(height: 16),
                                        _buildSectionHeader("BACKGROUND"),
                                        ...widget.backgroundTracks.map((track) => _buildTrackRow(track)),
                                        _buildEmptySpaceDragTarget(TrackType.background),
                                      ],
                                      if (widget.showAudioTracks) ...[
                                        const SizedBox(height: 16),
                                        _buildSectionHeader("MUSIC & SFX"),
                                        ...widget.audioTracks.map((track) => _buildTrackRow(track)),
                                        _buildEmptySpaceDragTarget(TrackType.audio),
                                      ],
                                      const SizedBox(height: 100), // Buffer for scrolling
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F29),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          // Row 1: Playback & Zoom
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 1, 16, 1),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onTogglePlay,
                  icon: Icon(
                    widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                    color: Colors.deepPurpleAccent,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                _buildTimeDisplay(),
                const SizedBox(width: 16),
                const Icon(Icons.zoom_out, size: 14, color: Colors.white30),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: widget.zoomLevel,
                      min: 0.0,
                      max: 5.0,
                      activeColor: Colors.deepPurpleAccent,
                      inactiveColor: Colors.white10,
                      onChanged: widget.onZoomChanged,
                    ),
                  ),
                ),
                const Icon(Icons.zoom_in, size: 14, color: Colors.white30),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onToggleCollapse,
                  icon: Icon(
                    widget.isCollapsed ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (!widget.isCollapsed) ...[
            const Divider(height: 1, color: Colors.white10),
            // Row 2: Tools (Scrollable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Visibility Toggles
                    _buildVerticalToggle("TEXT", widget.showTextTracks, widget.onToggleTextTracks, icon: widget.showTextTracks ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("OVERLAY", widget.showOverlayTracks, widget.onToggleOverlayTracks, icon: widget.showOverlayTracks ? Icons.layers_rounded : Icons.layers_clear_rounded),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("BG", widget.showBackgroundTracks, widget.onToggleBackgroundTracks, icon: widget.showBackgroundTracks ? Icons.wallpaper_rounded : Icons.image_not_supported_rounded),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("AUDIO", widget.showAudioTracks, widget.onToggleAudioTracks, icon: widget.showAudioTracks ? Icons.audiotrack_rounded : Icons.music_off_rounded),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("UNDO", false, widget.onUndo, icon: Icons.undo_rounded, color: widget.canUndo ? Colors.white : Colors.white10),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("REDO", false, widget.onRedo, icon: Icons.redo_rounded, color: widget.canRedo ? Colors.white : Colors.white10),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("MARK", false, widget.onAddMarker, icon: Icons.bookmark_add_rounded, color: Colors.amberAccent),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("CLR MK", false, widget.onClearMarkers, icon: Icons.bookmark_remove_outlined),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 16, color: Colors.white10),
                    const SizedBox(width: 16),
                    
                    _buildVerticalToggle("SPLIT", false, widget.onSplit, icon: Icons.content_cut_rounded),
                    const SizedBox(width: 16),
                    _buildVerticalToggle(
                      "MERGE", 
                      false, 
                      widget.onMerge, 
                      icon: Icons.link_rounded, 
                      color: widget.selectedClipIds.length >= 2 ? Colors.white : Colors.white10
                    ),
                    const SizedBox(width: 16),
                    _buildVerticalToggle(
                      "DIVIDE", 
                      false, 
                      widget.onSplitToWords, 
                      icon: Icons.format_list_bulleted_rounded,
                      color: widget.selectedClipIds.length == 1 ? Colors.white : Colors.white10
                    ),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("DEL", false, widget.onDelete, icon: Icons.delete_outline_rounded),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 16, color: Colors.white10),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("ADD TXT", false, widget.onAddText, icon: Icons.text_fields_rounded, color: Colors.deepPurpleAccent),
                    const SizedBox(width: 16),
                    
                    if (widget.onAddKeyframe != null) ...[
                      _buildVerticalToggle(
                        widget.isKeyframeAtCurrentTime ? "REMOVE" : "KEYFRAME", 
                        widget.isKeyframeAtCurrentTime, 
                        widget.onAddKeyframe!, 
                        icon: widget.isKeyframeAtCurrentTime ? Icons.diamond_outlined : Icons.diamond_rounded
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (widget.onClearKeyframes != null) ...[
                      _buildVerticalToggle("CLR CLIP", false, widget.onClearKeyframes!, icon: Icons.layers_clear_rounded),
                      const SizedBox(width: 16),
                    ],
                    const SizedBox(width: 40), // Spacing before multi-select tools
                    _buildVerticalToggle("ALL", widget.isAllSelected, widget.onToggleSelectAll),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("RESET", false, widget.onResetSelected, icon: Icons.history_rounded),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("STACK", false, widget.onStackSelected, icon: Icons.layers_outlined),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("PUSH", widget.isCollisionAdjustEnabled, widget.onToggleCollisionAdjust),
                    const SizedBox(width: 16),
                    _buildVerticalToggle("MULTI", widget.isMultiSelectMode, widget.onToggleMultiSelect),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(d.inMinutes.remainder(60));
      final seconds = twoDigits(d.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    return Text(
      "${formatDuration(widget.currentTime)} / ${formatDuration(widget.totalDuration)}",
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
      ),
    );
  }

  Widget _buildVerticalToggle(String label, bool value, VoidCallback onTap, {IconData? icon, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              width: 32,
              child: Center(
                child: icon != null 
                  ? Icon(icon, size: 16, color: color ?? Colors.white70)
                  : FittedBox(
                      fit: BoxFit.contain,
                      child: Switch(
                        value: value,
                        onChanged: (_) => onTap(),
                        activeColor: Colors.deepPurpleAccent,
                        activeTrackColor: Colors.deepPurpleAccent.withOpacity(0.3),
                        inactiveThumbColor: Colors.white24,
                        inactiveTrackColor: Colors.white10,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                fontSize: 6.5,
                fontWeight: FontWeight.w900,
                color: Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRuler() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => _handleSeek(details.localPosition.dx),
      onTapDown: (details) => _handleSeek(details.localPosition.dx),
      child: Container(
        height: 20,
        color: const Color(0xFF1F1F29),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: RulerPainter(widget.totalDuration, _pixelsPerSecond, widget.markers),
              ),
            ),
            ValueListenableBuilder<Duration>(
              valueListenable: widget.playbackTime ?? ValueNotifier(widget.currentTime),
              builder: (context, time, _) {
                return Positioned(
                  left: _calculatePosition(time),
                  top: 0,
                  bottom: 0,
                  child: _buildPlayhead(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayhead() {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            width: 2,
            color: Colors.redAccent.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  void _handleSeek(double dx) {
    final seconds = dx / _pixelsPerSecond;
    final duration = Duration(milliseconds: (seconds * 1000).toInt());
    if (duration >= Duration.zero && duration <= widget.totalDuration) {
      // Manually update the notifier for instant UI feedback
      widget.playbackTime?.value = duration;
      widget.onSeek(duration);
    }
  }

  Widget _buildTrackRow(Track track) {
    final GlobalKey trackKey = GlobalKey();
    return DragTarget<Object>( // Object to support both
      key: trackKey,
      onWillAccept: (data) => true,
      onAcceptWithDetails: (details) {
        final RenderBox box = trackKey.currentContext!.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.offset);
        final startTime = Duration(milliseconds: (localPos.dx / _pixelsPerSecond * 1000).toInt());
        widget.onMoveClip(details.data, track.id, startTime);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.deepPurpleAccent.withOpacity(0.05) : Colors.transparent,
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Stack(
            children: [
              if (track.type == TrackType.text)
                ...track.clips.map((clip) => _buildClipWidget(clip))
              else if (track.type == TrackType.overlay)
                ...track.overlays.map((clip) => _buildClipWidget(clip))
              else if (track.type == TrackType.background)
                ...track.backgrounds.map((clip) => _buildClipWidget(clip))
              else if (track.type == TrackType.audio)
                ...track.audioClips.map((clip) => _buildClipWidget(clip)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClipWidget(dynamic clip) {
    final left = _calculatePosition(clip.startTime);
    final width = _calculatePosition(clip.endTime) - left;
    final isSelected = widget.selectedClipIds.contains(clip.id);

    return Positioned(
      left: left,
      top: 4,
      bottom: 4,
      width: width.clamp(20.0, double.infinity),
      child: LongPressDraggable<Object>(
        data: clip,
        // Removed axis: Axis.vertical to allow horizontal dragging mode:AGENT_MODE_EXECUTION
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            height: 40,
            child: _buildClipContent(clip, isSelected, true),
          ),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => widget.onSelect(clip.id),
              child: _buildClipContent(clip, isSelected, false),
            ),
            // Trimming Handles - Only show when single selection
            if (isSelected && widget.selectedClipIds.length == 1) ...[
              Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 40, // Increased hit area
              child: Listener(
                key: ValueKey('${clip.id}_left_handle'),
                onPointerDown: (_) {
                  setState(() {
                    _activeEdgeClipId = clip.id;
                    _activeEdgeIsLeft = true;
                    _isScrollingLocked = true;
                    _dragAccumulatedDelta = 0;
                    _initialClipStartTime = clip.startTime;
                  });
                  widget.onActionStart();
                },
                onPointerUp: (_) {
                  if (_dragAccumulatedDelta.abs() < 5) {
                    widget.onSelect(clip.id);
                  }
                  setState(() {
                    _activeEdgeClipId = null;
                    _activeEdgeIsLeft = null;
                    _isScrollingLocked = false;
                    _initialClipStartTime = null;
                  });
                  widget.onResolveCollisions(clip.id);
                },
                onPointerCancel: (_) {
                   setState(() {
                    _activeEdgeClipId = null;
                    _activeEdgeIsLeft = null;
                    _isScrollingLocked = false;
                  });
                },
                onPointerMove: (event) {
                  if (_initialClipStartTime == null || _activeEdgeClipId != clip.id || _activeEdgeIsLeft != true) return;
                  _dragAccumulatedDelta += event.delta.dx;
                  final totalDeltaSeconds = _dragAccumulatedDelta / _pixelsPerSecond;
                  final newStart = _initialClipStartTime! + Duration(microseconds: (totalDeltaSeconds * 1000000).toInt());
                  
                  if (newStart < clip.endTime && newStart >= Duration.zero) {
                    widget.onUpdateClipTiming(clip, newStart, null, false);
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 5,
                      height: 24,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: (_activeEdgeClipId == clip.id && _activeEdgeIsLeft == true) ? Colors.greenAccent : Colors.white70,
                        borderRadius: BorderRadius.circular(2.5),
                        boxShadow: [
                          BoxShadow(
                            color: (_activeEdgeClipId == clip.id && _activeEdgeIsLeft == true) 
                              ? Colors.greenAccent.withOpacity(0.5) 
                              : Colors.black.withOpacity(0.5), 
                            blurRadius: 4
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 40, // Increased hit area
              child: Listener(
                key: ValueKey('${clip.id}_right_handle'),
                onPointerDown: (_) {
                  setState(() {
                    _activeEdgeClipId = clip.id;
                    _activeEdgeIsLeft = false;
                    _isScrollingLocked = true;
                    _dragAccumulatedDelta = 0;
                    _initialClipEndTime = clip.endTime;
                  });
                  widget.onActionStart();
                },
                onPointerUp: (_) {
                  if (_dragAccumulatedDelta.abs() < 5) {
                    widget.onSelect(clip.id);
                  }
                  setState(() {
                    _activeEdgeClipId = null;
                    _activeEdgeIsLeft = null;
                    _isScrollingLocked = false;
                    _initialClipEndTime = null;
                  });
                  widget.onResolveCollisions(clip.id);
                },
                onPointerCancel: (_) {
                   setState(() {
                    _activeEdgeClipId = null;
                    _activeEdgeIsLeft = null;
                    _isScrollingLocked = false;
                  });
                },
                onPointerMove: (event) {
                  if (_initialClipEndTime == null || _activeEdgeClipId != clip.id || _activeEdgeIsLeft != false) return;
                  _dragAccumulatedDelta += event.delta.dx;
                  final totalDeltaSeconds = _dragAccumulatedDelta / _pixelsPerSecond;
                  final newEnd = _initialClipEndTime! + Duration(microseconds: (totalDeltaSeconds * 1000000).toInt());
                  
                  if (newEnd > clip.startTime) {
                    widget.onUpdateClipTiming(clip, null, newEnd, false);
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 5,
                      height: 24,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: (_activeEdgeClipId == clip.id && _activeEdgeIsLeft == false) ? Colors.greenAccent : Colors.white70,
                        borderRadius: BorderRadius.circular(2.5),
                        boxShadow: [
                          BoxShadow(
                            color: (_activeEdgeClipId == clip.id && _activeEdgeIsLeft == false) 
                              ? Colors.greenAccent.withOpacity(0.5) 
                              : Colors.black.withOpacity(0.5), 
                            blurRadius: 4
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildClipContent(TimelineClip clip, bool isSelected, bool isFeedback) {
    final hasEntrance = clip.entranceAnimation.type != AnimationType.none;
    final hasExit = clip.exitAnimation.type != AnimationType.none;
    final hasAnimation = hasEntrance || hasExit;
    final width = _calculatePosition(clip.endTime) - _calculatePosition(clip.startTime);

    return Container(
      width: width.clamp(20.0, double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected 
            ? [Colors.deepPurpleAccent, Colors.deepPurple] 
            : clip is AudioClip
              ? [Colors.cyan.withOpacity(0.4), Colors.cyan.withOpacity(0.2)]
              : hasAnimation
                ? [const Color(0xFF4C1D95).withOpacity(0.6), const Color(0xFF7C3AED).withOpacity(0.3)]
                : [Colors.deepPurple.withOpacity(0.4), Colors.deepPurple.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected 
            ? Colors.white70 
            : clip is AudioClip
              ? Colors.cyanAccent.withOpacity(0.3)
              : hasAnimation 
                ? Colors.deepPurpleAccent.withOpacity(0.5) 
                : Colors.deepPurpleAccent.withOpacity(0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: (isSelected || isFeedback) ? [
          BoxShadow(
            color: (clip is AudioClip ? Colors.cyanAccent : Colors.deepPurpleAccent).withOpacity(0.4), 
            blurRadius: 10, 
            spreadRadius: 1
          )
        ] : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (clip is AudioClip) ...[
                  const Icon(Icons.audiotrack_rounded, size: 10, color: Colors.cyanAccent),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    clip is SubtitleClip ? clip.text : (clip is OverlayClip ? "Overlay" : (clip is AudioClip ? (clip.isMainAudio ? "Main Audio" : "Audio") : "Background")),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10, 
                      color: isSelected ? Colors.white : Colors.white70, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Keyframe Indicators
          if (clip.keyframes.isNotEmpty)
            ...clip.keyframes.map((k) {
              final pos = k.timeOffset * _pixelsPerSecond;
              return Positioned(
                left: pos - 4, // Center the 8px diamond
                bottom: -2,
                child: Transform.rotate(
                  angle: 0.785398, // 45 degrees in radians
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.deepPurpleAccent,
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                  ),
                ),
              );
            }).toList(),
          
          // Loop Indicator (Dotted Line)
          if (clip.sourceDurationMs > 0 && clip.duration.inMilliseconds > clip.sourceDurationMs)
            ...List.generate((clip.duration.inMilliseconds / clip.sourceDurationMs).floor(), (index) {
              if (index == 0) return const SizedBox.shrink(); // No line at the very start
              final pos = (index * clip.sourceDurationMs / 1000) * _pixelsPerSecond;
              return Positioned(
                left: pos,
                top: 0,
                bottom: 0,
                child: CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: DottedLinePainter(),
                ),
              );
            }),
        ],
      ),
    );
  }

  double _calculatePosition(Duration time) {
    return (time.inMilliseconds / 1000) * _pixelsPerSecond; 
  }

  Widget _buildEmptySpaceDragTarget(TrackType type) {
    return DragTarget<Object>(
      onWillAccept: (_) => true,
      onAccept: (_) => widget.onAddTrack(type),
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.deepPurpleAccent.withOpacity(0.05) : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (candidateData.isNotEmpty)
                const Text(
                  "DROP TO CREATE NEW TRACK", 
                  style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                )
              else 
                TextButton.icon(
                  onPressed: () => widget.onAddTrack(type),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Colors.white24),
                  label: Text("ADD ${type == TrackType.text ? 'TEXT' : (type == TrackType.overlay ? 'OVERLAY' : (type == TrackType.background ? 'BACKGROUND' : 'AUDIO'))} TRACK", 
                    style: const TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.2),
      width: double.infinity,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 8,
          color: Colors.deepPurpleAccent,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class RulerPainter extends CustomPainter {
  final Duration totalDuration;
  final double pixelsPerSecond;
  final List<Duration> markers;
  
  RulerPainter(this.totalDuration, this.pixelsPerSecond, this.markers);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= totalDuration.inSeconds; i++) {
        double x = i * pixelsPerSecond;
        canvas.drawLine(Offset(x, 12), Offset(x, 20), paint);
        
        if (i % 5 == 0 || pixelsPerSecond > 100) {
          textPainter.text = TextSpan(
            text: "${i}s",
            style: const TextStyle(color: Colors.white38, fontSize: 8),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x + 4, 1));
        }
    }

    // Draw Markers
    final markerPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill;
    
    final markerStroke = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var m in markers) {
      final x = (m.inMilliseconds / 1000) * pixelsPerSecond;
      // Draw a small diamond
      final path = Path();
      path.moveTo(x, 20);
      path.lineTo(x + 4, 25);
      path.lineTo(x, 30);
      path.lineTo(x - 4, 25);
      path.close();
      
      canvas.drawPath(path, markerPaint);
      canvas.drawPath(path, markerStroke);
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) => 
    oldDelegate.totalDuration != totalDuration || 
    oldDelegate.pixelsPerSecond != pixelsPerSecond ||
    oldDelegate.markers != markers;
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 4;
    const dashSpace = 4;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
