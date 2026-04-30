import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.example.typgraphyeditor/bridge');

  Future<int?> initRenderer(int width, int height) async {
    return await _channel.invokeMethod<int>('initRenderer', {'width': width, 'height': height});
  }

  Future<void> updateClips(List<Map<String, dynamic>> clips) async {
    await _channel.invokeMethod('updateClips', {'clips': clips});
  }

  Future<void> updateProjectSettings({
    required double aspectRatio,
    required int backgroundColor,
    String? backgroundImagePath,
    int? width,
    int? height,
    double? bgScale,
    double? bgRotation,
    double? bgX,
    double? bgY,
    int? bgFillMode,
  }) async {
    await _channel.invokeMethod('updateProjectSettings', {
      'aspectRatio': aspectRatio,
      'backgroundColor': backgroundColor,
      'backgroundImagePath': backgroundImagePath,
      'width': width,
      'height': height,
      'bgScale': bgScale,
      'bgRotation': bgRotation,
      'bgX': bgX,
      'bgY': bgY,
      'bgFillMode': bgFillMode,
    });
  }

  Future<void> seekTo(int timeMs) async {
    await _channel.invokeMethod('seekTo', {'timeMs': timeMs});
  }

  Future<void> setPlaying(bool playing) async {
    await _channel.invokeMethod('setPlaying', {'playing': playing});
  }

  Future<String?> exportVideo({
    required int width,
    required int height,
    required int durationMs,
    required List<Map<String, dynamic>> clips,
    required List<Map<String, dynamic>> audioTracks,
    String? audioPath,
    required int backgroundColor,
    String? backgroundImagePath,
    double? bgScale,
    double? bgRotation,
    double? bgX,
    double? bgY,
    int? bgFillMode,
  }) async {
    return await _channel.invokeMethod<String>('exportVideo', {
      'width': width,
      'height': height,
      'durationMs': durationMs,
      'clips': clips,
      'audioTracks': audioTracks,
      'audioPath': audioPath,
      'backgroundColor': backgroundColor,
      'backgroundImagePath': backgroundImagePath,
      'bgScale': bgScale,
      'bgRotation': bgRotation,
      'bgX': bgX,
      'bgY': bgY,
      'bgFillMode': bgFillMode,
    });
  }

  Future<void> extractAudio(String videoPath, String outputPath) async {
    await _channel.invokeMethod('extractAudio', {
      'videoPath': videoPath,
      'outputPath': outputPath,
    });
  }

  Future<void> disposeRenderer() async {
    await _channel.invokeMethod('disposeRenderer');
  }

  Future<void> registerFont(String family, String path) async {
    await _channel.invokeMethod('registerFont', {'family': family, 'path': path});
  }

  Future<int> getVideoDuration(String path) async {
    return await _channel.invokeMethod<int>('getVideoDuration', {'path': path}) ?? 0;
  }

  // Whisper
  Future<int> initWhisper(String modelPath) async {
    return await _channel.invokeMethod<int>('initWhisper', {'modelPath': modelPath}) ?? 0;
  }

  Future<String> transcribeWhisper(int contextPtr, String audioPath, String initialPrompt, String language) async {
    return await _channel.invokeMethod<String>('transcribeWhisper', {
      'contextPtr': contextPtr,
      'audioPath': audioPath,
      'initialPrompt': initialPrompt,
      'language': language,
    }) ?? "[]";
  }

  Future<void> freeWhisper(int contextPtr) async {
    await _channel.invokeMethod('freeWhisper', {'contextPtr': contextPtr});
  }

  // VAD
  Future<List<Map<String, dynamic>>> getSpeechSegments(String audioPath) async {
    final List<dynamic>? segments = await _channel.invokeMethod<List<dynamic>>('getSpeechSegments', {'audioPath': audioPath});
    if (segments == null) return [];
    return segments.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
