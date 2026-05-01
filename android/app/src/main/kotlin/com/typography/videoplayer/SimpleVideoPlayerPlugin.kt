package com.typography.videoplayer

import io.flutter.embedding.engine.plugins.FlutterPlugin

class SimpleVideoPlayerPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            "com.typography/native_video_player",
            SimpleVideoPlayerFactory(binding.binaryMessenger)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Cleanup if needed
    }
}
