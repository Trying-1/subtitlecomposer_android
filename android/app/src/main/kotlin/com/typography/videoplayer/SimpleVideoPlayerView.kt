package com.typography.videoplayer

import android.content.Context
import android.graphics.Color
import android.media.MediaPlayer
import android.net.Uri
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.VideoView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class SimpleVideoPlayerView(
    private val context: Context,
    messenger: BinaryMessenger,
    viewId: Int
) : PlatformView, MethodChannel.MethodCallHandler {

    private val container = FrameLayout(context)
    private val videoView = VideoView(context)
    private val channel = MethodChannel(messenger, "com.typography/video_player_$viewId")
    private var isMuted = false
    private var mediaPlayer: MediaPlayer? = null

    init {
        videoView.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
            Gravity.CENTER
        )
        container.addView(videoView)
        container.setBackgroundColor(Color.BLACK)
        
        channel.setMethodCallHandler(this)

        videoView.setOnPreparedListener { mp ->
            mediaPlayer = mp
            if (isMuted) {
                mp.setVolume(0f, 0f)
            }
            // Send duration back
            val info = mapOf("duration" to mp.duration)
            channel.invokeMethod("onPrepared", info)
        }

        videoView.setOnCompletionListener {
            channel.invokeMethod("onCompletion", null)
        }
        
        videoView.setOnErrorListener { _, what, extra ->
            channel.invokeMethod("onError", mapOf("what" to what, "extra" to extra))
            true
        }
    }

    override fun getView(): View = container

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "load" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    videoView.setVideoURI(Uri.parse(path))
                    result.success(null)
                } else {
                    result.error("INVALID_PATH", "Path is null", null)
                }
            }
            "play" -> {
                videoView.start()
                result.success(null)
            }
            "pause" -> {
                videoView.pause()
                result.success(null)
            }
            "seekTo" -> {
                val position = call.argument<Int>("position") ?: 0
                videoView.seekTo(position)
                result.success(null)
            }
            "setMute" -> {
                isMuted = call.argument<Boolean>("muted") ?: false
                mediaPlayer?.setVolume(if (isMuted) 0f else 1f, if (isMuted) 0f else 1f)
                result.success(null)
            }
            "setLooping" -> {
                val looping = call.argument<Boolean>("looping") ?: false
                mediaPlayer?.isLooping = looping
                result.success(null)
            }
            "getCurrentPosition" -> {
                result.success(videoView.currentPosition)
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun dispose() {
        videoView.stopPlayback()
        mediaPlayer = null
        channel.setMethodCallHandler(null)
    }
}
