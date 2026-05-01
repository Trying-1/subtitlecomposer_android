import 'dart:async';
import 'package:flutter/services.dart';

class NativeVideoPlayerController {
  final int viewId;
  late MethodChannel _channel;
  
  final _preparedController = StreamController<int>.broadcast();
  Stream<int> get onPrepared => _preparedController.stream;
  
  final _completionController = StreamController<void>.broadcast();
  Stream<void> get onCompletion => _completionController.stream;

  NativeVideoPlayerController(this.viewId) {
    _channel = MethodChannel('com.example.typgraphyeditor/video_player_$viewId');
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onPrepared':
        _preparedController.add(call.arguments['duration'] as int);
        break;
      case 'onCompletion':
        _completionController.add(null);
        break;
    }
  }

  Future<void> load(String path) async {
    await _channel.invokeMethod('load', {'path': path});
  }

  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  Future<void> seekTo(int positionMs) async {
    await _channel.invokeMethod('seekTo', {'position': positionMs});
  }

  Future<void> setMute(bool muted) async {
    await _channel.invokeMethod('setMute', {'muted': muted});
  }

  Future<void> setLooping(bool looping) async {
    await _channel.invokeMethod('setLooping', {'looping': looping});
  }

  Future<int> getCurrentPosition() async {
    return await _channel.invokeMethod('getCurrentPosition') as int;
  }

  void dispose() {
    _preparedController.close();
    _completionController.close();
    _channel.invokeMethod('dispose');
  }
}
