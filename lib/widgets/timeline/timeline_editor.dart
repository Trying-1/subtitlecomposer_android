import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../models/editor_models.dart';
import '../../providers/editor_provider.dart';
import '../../providers/font_provider.dart';
import '../../utils/toast_utils.dart';
import '../../services/kinetic/kinetic_style.dart';
import 'kinetic_preset_sheet.dart';
import 'dart:async';

class LockableScrollPhysics extends AlwaysScrollableScrollPhysics {
  final bool Function() isLocked;
  const LockableScrollPhysics({required this.isLocked, super.parent});
  @override
  LockableScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LockableScrollPhysics(isLocked: isLocked, parent: buildParent(ancestor));
  }
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (isLocked()) return 0.0;
    return super.applyPhysicsToUserOffset(position, offset);
  }
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => !isLocked();
  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (isLocked()) return null;
    return super.createBallisticSimulation(position, velocity);
  }
}

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
  final Function(String) onRemoveTrack;
  final Function(dynamic, Duration?, Duration?, bool) onUpdateClipTiming;
  final Function(String) onResolveCollisions;
  final VoidCallback onStackSelected;
  final VoidCallback onResetSelected;
  final VoidCallback onSplit;
  final VoidCallback onMerge;
  final VoidCallback onSplitToWords;
  final VoidCallback onBurstSelected;
  final VoidCallback onTogetherSelected;
  final VoidCallback onDelete;
  final VoidCallback onActionStart; // For undo saving
  final bool isPlaying;
  final VoidCallback onTogglePlay;
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
  final bool isPlayheadLocked;
  final VoidCallback onTogglePlayheadLock;
  final VoidCallback onAddText;
  final VoidCallback onBulkAudio;
  final int textTimelineColor;
  final int audioTimelineColor;
  final int overlayTimelineColor;
  final int backgroundTimelineColor;

  final bool isPreviewZoomMode;
  final VoidCallback onTogglePreviewZoomMode;
  final VoidCallback onResetPreviewZoom;

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
    required this.onRemoveTrack,
    required this.onUpdateClipTiming,
    required this.onResolveCollisions,
    required this.onStackSelected,
    required this.onResetSelected,
    required this.onSplit,
    required this.onMerge,
    required this.onSplitToWords,
    required this.onBurstSelected,
    required this.onTogetherSelected,
    required this.onDelete,
    required this.onActionStart,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.isPlaying,
    required this.onTogglePlay,
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
    required this.isPlayheadLocked,
    required this.onTogglePlayheadLock,
    required this.onAddText,
    required this.onBulkAudio,
    required this.isPreviewZoomMode,
    required this.onTogglePreviewZoomMode,
    required this.onResetPreviewZoom,
    this.textTimelineColor = 0xFFFF9800,
    this.audioTimelineColor = 0xFF009688,
    this.overlayTimelineColor = 0xFF03A9F4,
    this.backgroundTimelineColor = 0xFFFFEB3B,
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
  DateTime _lastUpdateTime = DateTime.now();
  Timer? _autoScrollTimer;
  double _currentScrollDelta = 0;
  String? _draggingClipId;
  DateTime _lastSeekTime = DateTime.now();
  
  // Junction dragging state
  String? _junctionClipAId;
  String? _junctionClipBId;
  Duration? _initialJunctionTime;
  
  late ScrollController _horizontalScrollController;
  bool _isManualScrolling = false;
  double _lastPPS = 50.0;
  double get _pixelsPerSecond => _lastPPS;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    widget.playbackTime?.addListener(_onPlaybackTimeChanged);
    
    // Initial scroll to current time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalScrollController.hasClients) {
        final targetOffset = (widget.currentTime.inMilliseconds / 1000.0) * _pixelsPerSecond;
        _horizontalScrollController.jumpTo(targetOffset);
      }
    });
  }

  @override
  void dispose() {
    widget.playbackTime?.removeListener(_onPlaybackTimeChanged);
    _autoScrollTimer?.cancel();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll(double speed, {Function(double)? onScroll}) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_horizontalScrollController.hasClients) return;
      final currentOffset = _horizontalScrollController.offset;
      final maxOffset = _horizontalScrollController.position.maxScrollExtent;
      final newOffset = (currentOffset + speed).clamp(0.0, maxOffset);
      
      if (newOffset != currentOffset) {
        final delta = newOffset - currentOffset;
        _horizontalScrollController.jumpTo(newOffset);
        if (onScroll != null) onScroll(delta);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _handleAutoScroll(double globalX, {Function(double)? onScroll}) {
    if (!mounted) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final Offset localOffset = box.globalToLocal(Offset(globalX, 0));
    final double viewportWidth = box.size.width;
    
    const double edgeThreshold = 60.0;
    const double maxSpeed = 15.0;

    if (localOffset.dx < edgeThreshold) {
      // Near left edge
      final speedFactor = ((edgeThreshold - localOffset.dx) / edgeThreshold).clamp(0.0, 1.0);
      _startAutoScroll(-maxSpeed * speedFactor, onScroll: onScroll);
    } else if (localOffset.dx > viewportWidth - edgeThreshold) {
      // Near right edge
      final speedFactor = ((localOffset.dx - (viewportWidth - edgeThreshold)) / edgeThreshold).clamp(0.0, 1.0);
      _startAutoScroll(maxSpeed * speedFactor, onScroll: onScroll);
    } else {
      _stopAutoScroll();
    }
  }

  @override
  void didUpdateWidget(TimelineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackTime != widget.playbackTime) {
      oldWidget.playbackTime?.removeListener(_onPlaybackTimeChanged);
      widget.playbackTime?.addListener(_onPlaybackTimeChanged);
    }
    
    // Adjust scroll when zoom changes to keep same time at center
    if (oldWidget.zoomLevel != widget.zoomLevel && _horizontalScrollController.hasClients) {
      final time = widget.playbackTime?.value ?? widget.currentTime;
      // We need to calculate the NEW pps here or wait for next build.
      // Actually, since build will happen right after this, we can use a post frame callback
      // or just trust that build will recalculate pps and we can jump then.
      // Better: jump in build if zoom changed? No, jump in didUpdateWidget with calculated pps.
      
      // Calculate new PPS exactly like build does
      final double availableWidth = MediaQuery.of(context).size.width - 40; 
      double newPPS = 50.0 * widget.zoomLevel;
      if (widget.zoomLevel < 0.05) {
        final totalSeconds = widget.totalDuration.inMilliseconds / 1000.0;
        if (totalSeconds > 0) newPPS = availableWidth / totalSeconds;
      }
      
      final targetOffset = (time.inMilliseconds / 1000.0) * newPPS;
      _horizontalScrollController.jumpTo(targetOffset);
    }

    if (widget.selectedClipIds.isEmpty) {
      _draggingClipId = null;
      _isScrollingLocked = false;
      _activeEdgeClipId = null;
    }
  }

  void _onPlaybackTimeChanged() {
    if (_isManualScrolling || _isScrollingLocked) return;
    
    // Auto-scroll to keep current time at center
    final time = widget.playbackTime?.value ?? widget.currentTime;
    final targetOffset = (time.inMilliseconds / 1000.0) * _pixelsPerSecond;
    
    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.jumpTo(targetOffset);
    }
  }

  /// Syncs _currentTime in EditorProvider to match the current scroll position.
  /// This is the single source of truth: scroll offset → time → provider.seek().
  void _syncSeekToScroll() {
    if (!_horizontalScrollController.hasClients) return;
    final offset = _horizontalScrollController.offset;
    final seconds = offset / _pixelsPerSecond;
    final duration = Duration(milliseconds: (seconds * 1000).toInt());
    if (duration >= Duration.zero && duration <= widget.totalDuration) {
      widget.playbackTime?.value = duration;
      widget.onSeek(duration);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

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

        final double timelineWidth = (widget.totalDuration.inMilliseconds / 1000) * pps;
        final double halfViewportWidth = constraints.maxWidth / 2;

        return Container(
          color: const Color(0xFF16161E),
          child: Column(
            children: [
              _buildControlHeader(context),
              Expanded(
                child: Stack(
                  children: [
                    GestureDetector(
                      onScaleStart: (details) => _baseZoomLevel = widget.zoomLevel,
                      onScaleUpdate: (details) {
                        if (details.pointerCount >= 2) {
                          final newZoom = (_baseZoomLevel * details.scale).clamp(0.0, 5.0);
                          widget.onZoomChanged(newZoom);
                        }
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification && notification.dragDetails != null) {
                            _isManualScrolling = true;
                            if (widget.isPlaying) widget.onTogglePlay();
                          } else if (notification is ScrollEndNotification) {
                            // CRITICAL: Sync _currentTime to final scroll position after inertia ends.
                            // Without this, the visual playhead (scroll position) drifts from _currentTime
                            // during ballistic scroll, causing split-at-playhead to use a stale position.
                            if (_isManualScrolling || !widget.isPlaying) {
                              _syncSeekToScroll();
                            }
                            _isManualScrolling = false;
                          }
                          
                          if (notification is ScrollUpdateNotification) {
                            // Update during both manual scrolling AND inertia (ballistic) scrolling
                            if (_isManualScrolling || (!widget.isPlaying && notification.dragDetails == null)) {
                              final now = DateTime.now();
                              if (now.difference(_lastSeekTime).inMilliseconds >= 16) {
                                _lastSeekTime = now;
                                _syncSeekToScroll();
                              }
                            }
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: LockableScrollPhysics(isLocked: () => _isScrollingLocked),
                          child: SizedBox(
                            width: timelineWidth + (halfViewportWidth * 2),
                            child: Column(
                              children: [
                                _buildTimeRulerWithOffset(halfViewportWidth),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => widget.onSelect(null),
                                    child: SingleChildScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      child: _buildTracksColumn(halfViewportWidth),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Fixed Playhead Overlay
                    Positioned(
                      left: halfViewportWidth,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: _buildPlayhead(),
                      ),
                    ),
                    // Fixed Time Progress Indicator (CapCut Style)
                    Positioned(
                      left: 12,
                      top: 4, // Aligned with ruler text
                      child: ValueListenableBuilder<Duration>(
                        valueListenable: widget.playbackTime ?? ValueNotifier(widget.currentTime),
                        builder: (context, time, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${_formatDuration(time)} / ${_formatDuration(widget.totalDuration)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'KleeOne',
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlHeader(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F29),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 1, 16, 1),
            child: Row(
              children: [
                 _buildPlaybackControls(),
                const SizedBox(width: 8),
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
                if (AppConfig.showTimelinePanControls && provider.showPanControls) ...[
                  Container(width: 1, height: 16, color: Colors.white10),
                  const SizedBox(width: 8),
                  _buildVerticalToggle(
                    "PAN", 
                    widget.isPreviewZoomMode, 
                    widget.onTogglePreviewZoomMode, 
                    icon: widget.isPreviewZoomMode ? Icons.zoom_in_map_rounded : Icons.zoom_out_map_rounded,
                    color: widget.isPreviewZoomMode ? Colors.amberAccent : null,
                  ),
                  const SizedBox(width: 8),
                ],
                _buildVerticalToggle(
                  "RESET VIEW", 
                  false, 
                  widget.onResetPreviewZoom, 
                  icon: Icons.restart_alt_rounded,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
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
                    if (AppConfig.showTimelineUndo) ...[
                      _buildVerticalToggle("UNDO", false, widget.onUndo, icon: Icons.undo_rounded, color: widget.canUndo ? Colors.white : Colors.white10),
                      const SizedBox(width: 16),
                    ],
                    
                    if (AppConfig.showTimelineRedo) ...[
                      _buildVerticalToggle("REDO", false, widget.onRedo, icon: Icons.redo_rounded, color: widget.canRedo ? Colors.white : Colors.white10),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineSplit) ...[
                      _buildVerticalToggle("SPLIT", false, widget.onSplit, icon: Icons.content_cut_rounded),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineMerge) ...[
                      _buildVerticalToggle(
                        "MERGE", 
                        false, 
                        widget.onMerge, 
                        icon: Icons.link_rounded, 
                        color: widget.selectedClipIds.length >= 2 ? Colors.white : Colors.white10
                      ),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineDelete) ...[
                      _buildVerticalToggle("DEL", false, widget.onDelete, icon: Icons.delete_outline_rounded),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineDivide) ...[
                      _buildVerticalToggle(
                        "DIVIDE", 
                        false, 
                        widget.onSplitToWords, 
                        icon: Icons.format_list_bulleted_rounded,
                        color: widget.selectedClipIds.isNotEmpty ? Colors.white : Colors.white10
                      ),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineBurst) ...[
                      _buildVerticalToggle(
                        "BURST", 
                        false, 
                        widget.onBurstSelected, 
                        icon: Icons.flare_rounded,
                        color: widget.selectedClipIds.isNotEmpty ? Colors.white : Colors.white10
                      ),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineTogether) ...[
                      _buildVerticalToggle(
                        "TOGETHER", 
                        false, 
                        widget.onTogetherSelected, 
                        icon: Icons.splitscreen_rounded,
                        color: widget.selectedClipIds.isNotEmpty ? Colors.white : Colors.white10
                      ),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineStack) ...[
                      _buildVerticalToggle("STACK", false, widget.onStackSelected, icon: Icons.layers_outlined),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showKineticButton) ...[
                      _buildVerticalToggle(
                        "AUTO AI", 
                        false, 
                        () => _showKineticPresetPicker(context),
                        icon: Icons.auto_awesome_rounded,
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineReset) ...[
                      _buildVerticalToggle("RESET", false, widget.onResetSelected, icon: Icons.history_rounded),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineSplit || 
                        AppConfig.showTimelineMerge || 
                        AppConfig.showTimelineDivide || 
                        AppConfig.showTimelineBurst || 
                        AppConfig.showTimelineTogether || 
                        AppConfig.showTimelineDelete ||
                        AppConfig.showTimelineStack ||
                        AppConfig.showTimelineReset)
                      Container(width: 1, height: 16, color: Colors.white10),
                    const SizedBox(width: 16),
                    
                    if (AppConfig.showTimelineAddText) ...[
                      _buildVerticalToggle("ADD TXT", false, widget.onAddText, icon: Icons.text_fields_rounded, color: Colors.deepPurpleAccent),
                      const SizedBox(width: 16),
                    ],

                    _buildVerticalToggle(
                      "BULK SFX", 
                      false, 
                      widget.onBulkAudio, 
                      icon: Icons.library_music_rounded, 
                      color: widget.isMultiSelectMode && widget.selectedClipIds.length > 1 ? Colors.amberAccent : Colors.white10
                    ),
                    const SizedBox(width: 16),

                    _buildVerticalToggle("ALL", widget.isAllSelected, widget.onToggleSelectAll),
                    const SizedBox(width: 16),

                    if (AppConfig.showTimelinePush) ...[
                      _buildVerticalToggle("PUSH", widget.isCollisionAdjustEnabled, widget.onToggleCollisionAdjust),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineLock) ...[
                      _buildVerticalToggle(
                        "LOCK", 
                        widget.isPlayheadLocked, 
                        widget.onTogglePlayheadLock, 
                        icon: Icons.lock_clock_rounded,
                        color: widget.isPlayheadLocked ? Colors.redAccent : null,
                      ),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineMultiSelect) ...[
                      _buildVerticalToggle("MULTI", widget.isMultiSelectMode, widget.onToggleMultiSelect),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineLoop) ...[
                      _buildVerticalToggle(
                        "LP START", 
                        provider.focusStart != null, 
                        () => provider.setFocusStart(provider.currentTime), 
                        icon: Icons.keyboard_double_arrow_right_rounded,
                        color: provider.focusStart != null ? Colors.cyanAccent : null,
                      ),
                      const SizedBox(width: 16),
                      _buildVerticalToggle(
                        "LP END", 
                        provider.focusEnd != null, 
                        () => provider.setFocusEnd(provider.currentTime), 
                        icon: Icons.keyboard_double_arrow_left_rounded,
                        color: provider.focusEnd != null ? Colors.cyanAccent : null,
                      ),
                      const SizedBox(width: 16),
                      if (provider.focusStart != null || provider.focusEnd != null) ...[
                        _buildVerticalToggle(
                          "LP CLEAR", 
                          false, 
                          () => provider.clearFocusRange(), 
                          icon: Icons.highlight_off_rounded,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ],

                    Container(width: 1, height: 16, color: Colors.white10),
                    const SizedBox(width: 16),

                    // Visibility Toggles
                    if (AppConfig.showTimelineVisibilityToggles) ...[
                      _buildVerticalToggle("TEXT", widget.showTextTracks, widget.onToggleTextTracks, icon: widget.showTextTracks ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      const SizedBox(width: 16),
                      _buildVerticalToggle("OVERLAY", widget.showOverlayTracks, widget.onToggleOverlayTracks, icon: widget.showOverlayTracks ? Icons.layers_rounded : Icons.layers_clear_rounded),
                      const SizedBox(width: 16),
                      _buildVerticalToggle("BG", widget.showBackgroundTracks, widget.onToggleBackgroundTracks, icon: widget.showBackgroundTracks ? Icons.wallpaper_rounded : Icons.image_not_supported_rounded),
                      const SizedBox(width: 16),
                      _buildVerticalToggle("AUDIO", widget.showAudioTracks, widget.onToggleAudioTracks, icon: widget.showAudioTracks ? Icons.audiotrack_rounded : Icons.music_off_rounded),
                      const SizedBox(width: 16),
                    ],

                    if (AppConfig.showTimelineMarkers) ...[
                      _buildVerticalToggle("MARK", false, widget.onAddMarker, icon: Icons.bookmark_add_rounded, color: Colors.amberAccent),
                      const SizedBox(width: 16),
                      _buildVerticalToggle("CLR MK", false, widget.onClearMarkers, icon: Icons.bookmark_remove_outlined),
                      const SizedBox(width: 16),
                    ],
                    
                    if (AppConfig.showTimelineKeyframes) ...[
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
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildPlaybackControls() {
    return IconButton(
      onPressed: widget.onTogglePlay,
      icon: Icon(
        widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 20,
        color: Colors.deepPurpleAccent,
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
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
                  ? Icon(icon, size: 16, color: color ?? (value ? Colors.deepPurpleAccent : Colors.white70))
                  : FittedBox(
                      fit: BoxFit.contain,
                      child: IgnorePointer(
                        child: Switch(
                          value: value,
                          onChanged: (_) {}, // Handled by InkWell
                          activeColor: Colors.deepPurpleAccent,
                          activeTrackColor: Colors.deepPurpleAccent.withOpacity(0.3),
                          inactiveThumbColor: Colors.white24,
                          inactiveTrackColor: Colors.white10,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'KleeOne',
                fontSize: 6.5,
                fontWeight: FontWeight.w900,
                color: color ?? (value ? Colors.deepPurpleAccent : Colors.white38),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRuler() {
    final provider = context.watch<EditorProvider>();
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
                painter: RulerPainter(
                  widget.totalDuration, 
                  _pixelsPerSecond, 
                  widget.markers,
                  provider.focusStart,
                  provider.focusEnd,
                ),
              ),
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
    if (widget.isPlayheadLocked) return;
    final seconds = dx / _pixelsPerSecond;
    final duration = Duration(milliseconds: (seconds * 1000).toInt());
    if (duration >= Duration.zero && duration <= widget.totalDuration) {
      // Manually update the notifier for instant UI feedback
      widget.playbackTime?.value = duration;
      widget.onSeek(duration);
    }
  }

  Widget _buildTrackRow(Track track, {bool showAddButton = false}) {
    final GlobalKey trackKey = GlobalKey();
    final provider = context.watch<EditorProvider>();
    final trackHeight = provider.timelineTrackHeight;

    return Row(
      children: [
        SizedBox(
          width: 52,
          height: trackHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAddButton(track.type),
              _buildRemoveButton(track.id, isEnabled: track.isEmpty),
            ],
          ),
        ),
        _buildTrackLabelWidget(track),
        Expanded(
          child: DragTarget<Object>( // Object to support both
            key: trackKey,
            onWillAccept: (data) => true,
            onAcceptWithDetails: (details) {
              final RenderBox box = trackKey.currentContext!.findRenderObject() as RenderBox;
              final localPos = box.globalToLocal(details.offset);
              final startTime = Duration(milliseconds: (localPos.dx / _pixelsPerSecond * 1000).toInt());
              setState(() {
                _isScrollingLocked = false;
                _draggingClipId = null;
              });
              widget.onMoveClip(details.data, track.id, startTime);
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                height: trackHeight,
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty ? Colors.deepPurpleAccent.withOpacity(0.05) : Colors.transparent,
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Stack(
                  children: [
                    if (track.type == TrackType.text) ...[
                      ...track.clips.map((clip) => _buildClipWidget(clip)),
                      ..._buildJunctionHandles(track.clips, track.id),
                    ] else if (track.type == TrackType.overlay) ...[
                      ...track.overlays.map((clip) => _buildClipWidget(clip)),
                      ..._buildJunctionHandles(track.overlays, track.id),
                    ] else if (track.type == TrackType.background) ...[
                      ...track.backgrounds.map((clip) => _buildClipWidget(clip)),
                      ..._buildJunctionHandles(track.backgrounds, track.id),
                    ] else if (track.type == TrackType.audio) ...[
                      ...track.audioClips.map((clip) => _buildClipWidget(clip)),
                      ..._buildJunctionHandles(track.audioClips, track.id),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildJunctionHandles(List<dynamic> clips, String trackId) {
    if (clips.length < 2) return [];

    final List<Widget> junctions = [];
    final sortedClips = List.from(clips)..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (int i = 0; i < sortedClips.length - 1; i++) {
      final clipA = sortedClips[i];
      final clipB = sortedClips[i + 1];

      // Adjacent if gap is less than 100ms
      if ((clipA.endTime.inMilliseconds - clipB.startTime.inMilliseconds).abs() < 100) {
        junctions.add(_buildJunctionWidget(clipA, clipB));
      }
    }
    return junctions;
  }

  Widget _buildJunctionWidget(dynamic clipA, dynamic clipB) {
    final centerX = _calculatePosition(clipA.endTime);
    const double handleWidth = 28.0;
    
    return Positioned(
      left: centerX - (handleWidth / 2),
      top: 0,
      bottom: 0,
      width: handleWidth,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (widget.isPlaying) widget.onTogglePlay();
          _junctionClipAId = clipA.id;
          _junctionClipBId = clipB.id;
          _initialJunctionTime = clipA.endTime;
          _dragAccumulatedDelta = 0;
          _isScrollingLocked = true;
          widget.onActionStart();
        },
        onPointerMove: (event) {
          if (_initialJunctionTime == null || _junctionClipAId != clipA.id) return;

          _dragAccumulatedDelta += event.delta.dx;
          
          _handleAutoScroll(event.position.dx, onScroll: (delta) {
            _dragAccumulatedDelta += delta;
          });

          final totalDeltaSeconds = _dragAccumulatedDelta / _pixelsPerSecond;
          final newJunctionTime = _initialJunctionTime! + Duration(microseconds: (totalDeltaSeconds * 1000000).toInt());

          if (newJunctionTime > clipA.startTime && newJunctionTime < clipB.endTime) {
            // Update both clips: clipA's end and clipB's start
            widget.onUpdateClipTiming(clipA, null, newJunctionTime, false);
            widget.onUpdateClipTiming(clipB, newJunctionTime, null, false);
            setState(() {});
          }
        },
        onPointerUp: (event) {
          _stopAutoScroll();
          final idA = _junctionClipAId;
          final idB = _junctionClipBId;
          setState(() {
            _junctionClipAId = null;
            _junctionClipBId = null;
            _initialJunctionTime = null;
            _isScrollingLocked = false;
          });
          if (idA != null) widget.onResolveCollisions(idA);
          if (idB != null) widget.onResolveCollisions(idB);
        },
        onPointerCancel: (_) {
          _stopAutoScroll();
          setState(() {
            _junctionClipAId = null;
            _junctionClipBId = null;
            _initialJunctionTime = null;
            _isScrollingLocked = false;
          });
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _junctionClipAId == clipA.id ? 0.95 : 0.25,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 10,
                  color: _junctionClipAId == clipA.id ? Colors.cyanAccent : Colors.white,
                ),
              ),
              const SizedBox(width: 1),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _junctionClipAId == clipA.id ? 14.0 : 10.0,
                height: _junctionClipAId == clipA.id ? 14.0 : 10.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _junctionClipAId == clipA.id 
                      ? Colors.cyanAccent 
                      : Colors.white.withValues(alpha: 0.85),
                  boxShadow: [
                    BoxShadow(
                      color: _junctionClipAId == clipA.id 
                          ? Colors.cyanAccent.withValues(alpha: 0.45) 
                          : Colors.black45,
                      blurRadius: _junctionClipAId == clipA.id ? 8.0 : 4.0,
                      spreadRadius: _junctionClipAId == clipA.id ? 1.5 : 0.0,
                    ),
                  ],
                  border: Border.all(
                    color: _junctionClipAId == clipA.id ? Colors.white : Colors.white24,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 3.0,
                    height: 3.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _junctionClipAId == clipA.id ? Colors.black : Colors.black38,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 1),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _junctionClipAId == clipA.id ? 0.95 : 0.25,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 10,
                  color: _junctionClipAId == clipA.id ? Colors.cyanAccent : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
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
        onDragStarted: () {
          if (widget.isPlaying) widget.onTogglePlay();
          setState(() {
            _isScrollingLocked = true;
            _draggingClipId = clip.id;
          });
          widget.onActionStart();
        },
        onDragUpdate: (details) {
          _handleAutoScroll(details.globalPosition.dx);
        },
        onDragEnd: (_) {
          _stopAutoScroll();
          setState(() {
            _isScrollingLocked = false;
            _draggingClipId = null;
          });
          widget.onResolveCollisions(clip.id);
        },
        onDraggableCanceled: (_, __) {
          _stopAutoScroll();
          setState(() {
            _isScrollingLocked = false;
            _draggingClipId = null;
          });
        },
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            height: context.read<EditorProvider>().timelineTrackHeight - 8,
            child: _buildDraggingFeedback(clip),
          ),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: Opacity(
          opacity: _shouldHideClip(clip) ? 0.0 : 1.0,
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
              width: 24,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) {
                  if (widget.isPlaying) widget.onTogglePlay();
                  // Direct assignment — NO setState here to avoid rebuild killing the pointer tracking
                  _activeEdgeClipId = clip.id;
                  _activeEdgeIsLeft = true;
                  _isScrollingLocked = true;
                  _dragAccumulatedDelta = 0;
                  _initialClipStartTime = clip.startTime;
                  widget.onActionStart();
                },
                onPointerMove: (event) {
                  if (_initialClipStartTime == null || _activeEdgeClipId != clip.id) return;
                  
                  _dragAccumulatedDelta += event.delta.dx;
                  
                  // Handle auto-scroll during trimming
                  _handleAutoScroll(event.position.dx, onScroll: (delta) {
                    _dragAccumulatedDelta += delta;
                  });

                  final totalDeltaSeconds = _dragAccumulatedDelta / _pixelsPerSecond;
                  final newStart = _initialClipStartTime! + Duration(microseconds: (totalDeltaSeconds * 1000000).toInt());
                  if (newStart < clip.endTime && newStart >= Duration.zero) {
                    widget.onUpdateClipTiming(clip, newStart, null, false);
                    setState(() {}); // local repaint only
                  }
                },
                onPointerUp: (_) {
                  _stopAutoScroll();
                  final clipId = _activeEdgeClipId;
                  setState(() {
                    _activeEdgeClipId = null;
                    _activeEdgeIsLeft = null;
                    _isScrollingLocked = false;
                    _initialClipStartTime = null;
                  });
                  if (clipId != null) widget.onResolveCollisions(clipId);
                },
                onPointerCancel: (_) {
                  _stopAutoScroll();
                  setState(() {
                    _activeEdgeClipId = null;
                    _activeEdgeIsLeft = null;
                    _isScrollingLocked = false;
                  });
                },
                child: Center(
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: (_activeEdgeClipId == clip.id && _activeEdgeIsLeft == true) ? Colors.greenAccent : Colors.white54,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 24,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) {
                  if (widget.isPlaying) widget.onTogglePlay();
                  _activeEdgeClipId = clip.id;
                  _activeEdgeIsLeft = false;
                  _isScrollingLocked = true;
                  _dragAccumulatedDelta = 0;
                  _initialClipEndTime = clip.endTime;
                  widget.onActionStart();
                },
                onPointerMove: (event) {
                  if (_initialClipEndTime == null || _activeEdgeClipId != clip.id) return;
                  
                  _dragAccumulatedDelta += event.delta.dx;

                  // Handle auto-scroll during trimming
                  _handleAutoScroll(event.position.dx, onScroll: (delta) {
                    _dragAccumulatedDelta += delta;
                  });

                  final totalDeltaSeconds = _dragAccumulatedDelta / _pixelsPerSecond;
                  final newEnd = _initialClipEndTime! + Duration(microseconds: (totalDeltaSeconds * 1000000).toInt());
                  if (newEnd > clip.startTime) {
                    widget.onUpdateClipTiming(clip, null, newEnd, false);
                    setState(() {}); // local repaint only
                  }
                },
                onPointerUp: (_) {
                  _stopAutoScroll();
                  final clipId = _activeEdgeClipId;
                  setState(() {
                    _activeEdgeClipId = null;
                    _activeEdgeIsLeft = null;
                    _isScrollingLocked = false;
                    _initialClipEndTime = null;
                  });
                  if (clipId != null) widget.onResolveCollisions(clipId);
                },
                onPointerCancel: (_) {
                  _stopAutoScroll();
                  setState(() {
                    _activeEdgeClipId = null;
                    _activeEdgeIsLeft = null;
                    _isScrollingLocked = false;
                  });
                },
                child: Center(
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: (_activeEdgeClipId == clip.id && _activeEdgeIsLeft == false) ? Colors.greenAccent : Colors.white54,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);
}

  bool _shouldHideClip(dynamic clip) {
    if (_draggingClipId == null) return false;
    if (_draggingClipId == clip.id) return true;
    
    // If we are dragging a selected clip, hide all other selected clips
    if (widget.selectedClipIds.contains(_draggingClipId) && widget.selectedClipIds.contains(clip.id)) {
      return true;
    }
    
    return false;
  }

  Widget _buildDraggingFeedback(dynamic clip) {
    final isSelected = widget.selectedClipIds.contains(clip.id);
    final count = isSelected ? widget.selectedClipIds.length : 1;
    
    if (count <= 1) {
      return _buildClipContent(clip, isSelected, true);
    }
    
    // Multi-select ghost feedback
    final primaryClip = clip as TimelineClip;
    final primaryStartPos = _calculatePosition(primaryClip.startTime);
    final allTracks = [...widget.tracks, ...widget.overlayTracks, ...widget.backgroundTracks, ...widget.audioTracks];
    
    int primaryTrackIdx = -1;
    for (int i = 0; i < allTracks.length; i++) {
      if (allTracks[i].clips.contains(primaryClip) || 
          allTracks[i].overlays.contains(primaryClip) ||
          allTracks[i].backgrounds.contains(primaryClip) ||
          allTracks[i].audioClips.contains(primaryClip)) {
        primaryTrackIdx = i;
        break;
      }
    }

    final List<TimelineClip> selectedClips = [];
    final Map<String, int> clipToTrackIdx = {};
    
    for (int i = 0; i < allTracks.length; i++) {
      final List<TimelineClip> trackClips = [
        ...allTracks[i].clips,
        ...allTracks[i].overlays,
        ...allTracks[i].backgrounds,
        ...allTracks[i].audioClips,
      ];
      for (var c in trackClips) {
        if (widget.selectedClipIds.contains(c.id)) {
          selectedClips.add(c);
          clipToTrackIdx[c.id] = i;
        }
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Base child (Primary clip) defines the main size/position of feedback
        _buildClipContent(primaryClip, true, true),
        
        // Ghost elements for other selected clips
        ...selectedClips.where((c) => c.id != primaryClip.id).map((c) {
          final relX = _calculatePosition(c.startTime) - primaryStartPos;
          final cTrackIdx = clipToTrackIdx[c.id] ?? primaryTrackIdx;
          final trackHeight = context.read<EditorProvider>().timelineTrackHeight;
          final relY = (cTrackIdx - primaryTrackIdx) * trackHeight;

          return Positioned(
            left: relX,
            top: relY,
            height: trackHeight - 8, // Maintain consistent height for all ghosts
            child: Opacity(
              opacity: 0.4,
              child: _buildClipContent(c, true, true),
            ),
          );
        }).toList(),
        
        // Count Badge on top of primary
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amberAccent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: Text(
              "+${count - 1}",
              style: const TextStyle(
                fontFamily: 'KleeOne',
                color: Colors.black, 
                fontSize: 9, 
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildClipContent(TimelineClip clip, bool isSelected, bool isFeedback) {
    final hasEntrance = clip.entranceAnimation.type != AnimationType.none;
    final hasExit = clip.exitAnimation.type != AnimationType.none;
    final hasAnimation = hasEntrance || hasExit;
    final width = _calculatePosition(clip.endTime) - _calculatePosition(clip.startTime);
    Color clipColor;
    Color borderColor;

    if (isSelected || isFeedback) {
      clipColor = Colors.deepPurple;
      borderColor = Colors.white70;
    } else if (clip is AudioClip) {
      clipColor = Color(widget.audioTimelineColor).withOpacity(0.4);
      borderColor = Color(widget.audioTimelineColor).withOpacity(0.7);
    } else if (clip is OverlayClip) {
      clipColor = Color(widget.overlayTimelineColor).withOpacity(0.4);
      borderColor = Color(widget.overlayTimelineColor).withOpacity(0.7);
    } else if (clip is BackgroundClip) {
      clipColor = Color(widget.backgroundTimelineColor).withOpacity(0.4);
      borderColor = Color(widget.backgroundTimelineColor).withOpacity(0.7);
    } else {
      // Subtitle (Text)
      clipColor = Color(widget.textTimelineColor).withOpacity(0.4);
      borderColor = Color(widget.textTimelineColor).withOpacity(0.7);
    }

    return Container(
      width: width.clamp(20.0, double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: clipColor,
        border: Border.all(
          color: borderColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Waveform for Audio Clips
          if (clip is AudioClip && clip.waveform != null)
            Positioned.fill(
              child: CustomPaint(
                painter: WaveformPainter(
                  waveform: clip.waveform!,
                  color: isSelected ? Colors.white.withOpacity(0.2) : Color(widget.audioTimelineColor).withOpacity(0.3),
                ),
              ),
            ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (clip is AudioClip) ...[
                  Icon(Icons.audiotrack_rounded, size: 10, color: Color(widget.audioTimelineColor)),
                  const SizedBox(width: 4),
                ] else if (clip is OverlayClip) ...[
                  Icon(Icons.layers_outlined, size: 10, color: Color(widget.overlayTimelineColor)),
                  const SizedBox(width: 4),
                ] else if (clip is BackgroundClip) ...[
                  Icon(Icons.wallpaper_rounded, size: 10, color: Color(widget.backgroundTimelineColor)),
                  const SizedBox(width: 4),
                ] else if (clip is SubtitleClip) ...[
                  // Removed text icon as requested
                ],
                Flexible(
                  child: Text(
                    clip is SubtitleClip ? clip.text : (clip is OverlayClip ? "Overlay" : (clip is AudioClip ? (clip.isMainAudio ? "Main Audio" : "Audio") : "Background")),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'KleeOne',
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



  Widget _buildTimeRulerWithOffset(double padding) {
    return Padding(
      padding: EdgeInsets.only(left: padding, right: padding),
      child: _buildTimeRuler(),
    );
  }

  Widget _buildLabelsColumn() {
    return Column(
      children: [
        if (widget.showTextTracks) ...[
          ...widget.tracks.map((t) => _buildTrackLabelWidget(t)),
          _buildEmptySpaceLabel(),
        ],
        if (widget.showOverlayTracks) ...[
          const SizedBox(height: 4),
          ...widget.overlayTracks.map((t) => _buildTrackLabelWidget(t)),
          _buildEmptySpaceLabel(),
        ],
        if (widget.showBackgroundTracks) ...[
          const SizedBox(height: 4),
          ...widget.backgroundTracks.map((t) => _buildTrackLabelWidget(t)),
          _buildEmptySpaceLabel(),
        ],
        if (widget.showAudioTracks) ...[
          const SizedBox(height: 4),
          ...widget.audioTracks.map((t) => _buildTrackLabelWidget(t)),
          _buildEmptySpaceLabel(),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTracksColumn(double padding) {
    return Padding(
      padding: EdgeInsets.only(left: padding - 92, right: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTextTracks) ...[
            ...widget.tracks.asMap().entries.map((e) => _buildTrackRow(e.value, showAddButton: e.key == 0)),
            _buildEmptySpaceDragTarget(TrackType.text),
          ],
          if (widget.showOverlayTracks) ...[
            const SizedBox(height: 4),
            ...widget.overlayTracks.asMap().entries.map((e) => _buildTrackRow(e.value, showAddButton: e.key == 0)),
            _buildEmptySpaceDragTarget(TrackType.overlay),
          ],
          if (widget.showBackgroundTracks) ...[
            const SizedBox(height: 4),
            ...widget.backgroundTracks.asMap().entries.map((e) => _buildTrackRow(e.value, showAddButton: e.key == 0)),
            _buildEmptySpaceDragTarget(TrackType.background),
          ],
          if (widget.showAudioTracks) ...[
            const SizedBox(height: 4),
            ...widget.audioTracks.asMap().entries.map((e) => _buildTrackRow(e.value, showAddButton: e.key == 0)),
            _buildEmptySpaceDragTarget(TrackType.audio),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTrackLabelWidget(Track track) {
    return _buildLabelContainer(_getTrackTypeLabel(track.type), _getTrackTypeColor(track.type));
  }

  Widget _buildLabelContainer(String label, Color color) {
    final trackHeight = context.watch<EditorProvider>().timelineTrackHeight;
    return Container(
      height: trackHeight,
      width: 40,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'KleeOne',
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
              color: color.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(TrackType type) {
    return _buildTimelineActionButton(
      icon: Icons.add_rounded,
      color: Colors.greenAccent,
      onTap: () => widget.onAddTrack(type),
    );
  }

  Widget _buildRemoveButton(String trackId, {bool isEnabled = true}) {
    return _buildTimelineActionButton(
      icon: Icons.remove_rounded,
      color: Colors.redAccent,
      onTap: () => widget.onRemoveTrack(trackId),
      isEnabled: isEnabled,
      disabledMessage: 'Track is not empty',
    );
  }

  Widget _buildTimelineActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isEnabled = true,
    String? disabledMessage,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : () {
          if (disabledMessage != null) {
            ToastUtils.show(disabledMessage, isError: true);
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isEnabled ? color.withOpacity(0.08) : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isEnabled ? color.withOpacity(0.15) : Colors.white10, width: 0.5),
          ),
          child: Center(
            child: Icon(icon, size: 14, color: isEnabled ? color.withOpacity(0.8) : Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySpaceLabel() {
    return const SizedBox(height: 60, width: 92);
  }

  Widget _buildEmptySpaceDragTarget(TrackType type) {
    final trackHeight = context.watch<EditorProvider>().timelineTrackHeight;
    return DragTarget<Object>(
      onWillAccept: (data) => true,
      onAccept: (data) {
        widget.onAddTrack(type);
      },
      builder: (context, candidateData, rejectedData) {
        return Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: trackHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAddButton(type),
                  ],
                ),
              ),
              _buildLabelContainer(_getTrackTypeLabel(type), _getTrackTypeColor(type)),
              Expanded(
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty ? Colors.deepPurpleAccent.withOpacity(0.05) : Colors.transparent,
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Center(
                    child: candidateData.isNotEmpty
                      ? const Text(
                          "DROP TO CREATE NEW TRACK", 
                          style: TextStyle(fontFamily: 'KleeOne', color: Colors.deepPurpleAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                        )
                      : const Text(
                          "DROP CLIP TO CREATE TRACK",
                          style: TextStyle(fontFamily: 'KleeOne', color: Colors.white10, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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

  String _getTrackTypeLabel(TrackType type) {
    switch (type) {
      case TrackType.text: return "TEXT";
      case TrackType.overlay: return "OVERLAY";
      case TrackType.background: return "BG";
      case TrackType.audio: return "AUDIO";
    }
  }

  Color _getTrackTypeColor(TrackType type) {
    switch (type) {
      case TrackType.text: return Color(widget.textTimelineColor);
      case TrackType.overlay: return Color(widget.overlayTimelineColor);
      case TrackType.background: return Color(widget.backgroundTimelineColor);
      case TrackType.audio: return Color(widget.audioTimelineColor);
    }
  }

  void _showKineticPresetPicker(BuildContext context) {
    final provider = context.read<EditorProvider>();
    final fontProvider = context.read<FontProvider>();
    
    // Collect all available fonts
    final defaultFonts = [
      'Poppins', 'Bellota', 'BhuTukaExpandedOne', 'Bokor', 'BungeeHairline',
      'Caramel', 'Explora', 'GrandifloraOne', 'KleeOne', 'Lacquer',
      'LibreBarcode39Text', 'LuckiestGuy', 'MajorMonoDisplay', 'Metrophobic',
      'Michroma', 'NewRocker', 'NewTegomin', 'ProtestRevolution',
    ];
    final customFonts = fontProvider.customFonts.map((f) => f.family).toList();
    final allFonts = [...defaultFonts, ...customFonts];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return KineticPresetSheet(
          allFonts: allFonts,
          onApply: (styles, doBurst, doTogether, bgColor) {
            Navigator.pop(sheetContext);
            provider.applyKineticStyle(styles, doBurst: doBurst, doTogether: doTogether, customBgColor: bgColor);
          },
        );
      },
    );
  }
}

class RulerPainter extends CustomPainter {
  final Duration totalDuration;
  final double pixelsPerSecond;
  final List<Duration> markers;
  final Duration? focusStart;
  final Duration? focusEnd;
  
  RulerPainter(this.totalDuration, this.pixelsPerSecond, this.markers, this.focusStart, this.focusEnd);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Loop Focus Range first so grid lines are drawn on top
    if (focusStart != null && focusEnd != null) {
      final startX = (focusStart!.inMilliseconds / 1000) * pixelsPerSecond;
      final endX = (focusEnd!.inMilliseconds / 1000) * pixelsPerSecond;
      
      // Soft translucent cyan background
      final rangePaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.08)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(startX, 0, endX, size.height), rangePaint);
      
      // Boundaries lines
      final boundPaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.4)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(startX, 0), Offset(startX, size.height), boundPaint);
      canvas.drawLine(Offset(endX, 0), Offset(endX, size.height), boundPaint);

      // Draw small loop bracket icons [ ] at the top/bottom edges
      final bracketPaint = Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.fill;
        
      // Left bracket [
      final leftPath = Path()
        ..moveTo(startX, 0)
        ..lineTo(startX + 4, 0)
        ..lineTo(startX + 4, 2)
        ..lineTo(startX + 1.5, 2)
        ..lineTo(startX + 1.5, size.height - 2)
        ..lineTo(startX + 4, size.height - 2)
        ..lineTo(startX + 4, size.height)
        ..lineTo(startX, size.height)
        ..close();
      canvas.drawPath(leftPath, bracketPaint);

      // Right bracket ]
      final rightPath = Path()
        ..moveTo(endX, 0)
        ..lineTo(endX - 4, 0)
        ..lineTo(endX - 4, 2)
        ..lineTo(endX - 1.5, 2)
        ..lineTo(endX - 1.5, size.height - 2)
        ..lineTo(endX - 4, size.height - 2)
        ..lineTo(endX - 4, size.height)
        ..lineTo(endX, size.height)
        ..close();
      canvas.drawPath(rightPath, bracketPaint);
    }

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
            style: const TextStyle(fontFamily: 'KleeOne', color: Colors.white38, fontSize: 8),
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
    oldDelegate.markers != markers ||
    oldDelegate.focusStart != focusStart ||
    oldDelegate.focusEnd != focusEnd;
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

class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final Color color;

  WaveformPainter({required this.waveform, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    final double midY = height / 2;
    
    final int totalPoints = waveform.length;
    final double spacing = width / totalPoints;

    for (int i = 0; i < totalPoints; i++) {
      final double amplitude = waveform[i].clamp(0.0, 1.0);
      final double barHeight = amplitude * height * 0.8;
      final double x = i * spacing;
      
      canvas.drawLine(
        Offset(x, midY - barHeight / 2),
        Offset(x, midY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => 
    oldDelegate.waveform != waveform || oldDelegate.color != color;
}
