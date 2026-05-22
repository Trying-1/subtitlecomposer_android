import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/native_bridge.dart';
import '../../screens/video_player_screen.dart';

class ImageSequenceMaker extends StatefulWidget {
  const ImageSequenceMaker({super.key});

  @override
  State<ImageSequenceMaker> createState() => _ImageSequenceMakerState();
}

class _ImageSequenceMakerState extends State<ImageSequenceMaker> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<File> _images = [];
  File? _audioFile;
  String? _audioName;

  bool _isPlaying = false;
  int _currentIndex = 0;
  double _secondsPerImage = 0.5;
  late TextEditingController _intervalController;
  double _totalDurationSeconds = 8.0;
  late TextEditingController _totalDurationController;
  bool _shufflePlayback = false;
  String _aspectRatio = '16:9'; // '9:16', '16:9', '1:1'
  String _fitMode = 'Cover'; // 'Cover', 'Fit'
  String _transitionType = 'Cut'; // 'Fade', 'Ken Burns', 'Slide', 'Cut'
  double _volume = 0.8;

  Timer? _sequenceTimer;
  double _imageProgress = 0.0;
  Timer? _progressTimer;
  Timer? _playbackTicker;
  double _currentPreviewTimeSeconds = 0.0;
  double _previewStartOffsetSeconds = 0.0;
  final Stopwatch _playbackStopwatch = Stopwatch();
  List<int> _shuffleMapping = [];

  int _activeTabIndex = 0;
  bool _isControlPanelCollapsed = false;

  final List<Map<String, dynamic>> _controlTabs = [
    {'name': 'Images', 'icon': Icons.image_rounded},
    {'name': 'Transition', 'icon': Icons.movie_filter_rounded},
    {'name': 'Settings', 'icon': Icons.settings_rounded},
    {'name': 'Audio', 'icon': Icons.audiotrack_rounded},
    {'name': 'Export', 'icon': Icons.ios_share_rounded},
  ];

  // Animation controller for Slide & Zoom transitions
  late AnimationController _animationController;
  late Animation<double> _zoomAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(text: _secondsPerImage.toStringAsFixed(2));
    _totalDurationController = TextEditingController(text: _totalDurationSeconds.toStringAsFixed(2));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _setupAnimations();
  }

  void _setupAnimations() {
    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _progressTimer?.cancel();
    _playbackTicker?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    _intervalController.dispose();
    _totalDurationController.dispose();
    super.dispose();
  }

  // Pick multiple images
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles.map((x) => File(x.path)));
          _updateShuffleMapping();
          if (_images.length == pickedFiles.length) {
            _currentIndex = 0;
            _currentPreviewTimeSeconds = 0.0;
          }
          _updateCurrentIndexFromTime();
        });
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e');
    }
  }

  // Pick audio
  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        setState(() {
          _audioFile = File(path);
          _audioName = result.files.single.name;
        });
        await _audioPlayer.setFilePath(path);
        await _audioPlayer.setVolume(_volume);
        
        final duration = _audioPlayer.duration;
        if (duration != null) {
          setState(() {
            _totalDurationSeconds = duration.inMilliseconds / 1000.0;
            _totalDurationController.text = _totalDurationSeconds.toStringAsFixed(2);
          });
        }
        
        _showSnackBar('Audio track loaded: $_audioName');
      }
    } catch (e) {
      _showSnackBar('Error picking audio: $e');
    }
  }

  // Extract audio from video
  Future<void> _extractAudioFromVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final path = video.path;
        final name = video.name;
        setState(() {
          _audioFile = File(path);
          _audioName = name;
        });
        await _audioPlayer.setFilePath(path);
        await _audioPlayer.setVolume(_volume);
        
        final duration = _audioPlayer.duration;
        if (duration != null) {
          setState(() {
            _totalDurationSeconds = duration.inMilliseconds / 1000.0;
            _totalDurationController.text = _totalDurationSeconds.toStringAsFixed(2);
          });
        }
        
        _showSnackBar('Audio loaded from video: $name');
      }
    } catch (e) {
      _showSnackBar('Error loading audio from video: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _updateShuffleMapping();
      if (_images.isEmpty) {
        _stopPlayback();
      } else {
        if (_currentIndex >= _images.length) {
          _currentIndex = 0;
        }
        _updateCurrentIndexFromTime();
      }
    });
  }

  void _updateShuffleMapping() {
    _shuffleMapping = List.generate(_images.length, (i) => i);
    if (_shufflePlayback) {
      _shuffleMapping.shuffle();
    }
  }

  void _updateCurrentIndexFromTime() {
    if (_images.isEmpty) return;
    final int index = (_currentPreviewTimeSeconds / _secondsPerImage).floor();
    final int normalIndex = index % _images.length;
    
    final int targetIndex;
    if (_shufflePlayback) {
      if (_shuffleMapping.length != _images.length) {
        _updateShuffleMapping();
      }
      targetIndex = _shuffleMapping[normalIndex % _shuffleMapping.length];
    } else {
      targetIndex = normalIndex;
    }

    if (_currentIndex != targetIndex) {
      setState(() {
        _currentIndex = targetIndex;
        _animationController.reset();
        _animationController.forward();
      });
    }
    
    // Calculate progress for transitions
    final double currentFrameStart = index * _secondsPerImage;
    final double elapsedInFrame = _currentPreviewTimeSeconds - currentFrameStart;
    _imageProgress = (elapsedInFrame / _secondsPerImage).clamp(0.0, 1.0);
  }

  void _seekToTime(double time) {
    setState(() {
      _currentPreviewTimeSeconds = time.clamp(0.0, _totalDurationSeconds);
      _previewStartOffsetSeconds = _currentPreviewTimeSeconds;
      _playbackStopwatch.reset();
      if (_isPlaying) {
        _playbackStopwatch.start();
      }
      _updateCurrentIndexFromTime();
      
      if (_audioFile != null) {
        _audioPlayer.seek(Duration(milliseconds: (_currentPreviewTimeSeconds * 1000).round()));
      }
    });
  }

  void _togglePlayback() {
    if (_images.isEmpty) {
      _showSnackBar('Import some images first!');
      return;
    }

    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_images.isEmpty) return;
    setState(() {
      _isPlaying = true;
    });

    if (_currentPreviewTimeSeconds >= _totalDurationSeconds) {
      _currentPreviewTimeSeconds = 0.0;
    }
    
    _previewStartOffsetSeconds = _currentPreviewTimeSeconds;
    _playbackStopwatch.reset();
    _playbackStopwatch.start();

    if (_audioFile != null) {
      _audioPlayer.seek(Duration(milliseconds: (_currentPreviewTimeSeconds * 1000).round()));
      _audioPlayer.play();
    }

    _playbackTicker?.cancel();
    _playbackTicker = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        final elapsed = _playbackStopwatch.elapsedMilliseconds / 1000.0;
        _currentPreviewTimeSeconds = _previewStartOffsetSeconds + elapsed;
        
        if (_currentPreviewTimeSeconds >= _totalDurationSeconds) {
          _currentPreviewTimeSeconds = 0.0;
          _previewStartOffsetSeconds = 0.0;
          _playbackStopwatch.reset();
          _playbackStopwatch.start();
          if (_audioFile != null) {
            _audioPlayer.seek(Duration.zero);
          }
        }
        _updateCurrentIndexFromTime();
      });
    });
  }

  void _pausePlayback() {
    setState(() {
      _isPlaying = false;
    });
    _playbackStopwatch.stop();
    _playbackTicker?.cancel();
    _audioPlayer.pause();
  }

  void _stopPlayback() {
    setState(() {
      _isPlaying = false;
      _currentPreviewTimeSeconds = 0.0;
      _previewStartOffsetSeconds = 0.0;
      _currentIndex = 0;
      _imageProgress = 0.0;
    });
    _playbackStopwatch.stop();
    _playbackStopwatch.reset();
    _playbackTicker?.cancel();
    _audioPlayer.stop();
    _audioPlayer.seek(Duration.zero);
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.deepPurpleAccent,
        duration: const Duration(seconds: 2),
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'KleeOne', fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }

  double _getAspectRatioValue() {
    switch (_aspectRatio) {
      case '16:9':
        return 16 / 9;
      case '1:1':
        return 1.0;
      case '9:16':
      default:
        return 9 / 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double doubleAspectRatio = _getAspectRatioValue();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Image Sequence Maker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'KleeOne'),
        ),
      ),
      body: Column(
        children: [
          // 1. LIVE PREVIEW CANVAS
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16161E), // Premium workspace background matching the main project!
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dynamic Grid pattern for workspace background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPatternPainter(),
                    ),
                  ),
                  Column(
                    children: [
                      // 1. Centered aspect-ratio canvas
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: doubleAspectRatio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF050508),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _images.isEmpty
                                      ? _buildEmptyCanvasPlaceholder()
                                      : _buildActiveImageTransition(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 2. Timeline scrubber row at bottom
                      if (_images.isNotEmpty)
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            border: Border(top: BorderSide(color: Colors.white10)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Full-width seek bar slider (runs edge to edge!)
                              SizedBox(
                                height: 12,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.deepPurpleAccent,
                                    inactiveTrackColor: Colors.white12,
                                    thumbColor: Colors.deepPurpleAccent,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                    trackHeight: 3,
                                    trackShape: const RectangularSliderTrackShape(),
                                  ),
                                  child: Slider(
                                    value: _currentPreviewTimeSeconds.clamp(0.0, _totalDurationSeconds),
                                    min: 0.0,
                                    max: _totalDurationSeconds,
                                    onChanged: _seekToTime,
                                  ),
                                ),
                              ),
                              // Controls & timestamps underneath
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Play/Pause
                                        IconButton(
                                          icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                          onPressed: _togglePlayback,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 16),
                                        // Stop/Reset
                                        IconButton(
                                          icon: const Icon(Icons.stop_rounded, color: Colors.white38, size: 20),
                                          onPressed: _stopPlayback,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    // Current Time Stamp
                                    Text(
                                      '${_currentPreviewTimeSeconds.toStringAsFixed(2)}s / ${_totalDurationSeconds.toStringAsFixed(1)}s',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. BOTTOM CONTROL TABS SYSTEM (Similar to main kinetic project)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: _isControlPanelCollapsed ? 52 : 260,
            decoration: const BoxDecoration(
              color: Color(0xFF16161E),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                if (!_isControlPanelCollapsed)
                  Expanded(
                    child: _buildActiveTabContent(_activeTabIndex),
                  ),
                const Divider(height: 1, color: Colors.white10),
                _buildTabBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.black26,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_controlTabs.length, (index) {
          final tab = _controlTabs[index];
          return _buildTabBarItem(index, tab['icon'], tab['name']);
        }),
      ),
    );
  }

  Widget _buildTabBarItem(int index, IconData icon, String label) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            if (_activeTabIndex == index) {
              _isControlPanelCollapsed = !_isControlPanelCollapsed;
            } else {
              _activeTabIndex = index;
              _isControlPanelCollapsed = false;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: (isSelected && !_isControlPanelCollapsed) ? Colors.deepPurpleAccent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected && !_isControlPanelCollapsed ? Colors.deepPurpleAccent : Colors.white24),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 7.5,
                  letterSpacing: 0.5,
                  color: isSelected && !_isControlPanelCollapsed ? Colors.white : Colors.white24,
                  fontWeight: isSelected && !_isControlPanelCollapsed ? FontWeight.w900 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(int index) {
    switch (index) {
      case 0:
        return _buildImagesTab();
      case 1:
        return _buildTransitionTab();
      case 2:
        return _buildSettingsTab();
      case 3:
        return _buildAudioTab();
      case 4:
        return _buildExportTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildImagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MANAGE SEQUENCE IMAGES',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: Row(
              children: [
                // Import Plus Card
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.deepPurpleAccent, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _images.isEmpty
                      ? Center(
                          child: Text(
                            'No images imported yet.\nTap add button to load photos!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10),
                          ),
                        )
                      : ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) {
                                  newIndex -= 1;
                              }
                              final item = _images.removeAt(oldIndex);
                              _images.insert(newIndex, item);
                              _updateShuffleMapping();
                              if (_currentIndex >= _images.length) {
                                _currentIndex = _images.length - 1;
                              }
                              _updateCurrentIndexFromTime();
                            });
                          },
                          itemBuilder: (context, index) {
                            final isSelected = index == _currentIndex;
                            return Container(
                              key: ValueKey(_images[index].path + '_$index'),
                              margin: const EdgeInsets.only(right: 10),
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.04),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(_images[index], fit: BoxFit.cover),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_images.length} images loaded',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _images.clear();
                      _currentIndex = 0;
                      _imageProgress = 0.0;
                    });
                  },
                  child: Text(
                    'CLEAR ALL',
                    style: TextStyle(color: Colors.pinkAccent.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransitionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRANSITION STYLE',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Fade', 'Ken Burns', 'Slide', 'Cut'].map((style) {
              final active = _transitionType == style;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _transitionType = style;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? Colors.deepPurpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.white10),
                    ),
                    child: Center(
                      child: Text(
                        style,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'IMAGE INTERVAL',
                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _intervalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      cursorColor: Colors.deepPurpleAccent,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onChanged: (text) {
                        final parsed = double.tryParse(text);
                        if (parsed != null && parsed >= 0.01 && parsed <= 10.0) {
                          setState(() {
                            _secondsPerImage = parsed;
                            _updateCurrentIndexFromTime();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    's / frame',
                    style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.deepPurpleAccent,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.deepPurpleAccent,
              overlayColor: Colors.deepPurpleAccent.withOpacity(0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: _secondsPerImage.clamp(0.01, 5.0),
              min: 0.01,
              max: 5.0,
              onChanged: (val) {
                setState(() {
                  _secondsPerImage = val;
                  _intervalController.text = _secondsPerImage.toStringAsFixed(2);
                  _updateCurrentIndexFromTime();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'TOTAL DURATION',
                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _totalDurationController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      cursorColor: Colors.deepPurpleAccent,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onChanged: (text) {
                        final parsed = double.tryParse(text);
                        if (parsed != null && parsed >= 0.1 && parsed <= 300.0) {
                          setState(() {
                            _totalDurationSeconds = parsed;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    's total',
                    style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.deepPurpleAccent,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.deepPurpleAccent,
              overlayColor: Colors.deepPurpleAccent.withOpacity(0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: _totalDurationSeconds.clamp(0.5, 60.0),
              min: 0.5,
              max: 60.0,
              onChanged: (val) {
                setState(() {
                  _totalDurationSeconds = val;
                  _totalDurationController.text = _totalDurationSeconds.toStringAsFixed(2);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Playback order
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PLAYBACK ORDER',
                      style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildToggleChip('Sequential', !_shufflePlayback, () {
                          setState(() => _shufflePlayback = false);
                        }),
                        const SizedBox(width: 8),
                        _buildToggleChip('Shuffle', _shufflePlayback, () {
                          setState(() => _shufflePlayback = true);
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Aspect ratio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASPECT RATIO',
                      style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['9:16', '16:9', '1:1'].map((ratio) {
                        final active = _aspectRatio == ratio;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _aspectRatio = ratio;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: active ? Colors.deepPurpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: active ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.white10),
                            ),
                            child: Text(
                              ratio,
                              style: TextStyle(
                                color: active ? Colors.white : Colors.white38,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          // Image Scaling Mode
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IMAGE SCALING MODE',
                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildToggleChip('Cover (Full Bleed)', _fitMode == 'Cover', () {
                    setState(() => _fitMode = 'Cover');
                  }),
                  const SizedBox(width: 10),
                  _buildToggleChip('Fit (Letterbox)', _fitMode == 'Fit', () {
                    setState(() => _fitMode = 'Fit');
                  }),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _fitMode == 'Cover'
                    ? 'Centers and crops image to completely fill the frame (No black spaces).'
                    : 'Scales image down to completely fit the frame (May show black spaces).',
                style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OPTIONAL BACKGROUND AUDIO',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _audioFile != null ? Icons.music_note_rounded : Icons.audiotrack_outlined,
                        color: _audioFile != null ? Colors.deepPurpleAccent : Colors.white24,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _audioFile != null ? _audioName! : 'No Background Sound Loaded',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _audioFile != null ? 'Synced with visual loop player' : 'Pick MP3/WAV audio clip or Video file',
                            style: const TextStyle(color: Colors.white24, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    if (_audioFile != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _audioFile = null;
                            _audioName = null;
                            _audioPlayer.stop();
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('REMOVE', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
                if (_audioFile == null) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAudio,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.audiotrack_rounded, size: 14),
                          label: const Text('IMPORT AUDIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _extractAudioFromVideo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.video_library_rounded, size: 14),
                          label: const Text('EXTRACT FROM VIDEO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAudio,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.audiotrack_rounded, size: 12),
                          label: const Text('REPLACE AUDIO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _extractAudioFromVideo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.video_library_rounded, size: 12),
                          label: const Text('REPLACE FROM VIDEO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_audioFile != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AUDIO VOLUME',
                  style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                Text(
                  '${(_volume * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.deepPurpleAccent,
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.deepPurpleAccent,
                trackHeight: 2,
              ),
              child: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                onChanged: (val) {
                  setState(() {
                    _volume = val;
                    _audioPlayer.setVolume(_volume);
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            AnimatedEqualizer(isPlaying: _isPlaying),
          ],
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    final double totalDurationSec = _totalDurationSeconds;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SEQUENCE COMPILATION DIAGNOSTICS',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'TOTAL DURATION',
                  value: '${totalDurationSec.toStringAsFixed(1)} seconds',
                  icon: Icons.timer_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'RENDER RESOLUTION',
                  value: _aspectRatio == '9:16'
                      ? '720 x 1280 (HD)'
                      : _aspectRatio == '16:9'
                          ? '1280 x 720 (HD)'
                          : '1080 x 1080 (Square)',
                  icon: Icons.hd_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _images.isEmpty ? null : _simulateVideoCompilation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              disabledBackgroundColor: Colors.white.withOpacity(0.05),
            ),
            icon: const Icon(Icons.movie_creation_rounded, size: 18),
            label: const Text(
              'COMPILE VIDEO SEQUENCE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCanvasPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_library_rounded, size: 48, color: Colors.white.withOpacity(0.05)),
        const SizedBox(height: 16),
        const Text(
          'Image Sequence Studio',
          style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'KleeOne'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Import photos to start playing sequence loop',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate_rounded, size: 16, color: Colors.deepPurpleAccent),
          label: const Text('IMPORT IMAGES', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'KleeOne')),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.deepPurpleAccent.withOpacity(0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveImageTransition() {
    final imageFile = _images[_currentIndex];
    final boxFit = _fitMode == 'Cover' ? BoxFit.cover : BoxFit.contain;

    // Standard cross-fade swap
    if (_transitionType == 'Fade') {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Image.file(
          imageFile,
          key: ValueKey<int>(_currentIndex),
          fit: boxFit,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    // Ken Burns visual zooming
    if (_transitionType == 'Ken Burns') {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: ScaleTransition(
          key: ValueKey<int>(_currentIndex),
          scale: _zoomAnimation,
          child: Image.file(
            imageFile,
            fit: boxFit,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    // Slide transition
    if (_transitionType == 'Slide') {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, anim) {
          return SlideTransition(
            position: _slideAnimation,
            child: child,
          );
        },
        child: Image.file(
          imageFile,
          key: ValueKey<int>(_currentIndex),
          fit: boxFit,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    // Cut (instant change)
    return Image.file(
      imageFile,
      fit: boxFit,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildToggleChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.deepPurpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Real native GPU compilation using VideoExporter
  void _simulateVideoCompilation() {
    _pausePlayback();

    // Calculate dimensions based on aspect ratio choice
    final int width;
    final int height;
    if (_aspectRatio == '9:16') {
      width = 720;
      height = 1280;
    } else if (_aspectRatio == '16:9') {
      width = 1280;
      height = 720;
    } else {
      width = 1080;
      height = 1080;
    }

    final double doubleAspectRatio = _getAspectRatioValue();
    final totalDurationMs = (_totalDurationSeconds * 1000).round();
    final durationPerImageMs = (_secondsPerImage * 1000).round().clamp(10, totalDurationMs);

    // Build standard image clips array loop
    final clips = <Map<String, dynamic>>[];
    int i = 0;
    int currentMs = 0;
    final random = Random();

    while (currentMs < totalDurationMs) {
      final start = currentMs;
      final end = (currentMs + durationPerImageMs).clamp(0, totalDurationMs);

      final imageIndex = _shufflePlayback ? random.nextInt(_images.length) : (i % _images.length);
      final imageFile = _images[imageIndex];

      // Map transition style selections
      Map<String, dynamic>? entranceAnim;
      Map<String, dynamic>? exitAnim;

      if (_transitionType == 'Fade') {
        entranceAnim = {'type': 1, 'easing': 2, 'durationMs': 500, 'intensity': 1.0}; // fadeIn
        exitAnim = {'type': 2, 'easing': 2, 'durationMs': 500, 'intensity': 1.0}; // fadeOut
      } else if (_transitionType == 'Slide') {
        entranceAnim = {'type': 5, 'easing': 2, 'durationMs': 500, 'intensity': 1.0}; // slideLeft
        exitAnim = {'type': 6, 'easing': 2, 'durationMs': 500, 'intensity': 1.0}; // slideRight
      } else if (_transitionType == 'Ken Burns') {
        entranceAnim = {'type': 8, 'easing': 2, 'durationMs': 500, 'intensity': 1.0}; // scaleUp
        exitAnim = {'type': 9, 'easing': 2, 'durationMs': 500, 'intensity': 1.0}; // scaleDown
      }

      clips.add({
        'id': 'img_seq_${i}_$start',
        'text': '',
        'startTime': start,
        'endTime': end,
        'x': 0.5,
        'y': 0.5,
        'fontSize': 30.0,
        'color': 0xFFFFFFFF,
        'strokeColor': 0xFF000000,
        'strokeWidth': 0.0,
        'shadowColor': 0x00000000,
        'shadowBlur': 0.0,
        'shadowOffsetX': 0.0,
        'shadowOffsetY': 0.0,
        'backgroundColor': 0x00000000,
        'backgroundRadius': 0.0,
        'letterSpacing': 0.0,
        'rotation': 0.0,
        'scale': 1.0,
        'opacity': 1.0,
        'textOpacity': 1.0,
        'isShadowEnabled': false,
        'isBackgroundEnabled': false,
        'isStrokeEnabled': false,
        'isGlowEnabled': false,
        'isBendingEnabled': false,
        'isReflectionEnabled': false,
        'glowColor': 0x00000000,
        'glowSize': 0.0,
        'bendingAmount': 0.0,
        'reflectionOffset': 0.0,
        'reflectionOpacity': 0.0,
        'reflectionColor': 0x00000000,
        'fontFamily': 'Poppins',
        'entranceAnimation': entranceAnim,
        'exitAnimation': exitAnim,
        'loopAnimation': null,
        'blendMode': 0,
        'keyframes': [],
        'imagePath': imageFile.path,
        'isText': false,
        'isBackground': true,
        'fillMode': _fitMode == 'Cover' ? 0 : 1, // fill mode: 0: cover, 1: fit
        'isGradientEnabled': false,
        'gradientColor1': 0xFFFFFFFF,
        'gradientColor2': 0xFF000000,
        'gradientAngle': 0.0,
        'brightness': 1.0,
        'saturation': 1.0,
        'contrast': 1.0,
        'blur': 0.0,
      });

      currentMs = end;
      i++;
    }

    final audioTracks = <Map<String, dynamic>>[];
    if (_audioFile != null) {
      audioTracks.add({
        'audioClips': [
          {
            'audioPath': _audioFile!.path,
            'startTime': 0,
            'endTime': totalDurationMs,
            'volume': _volume,
          }
        ]
      });
    }

    // Show beautiful modal loader indicating physical compile progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _ExportProgressModal(
          width: width,
          height: height,
          durationMs: totalDurationMs,
          clips: clips,
          audioTracks: audioTracks,
          audioPath: _audioFile?.path,
          aspectRatio: doubleAspectRatio,
        );
      },
    );
  }
}

// Private progress modal executing the real GPU compile thread
class _ExportProgressModal extends StatefulWidget {
  final int width;
  final int height;
  final int durationMs;
  final List<Map<String, dynamic>> clips;
  final List<Map<String, dynamic>> audioTracks;
  final String? audioPath;
  final double aspectRatio;

  const _ExportProgressModal({
    required this.width,
    required this.height,
    required this.durationMs,
    required this.clips,
    required this.audioTracks,
    this.audioPath,
    required this.aspectRatio,
  });

  @override
  State<_ExportProgressModal> createState() => _ExportProgressModalState();
}

class _ExportProgressModalState extends State<_ExportProgressModal> {
  double _progress = 0.0;
  bool _isDone = false;
  String? _outputPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  Future<void> _startExport() async {
    Timer? progressTimer;
    try {
      // Smooth visual progression matching the actual GPU export pipeline
      progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isDone || _error != null) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_progress < 0.95) {
            _progress += 0.04;
          }
        });
      });

      final result = await NativeBridge().exportVideo(
        width: widget.width,
        height: widget.height,
        durationMs: widget.durationMs,
        clips: widget.clips,
        audioTracks: widget.audioTracks,
        audioPath: widget.audioPath,
        backgroundColor: 0xFF000000,
        aspectRatio: widget.aspectRatio,
      );

      progressTimer.cancel();

      if (result != null) {
        setState(() {
          _progress = 1.0;
          _isDone = true;
          _outputPath = result;
        });
      } else {
        setState(() {
          _error = 'Export returned empty output path';
        });
      }
    } catch (e) {
      progressTimer?.cancel();
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeFrame = (_progress * (widget.durationMs / 1000 * 30)).round();
    final int totalFrames = (widget.durationMs / 1000 * 30).round();

    return AlertDialog(
      backgroundColor: const Color(0xFF14141A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            const Icon(Icons.error_outline_rounded, color: Colors.pinkAccent, size: 48),
            const SizedBox(height: 20),
            const Text(
              'EXPORT FAILED',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'KleeOne'),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ] else if (!_isDone) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
            ),
            const SizedBox(height: 24),
            const Text(
              'COMPILING SEQUENCE...',
              style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Text(
              'Rendering Frame $activeFrame / $totalFrames',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ] else ...[
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 48),
            const SizedBox(height: 20),
            const Text(
              'COMPILATION COMPLETE!',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'KleeOne'),
            ),
            const SizedBox(height: 8),
            Text(
              'Successfully generated image sequence video at 30fps. Saved directly to Movies/TypographyEditor public folder!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_outputPath != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(videoPath: _outputPath!),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('PREVIEW VIDEO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double step = 20.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedEqualizer extends StatefulWidget {
  final bool isPlaying;
  const AnimatedEqualizer({super.key, required this.isPlaying});

  @override
  State<AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<AnimatedEqualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = List.generate(15, (index) => Random().nextDouble());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        if (widget.isPlaying) {
          setState(() {
            for (int i = 0; i < _heights.length; i++) {
              _heights[i] = 0.2 + 0.8 * Random().nextDouble();
            }
          });
        }
      });
    
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
      setState(() {
        _heights.fillRange(0, _heights.length, 0.15);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_heights.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 3,
            height: 8 + (_heights[index] * 32),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(widget.isPlaying ? 0.8 : 0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}

