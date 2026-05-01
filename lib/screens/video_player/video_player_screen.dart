import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'native_video_player_controller.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  NativeVideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isLooping = false;
  int _duration = 0;
  int _position = 0;
  Timer? _positionTimer;
  final ImagePicker _picker = ImagePicker();

  void _onViewCreated(int viewId) {
    _controller = NativeVideoPlayerController(viewId);
    _controller!.onPrepared.listen((duration) {
      setState(() {
        _duration = duration;
      });
      _startPositionTimer();
    });
    
    _controller!.onCompletion.listen((_) {
      if (!_isLooping) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_controller != null && _isPlaying) {
        final pos = await _controller!.getCurrentPosition();
        setState(() {
          _position = pos;
        });
      }
    });
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null && _controller != null) {
      await _controller!.load(video.path);
      setState(() {
        _isPlaying = false;
        _position = 0;
      });
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // Fallback aspect ratio
                    child: Container(
                      color: Colors.black,
                      child: AndroidView(
                        viewType: 'com.example.typgraphyeditor/native_video_player',
                        onPlatformViewCreated: _onViewCreated,
                      ),
                    ),
                  ),
                ),
                // Floating back button since header is removed
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: const Color(0xFF121212),
      child: Row(
        children: [
          // Play/Pause on the left
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
            onPressed: () {
              if (_isPlaying) {
                _controller?.pause();
              } else {
                _controller?.play();
              }
              setState(() => _isPlaying = !_isPlaying);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          
          // Scrubber in the middle
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Colors.blueAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.blueAccent,
                  ),
                  child: Slider(
                    value: _position.toDouble().clamp(0, _duration.toDouble()),
                    max: _duration.toDouble() > 0 ? _duration.toDouble() : 1.0,
                    onChanged: (val) {
                      setState(() {
                        _position = val.toInt();
                      });
                      _controller?.seekTo(val.toInt());
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position), style: const TextStyle(color: Colors.white24, fontSize: 8)),
                      Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white24, fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Mute, Loop, Import on the right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white70, size: 20),
                onPressed: () {
                  setState(() => _isMuted = !_isMuted);
                  _controller?.setMute(_isMuted);
                },
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: Icon(_isLooping ? Icons.loop_rounded : Icons.repeat_rounded, color: _isLooping ? Colors.blueAccent : Colors.white70, size: 20),
                onPressed: () {
                  setState(() => _isLooping = !_isLooping);
                  _controller?.setLooping(_isLooping);
                },
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.video_library_rounded, color: Colors.white70, size: 20),
                onPressed: _pickVideo,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScrubber() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.blueAccent,
          ),
          child: Slider(
            value: _position.toDouble().clamp(0, _duration.toDouble()),
            max: _duration.toDouble() > 0 ? _duration.toDouble() : 1.0,
            onChanged: (val) {
              setState(() {
                _position = val.toInt();
              });
              _controller?.seekTo(val.toInt());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position), style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
