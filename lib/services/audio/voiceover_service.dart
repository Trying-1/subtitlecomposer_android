import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service dedicated to handling microphone permissions and audio recording.
class VoiceoverService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  /// Stream of amplitude values for visualizing the recording.
  Stream<Amplitude> onAmplitudeChanged(Duration interval) {
    return _audioRecorder.onAmplitudeChanged(interval);
  }

  /// Starts recording audio to a temporary file.
  /// Returns the intended path of the file, or null if permissions were denied.
  Future<String?> startRecording() async {
    try {
      // Check and request microphone permissions
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        // Generate a unique filename based on current timestamp
        final filePath = '${dir.path}/voiceover_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc, // Standard highly compatible encoder
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );
        
        _isRecording = true;
        return filePath;
      } else {
        debugPrint('Microphone permission denied.');
        return null;
      }
    } catch (e) {
      debugPrint('Error starting voiceover recording: $e');
      return null;
    }
  }

  /// Stops the current recording session and returns the path to the saved file.
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      debugPrint('Error stopping voiceover recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancels and deletes the current recording.
  Future<void> cancelRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error canceling voiceover recording: $e');
      _isRecording = false;
    }
  }

  /// Cleans up resources.
  void dispose() {
    _audioRecorder.dispose();
  }
}
