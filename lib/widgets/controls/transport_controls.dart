import 'package:flutter/material.dart';

class TransportControls extends StatelessWidget {
  final bool isPlaying;
  final Duration currentTime;
  final Duration totalDuration;
  final VoidCallback onTogglePlay;

  const TransportControls({
    super.key,
    required this.isPlaying,
    required this.currentTime,
    required this.totalDuration,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32),
            color: Colors.deepPurpleAccent,
            onPressed: onTogglePlay,
          ),
          const SizedBox(width: 8),
          _buildTimeDisplay(),
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
      "${formatDuration(currentTime)} / ${formatDuration(totalDuration)}",
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }
}
