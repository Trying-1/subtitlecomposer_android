import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../models/editor_models.dart';
import 'common/common_controls.dart';

class TimingTab extends StatefulWidget {
  final dynamic clip; // SubtitleClip, OverlayClip, BackgroundClip, or AudioClip
  final Function(dynamic clip, Duration? start, Duration? end, {bool resolve}) onUpdate;

  const TimingTab({
    super.key,
    required this.clip,
    required this.onUpdate,
  });

  @override
  State<TimingTab> createState() => _TimingTabState();
}

class _TimingTabState extends State<TimingTab> {
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _durationController;
  
  final FocusNode _startFocus = FocusNode();
  final FocusNode _endFocus = FocusNode();
  final FocusNode _durationFocus = FocusNode();

  int _activeSubTab = 0; // 0: Timing, 1: Track

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: _formatDuration(widget.clip.startTime));
    _endController = TextEditingController(text: _formatDuration(widget.clip.endTime));
    _durationController = TextEditingController(text: _formatDuration(widget.clip.duration));
  }

  @override
  void didUpdateWidget(TimingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.startTime != widget.clip.startTime && !_startFocus.hasFocus) {
      _startController.text = _formatDuration(widget.clip.startTime);
    }
    if (oldWidget.clip.endTime != widget.clip.endTime && !_endFocus.hasFocus) {
      _endController.text = _formatDuration(widget.clip.endTime);
    }
    if (oldWidget.clip.duration != widget.clip.duration && !_durationFocus.hasFocus) {
      _durationController.text = _formatDuration(widget.clip.duration);
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _durationController.dispose();
    _startFocus.dispose();
    _endFocus.dispose();
    _durationFocus.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    return (d.inMilliseconds / 1000.0).toStringAsFixed(3);
  }

  Duration? _parseDuration(String s) {
    try {
      final seconds = double.parse(s);
      return Duration(milliseconds: (seconds * 1000).toInt());
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final totalDurationSec = provider.totalDuration.inMilliseconds / 1000.0;
    
    final startSec = widget.clip.startTime.inMilliseconds / 1000.0;
    final endSec = widget.clip.endTime.inMilliseconds / 1000.0;
    final durSec = widget.clip.duration.inMilliseconds / 1000.0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-tab selector
          Row(
            children: [
              _buildSubTabButton("TIMING", 0),
              const SizedBox(width: 12),
              _buildSubTabButton("TRACK", 1),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_activeSubTab == 0) ...[
            const Text(
              "PRECISE TIMING",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.amberAccent,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTimeInput(
                    "START TIME (SEC)",
                    _startController,
                    _startFocus,
                    (val) {
                      final dur = _parseDuration(val);
                      if (dur != null) {
                        widget.onUpdate(widget.clip, dur, null, resolve: true);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeInput(
                    "END TIME (SEC)",
                    _endController,
                    _endFocus,
                    (val) {
                      final dur = _parseDuration(val);
                      if (dur != null) {
                        widget.onUpdate(widget.clip, null, dur, resolve: true);
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            CommonControls.buildDialScrubber(
              context,
              "START ADJUST",
              startSec,
              0,
              endSec - 0.01,
              (val) {
                widget.onUpdate(widget.clip, Duration(milliseconds: (val * 1000).toInt()), null, resolve: false);
              },
              onEnd: () {
                widget.onUpdate(widget.clip, widget.clip.startTime, null, resolve: true);
              },
            ),
            
            const SizedBox(height: 16),
            
            CommonControls.buildDialScrubber(
              context,
              "END ADJUST",
              endSec,
              startSec + 0.01,
              totalDurationSec + 10.0, // Allow extending
              (val) {
                widget.onUpdate(widget.clip, null, Duration(milliseconds: (val * 1000).toInt()), resolve: false);
              },
              onEnd: () {
                widget.onUpdate(widget.clip, null, widget.clip.endTime, resolve: true);
              },
            ),

            const SizedBox(height: 24),
            
            // Duration Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL DURATION", style: TextStyle(fontSize: 10, color: Colors.white38)),
                Text("${durSec.toStringAsFixed(3)}s", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalDurationSec > 0 ? (durSec / totalDurationSec).clamp(0.0, 1.0) : 0,
              backgroundColor: Colors.white10,
              color: Colors.amberAccent,
              minHeight: 2,
            ),
          ] else ...[
            // Track Management
            const Text(
              "TRACK MANAGEMENT",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.amberAccent,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTrackSelector(context, provider),
          ],
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String label, int index) {
    final bool isActive = _activeSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.amberAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.amberAccent.withOpacity(0.5) : Colors.white10,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isActive ? Colors.amberAccent : Colors.white38,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackSelector(BuildContext context, EditorProvider provider) {
    final currentIdx = provider.getCurrentTrackIndex(widget.clip);
    final availableIndices = provider.getAvailableTrackIndices(widget.clip);
    final isOverlay = widget.clip is OverlayClip;
    final isBackground = widget.clip is BackgroundClip;
    final isAudio = widget.clip is AudioClip;
    
    final trackList = isOverlay ? provider.overlayTracks : (isBackground ? provider.backgroundTracks : (isAudio ? provider.audioTracks : provider.tracks));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("CURRENT TRACK: ", style: TextStyle(fontSize: 10, color: Colors.white38)),
            Text("#${currentIdx + 1}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          ],
        ),
        const SizedBox(height: 12),
        const Text("MOVE TO TRACK:", style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trackList.length + 1, // +1 for "New Track"
            itemBuilder: (context, index) {
              final bool isCurrent = index == currentIdx;
              final bool isAvailable = availableIndices.contains(index) || index == trackList.length;
              final bool isNewTrack = index == trackList.length;

              return GestureDetector(
                onTap: isAvailable && !isCurrent ? () {
                  final String targetTrackId;
                  if (isNewTrack) {
                    // Add new track first
                    final trackType = isOverlay ? TrackType.overlay : (isBackground ? TrackType.background : (isAudio ? TrackType.audio : TrackType.text));
                    provider.addNewTrack(trackType);
                    targetTrackId = trackList.last.id;
                  } else {
                    targetTrackId = trackList[index].id;
                  }
                  provider.moveClip(widget.clip, targetTrackId, widget.clip.startTime);
                } : null,
                child: Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isCurrent 
                        ? Colors.amberAccent 
                        : (isAvailable ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.02)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent ? Colors.amberAccent : (isAvailable ? Colors.white24 : Colors.transparent),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isNewTrack ? "+" : "${index + 1}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.black : (isAvailable ? Colors.white : Colors.white12),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInput(String label, TextEditingController controller, FocusNode focusNode, ValueChanged<String> onSubmitted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 4),
            _buildNudgeButton("-", () {
              final val = _parseDuration(controller.text);
              if (val != null) {
                final newVal = val - const Duration(milliseconds: 100);
                onSubmitted(_formatDuration(newVal < Duration.zero ? Duration.zero : newVal));
              }
            }),
            _buildNudgeButton("+", () {
              final val = _parseDuration(controller.text);
              if (val != null) {
                onSubmitted(_formatDuration(val + const Duration(milliseconds: 100)));
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildNudgeButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 30,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
