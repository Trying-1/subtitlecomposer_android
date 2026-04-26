import 'package:flutter/material.dart';
import '../../models/editor_models.dart';

class TimelineEditor extends StatefulWidget {
  final List<Track> tracks;
  final Duration currentTime;
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
  final Function(SubtitleClip, String, Duration?) onMoveClip;
  final VoidCallback onAddTrack;
  final Function(SubtitleClip, Duration?, Duration?, bool) onUpdateClipTiming;
  final Function(String) onResolveCollisions;
  final VoidCallback onStackSelected;
  final VoidCallback onResetSelected;

  const TimelineEditor({
    super.key,
    required this.tracks,
    required this.currentTime,
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

  double get _pixelsPerSecond => 50.0 * widget.zoomLevel;

  @override
  Widget build(BuildContext context) {
    final timelineWidth = (widget.totalDuration.inMilliseconds / 1000) * _pixelsPerSecond + 200;

    return Container(
      color: const Color(0xFF16161E),
      child: Column(
        children: [
          _buildZoomControls(context),
          Expanded(
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
                              ...widget.tracks.map((track) => _buildTrackRow(track)).toList(),
                              _buildEmptySpaceDragTarget(),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: TextButton.icon(
                                  onPressed: widget.onAddTrack,
                                  icon: const Icon(Icons.add, size: 16, color: Colors.deepPurpleAccent),
                                  label: const Text("ADD TRACK", style: TextStyle(fontSize: 10, color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.05),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.black26,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.zoom_out, size: 16, color: Colors.white54),
          Expanded(
            child: Slider(
              value: widget.zoomLevel,
              min: 0.1,
              max: 5.0,
              activeColor: Colors.deepPurpleAccent,
              onChanged: widget.onZoomChanged,
            ),
          ),
          const Icon(Icons.zoom_in, size: 16, color: Colors.white54),
          const SizedBox(width: 16),
          const Spacer(),
          _buildVerticalToggle("ALL", widget.isAllSelected, widget.onToggleSelectAll),
          const SizedBox(width: 12),
          _buildVerticalToggle("RESET", false, widget.onResetSelected, icon: Icons.history_rounded),
          const SizedBox(width: 12),
          _buildVerticalToggle("STACK", false, widget.onStackSelected, icon: Icons.layers_outlined),
          const SizedBox(width: 12),
          _buildVerticalToggle("MULTI", widget.isMultiSelectMode, widget.onToggleMultiSelect),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildVerticalToggle(String label, bool value, VoidCallback onTap, {IconData? icon}) {
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
                  ? Icon(icon, size: 16, color: Colors.white70)
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
        height: 35,
        color: const Color(0xFF1F1F29),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: RulerPainter(widget.totalDuration, _pixelsPerSecond),
              ),
            ),
            Positioned(
              left: _calculatePosition(widget.currentTime),
              top: 0,
              bottom: 0,
              child: _buildPlayhead(),
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
          width: 12,
          height: 12,
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
      widget.onSeek(duration);
    }
  }

  Widget _buildTrackRow(Track track) {
    final GlobalKey trackKey = GlobalKey();
    return DragTarget<SubtitleClip>(
      key: trackKey,
      onWillAccept: (data) {
        if (data != null && !track.clips.any((c) => c.id == data.id)) {
          widget.onMoveClip(data, track.id, null);
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        widget.onMoveClip(details.data, track.id, null);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.deepPurpleAccent.withOpacity(0.05) : Colors.transparent,
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Stack(
            children: track.clips.map((clip) => _buildClipWidget(clip)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildClipWidget(SubtitleClip clip) {
    final left = _calculatePosition(clip.startTime);
    final width = _calculatePosition(clip.endTime) - left;
    final isSelected = widget.selectedClipIds.contains(clip.id);

    return Positioned(
      left: left,
      top: 8,
      bottom: 8,
      width: width.clamp(20.0, double.infinity),
      child: LongPressDraggable<SubtitleClip>(
        data: clip,
        axis: Axis.vertical,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            height: 54,
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

  Widget _buildClipContent(SubtitleClip clip, bool isSelected, bool isFeedback) {
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
            : hasAnimation
              ? [const Color(0xFF4C1D95).withOpacity(0.6), const Color(0xFF7C3AED).withOpacity(0.3)]
              : [Colors.deepPurple.withOpacity(0.4), Colors.deepPurple.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? Colors.white70 : hasAnimation ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.deepPurpleAccent.withOpacity(0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: (isSelected || isFeedback) ? [
          BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)
        ] : null,
      ),
      child: Center(
        child: Text(
          clip.text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: 11, 
            color: isSelected ? Colors.white : Colors.white70, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  double _calculatePosition(Duration time) {
    return (time.inMilliseconds / 1000) * _pixelsPerSecond; 
  }

  Widget _buildEmptySpaceDragTarget() {
    return DragTarget<SubtitleClip>(
      onWillAccept: (_) => true,
      onAccept: (_) => widget.onAddTrack(),
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.deepPurpleAccent.withOpacity(0.05) : Colors.transparent,
          ),
          child: candidateData.isNotEmpty 
            ? const Center(
                child: Text(
                  "DROP TO CREATE NEW TRACK", 
                  style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                )
              )
            : null,
        );
      },
    );
  }
}

class RulerPainter extends CustomPainter {
  final Duration totalDuration;
  final double pixelsPerSecond;
  
  RulerPainter(this.totalDuration, this.pixelsPerSecond);

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
        canvas.drawLine(Offset(x, 20), Offset(x, 35), paint);
        
        if (i % 5 == 0 || pixelsPerSecond > 100) {
          textPainter.text = TextSpan(
            text: "${i}s",
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x + 4, 5));
        }
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) => 
    oldDelegate.totalDuration != totalDuration || oldDelegate.pixelsPerSecond != pixelsPerSecond;
}
