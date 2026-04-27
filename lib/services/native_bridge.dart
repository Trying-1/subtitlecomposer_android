import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.example.typgraphyeditor/bridge');

  Future<int?> initRenderer(int width, int height) async {
    try {
      final int? textureId = await _channel.invokeMethod('initRenderer', {
        'width': width,
        'height': height,
      });
      return textureId;
    } on PlatformException catch (e) {
      print("Failed to init renderer: '${e.message}'.");
      return null;
    }
  }

  Future<void> updateClips(List<Map<String, dynamic>> clips) async {
    try {
      await _channel.invokeMethod('updateClips', {'clips': clips});
    } on PlatformException catch (e) {
      print("Failed to update clips: '${e.message}'.");
    }
  }

  Future<void> updateProjectSettings({
    required double aspectRatio,
    required int backgroundColor,
    String? backgroundImagePath,
    double? bgScale,
    double? bgRotation,
    double? bgX,
    double? bgY,
    int? bgFillMode,
    int? width,
    int? height,
  }) async {
    try {
      await _channel.invokeMethod('updateProjectSettings', {
        'aspectRatio': aspectRatio,
        'backgroundColor': backgroundColor,
        'backgroundImagePath': backgroundImagePath,
        'bgScale': bgScale,
        'bgRotation': bgRotation,
        'bgX': bgX,
        'bgY': bgY,
        'bgFillMode': bgFillMode,
        'width': width,
        'height': height,
      });
    } on PlatformException catch (e) {
      print("Failed to update project settings: '${e.message}'.");
    }
  }


  Future<void> seekTo(int timeMs) async {
    try {
      await _channel.invokeMethod('seekTo', {'timeMs': timeMs});
    } on PlatformException catch (e) {
      print("Failed to seek: '${e.message}'.");
    }
  }

  Future<String?> exportVideo({
    required int width,
    required int height,
    required int durationMs,
    required List<Map<String, dynamic>> clips,
    String? audioPath,
    int? backgroundColor,
    String? backgroundImagePath,
    double? bgScale,
    double? bgRotation,
    double? bgX,
    double? bgY,
    int? bgFillMode,
  }) async {
    try {
      final String? result = await _channel.invokeMethod('exportVideo', {
        'width': width,
        'height': height,
        'durationMs': durationMs,
        'clips': clips,
        'audioPath': audioPath,
        'backgroundColor': backgroundColor,
        'backgroundImagePath': backgroundImagePath,
        'bgScale': bgScale,
        'bgRotation': bgRotation,
        'bgX': bgX,
        'bgY': bgY,
        'bgFillMode': bgFillMode,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to export video: '${e.message}'.");
      return null;
    }
  }

  Future<void> disposeRenderer() async {
    try {
      await _channel.invokeMethod('disposeRenderer');
    } on PlatformException catch (e) {
      print("Failed to dispose renderer: '${e.message}'.");
    }
  }

  Future<void> registerFont(String family, String path) async {
    try {
      await _channel.invokeMethod('registerFont', {
        'family': family,
        'path': path,
      });
    } on PlatformException catch (e) {
      print("Failed to register font: '${e.message}'.");
    }
  }
}
