import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../../providers/editor_provider.dart';

class VoiceoverDialog extends StatefulWidget {
  const VoiceoverDialog({super.key});

  @override
  State<VoiceoverDialog> createState() => _VoiceoverDialogState();
}

class _VoiceoverDialogState extends State<VoiceoverDialog> with SingleTickerProviderStateMixin {
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  double _currentAmplitude = 0.0;
  bool _isInitializing = true;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRecordingFlow();
  }

  Future<void> _startRecordingFlow() async {
    final provider = context.read<EditorProvider>();
    await provider.startVoiceoverRecording();
    
    if (provider.isVoiceoverRecording) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      
      _amplitudeSubscription = provider
          .getVoiceoverAmplitudeStream(const Duration(milliseconds: 50))
          .listen((amp) {
        if (mounted) {
          // amp.current is usually between -160 and 0.
          // Map -60 (silence) to 0 (loudest) to 0.0 -> 1.0 range
          final raw = amp.current;
          final normalized = max(0.0, (raw + 60) / 60);
          setState(() {
            _currentAmplitude = normalized;
          });
        }
      });
      
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (mounted) {
          setState(() {
            _recordDuration = Duration(seconds: t.tick);
          });
        }
      });
    } else {
      // Failed to start
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    super.dispose();
  }

  void _cancelAndClose() {
    context.read<EditorProvider>().cancelVoiceoverRecording();
    Navigator.pop(context);
  }

  void _stopAndSave() {
    context.read<EditorProvider>().stopVoiceoverRecording();
    Navigator.pop(context);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        child: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
      );
    }

    return Dialog(
      backgroundColor: const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Recording Voiceover',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'KleeOne',
              ),
            ),
            const SizedBox(height: 24),
            
            // Visualizer & Microphone
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildBars(left: true),
                  const SizedBox(width: 16),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.pinkAccent.withOpacity(0.2 + (_currentAmplitude * 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(_currentAmplitude * 0.5),
                          blurRadius: 20 * _currentAmplitude,
                          spreadRadius: 5 * _currentAmplitude,
                        )
                      ],
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.pinkAccent, size: 32),
                  ),
                  const SizedBox(width: 16),
                  _buildBars(left: false),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              _formatDuration(_recordDuration),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 32),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _cancelAndClose,
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _stopAndSave,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop & Save'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBars({required bool left}) {
    // Generate 5 bars on each side that ripple based on amplitude
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        // Create a wave effect by offsetting the multiplier
        final offset = left ? (4 - index) : index;
        final factor = max(0.1, _currentAmplitude - (offset * 0.15));
        
        return Container(
          width: 6,
          height: 10 + (60 * factor),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withOpacity(0.5 + (factor * 0.5)),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
