import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/asset_provider.dart';
import '../../providers/font_provider.dart';
import '../../widgets/common/custom_color_picker.dart';
import '../../services/native_bridge.dart';
import '../../services/ads/ad_service.dart';
import '../../screens/video_player_screen.dart';

class FontSequenceMaker extends StatefulWidget {
  const FontSequenceMaker({super.key});

  @override
  State<FontSequenceMaker> createState() => _FontSequenceMakerState();
}

class _FontSequenceMakerState extends State<FontSequenceMaker> with SingleTickerProviderStateMixin {
  // Kinetic Font Sequence State
  String _customText = 'KINETIC';
  double _fontSize = 110.0;
  Color _textColor = Colors.white;
  Color _canvasBgColor = const Color(0xFF0A0A0E);
  bool _isPlaying = false;
  int _currentIndex = 0;
  double _secondsPerFont = 0.3;
  late TextEditingController _intervalController;
  double _totalDurationSeconds = 8.0;
  late TextEditingController _totalDurationController;
  bool _shufflePlayback = false;
  String _firstFont = 'Poppins';
  int _fontsSubTabIndex = 0;
  String _aspectRatio = '16:9'; // '9:16', '16:9', '1:1'
  String _transitionType = 'Cut'; // 'Cut', 'Fade', 'Ken Burns', 'Slide'
  double _volume = 0.8;

  // Selected Font loop sequence (User-managed, reorderable!)
  List<String> _selectedFonts = [
    'LuckiestGuy',
    'Lacquer',
    'ProtestRevolution',
    'NewRocker',
    'Poppins',
    'KleeOne'
  ];

  // ImagePicker for dynamic video audio extraction
  final ImagePicker _picker = ImagePicker();

  // Scrubbable timeline seeker properties
  Timer? _playbackTicker;
  double _currentPreviewTimeSeconds = 0.0;
  double _previewStartOffsetSeconds = 0.0;
  final Stopwatch _playbackStopwatch = Stopwatch();
  List<int> _shuffleMapping = [];

  // Active Control Panel navigation
  int _activeTabIndex = 0;
  bool _isControlPanelCollapsed = false;

  final List<Map<String, dynamic>> _controlTabs = [
    {'name': 'Text', 'icon': Icons.text_fields_rounded},
    {'name': 'Fonts Loop', 'icon': Icons.font_download_rounded},
    {'name': 'Transition', 'icon': Icons.movie_filter_rounded},
    {'name': 'Settings', 'icon': Icons.settings_rounded},
    {'name': 'Audio', 'icon': Icons.audiotrack_rounded},
    {'name': 'Export', 'icon': Icons.ios_share_rounded},
  ];

  // Transitions controller
  late AnimationController _animationController;
  late Animation<double> _zoomAnimation;
  late Animation<Offset> _slideAnimation;

  // Background Audio State
  File? _audioFile;
  String? _audioFileName;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(text: _secondsPerFont.toStringAsFixed(2));
    _totalDurationController = TextEditingController(text: _totalDurationSeconds.toStringAsFixed(2));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _setupAnimations();
  }

  void _setupAnimations() {
    _zoomAnimation = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _playbackTicker?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    _intervalController.dispose();
    _totalDurationController.dispose();
    super.dispose();
  }

  // Shuffle loops helper
  void _updateShuffleMapping() {
    _shuffleMapping = List.generate(_selectedFonts.length, (i) => i);
    if (_shufflePlayback) {
      _shuffleMapping.shuffle();
    }
  }

  void _updateCurrentIndexFromTime() {
    final int index = (_currentPreviewTimeSeconds / _secondsPerFont).floor();
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        _animationController.reset();
        _animationController.forward();
      });
    }
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
    if (_selectedFonts.isEmpty) {
      _showSnackBar('Select at least one font first!');
      return;
    }

    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_selectedFonts.isEmpty) return;
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
          'Font Sequence Studio',
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
                color: const Color(0xFF16161E),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPatternPainter(),
                    ),
                  ),
                  Column(
                    children: [
                      // Centered Canvas Box forced to aspect ratio
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: doubleAspectRatio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _canvasBgColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final previewHeight = constraints.maxHeight;
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _selectedFonts.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'ADD FONTS TO LOOP',
                                                style: TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          : _buildActiveFontText(previewHeight),
                                    ],
                                  );
                                }
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Full-width seek timeline
                      if (_selectedFonts.isNotEmpty)
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            border: Border(top: BorderSide(color: Colors.white10)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                          onPressed: _togglePlayback,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: const Icon(Icons.stop_rounded, color: Colors.white38, size: 20),
                                          onPressed: _stopPlayback,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
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

          // 2. BOTTOM CONTROL TABS SYSTEM (Similar to image sequence maker)
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
                    child: Container(
                      color: const Color(0xFF14141C),
                      child: _buildActiveTabContent(),
                    ),
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

  List<String> _getAllAvailableFonts() {
    final fontProvider = Provider.of<FontProvider>(context, listen: false);
    final defaultFonts = [
      'Poppins', 'Bellota', 'BhuTukaExpandedOne', 'Bokor', 'BungeeHairline',
      'Caramel', 'Explora', 'GrandifloraOne', 'KleeOne', 'Lacquer',
      'LibreBarcode39Text', 'LuckiestGuy', 'MajorMonoDisplay', 'Metrophobic',
      'Michroma', 'NewRocker', 'NewTegomin', 'ProtestRevolution',
    ];
    final customFonts = fontProvider.customFonts.map((f) => f.family).toList();
    return [...defaultFonts, ...customFonts];
  }

  String _getFontForIndex(int index, List<String> allFonts) {
    if (index == 0) {
      return _firstFont;
    } else {
      if (_selectedFonts.isEmpty) return _firstFont;
      final rand = Random(index);
      return _selectedFonts[rand.nextInt(_selectedFonts.length)];
    }
  }

  // Active loop renderer helper
  Widget _buildActiveFontText(double previewHeight) {
    final fontName = _getFontForIndex(_currentIndex, _getAllAvailableFonts());

    final double exportHeight;
    if (_aspectRatio == '9:16') {
      exportHeight = 1280;
    } else if (_aspectRatio == '16:9') {
      exportHeight = 720;
    } else {
      exportHeight = 1080;
    }

    final scaledSize = _fontSize * (previewHeight / exportHeight);

    if (_transitionType == 'Fade') {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Text(
          _customText,
          key: ValueKey<int>(_currentIndex),
          style: TextStyle(fontFamily: fontName, fontSize: scaledSize, color: _textColor),
        ),
      );
    }

    if (_transitionType == 'Ken Burns') {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: ScaleTransition(
          key: ValueKey<int>(_currentIndex),
          scale: _zoomAnimation,
          child: Text(
            _customText,
            style: TextStyle(fontFamily: fontName, fontSize: scaledSize, color: _textColor),
          ),
        ),
      );
    }

    if (_transitionType == 'Slide') {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, anim) {
          return SlideTransition(
            position: _slideAnimation,
            child: child,
          );
        },
        child: Text(
          _customText,
          key: ValueKey<int>(_currentIndex),
          style: TextStyle(fontFamily: fontName, fontSize: scaledSize, color: _textColor),
        ),
      );
    }

    // Cut (instant change)
    return Text(
      _customText,
      style: TextStyle(fontFamily: fontName, fontSize: scaledSize, color: _textColor),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return _buildTextTab();
      case 1:
        return _buildFontsTab();
      case 2:
        return _buildTransitionTab();
      case 3:
        return _buildSettingsTab();
      case 4:
        return _buildAudioTab();
      case 5:
        return _buildExportTab();
      default:
        return const SizedBox();
    }
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
          return _buildTabBarItem(index, tab['icon'] as IconData, tab['name'] as String);
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

  // TAB 1: TEXT SETTINGS
  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CUSTOM TEXT PHRASE', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _customText = val.isEmpty ? 'KINETIC' : val;
                          });
                        },
                        controller: TextEditingController(text: _customText)..selection = TextSelection.collapsed(offset: _customText.length),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: InputBorder.none,
                          hintText: 'Enter text...',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TEXT COLOR', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickColorDialog(true),
                    child: Container(
                      width: 50,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _textColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.colorize_rounded, color: Colors.black38, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CANVAS BG', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickColorDialog(false),
                    child: Container(
                      width: 50,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _canvasBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.colorize_rounded, color: Colors.white38, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FONT SIZE', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
              Text('${_fontSize.toStringAsFixed(0)}px', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
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
              value: _fontSize,
              min: 20,
              max: 250,
              onChanged: (val) {
                setState(() {
                  _fontSize = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _pickColorDialog(bool isTextColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => CustomColorPicker(
        initialColor: isTextColor ? _textColor : _canvasBgColor,
        onColorChanged: (newColor) {
          setState(() {
            if (isTextColor) {
              _textColor = newColor;
            } else {
              _canvasBgColor = newColor;
            }
          });
        },
      ),
    );
  }

  // TAB 2: FONTS SEQUENCE LIST (Interactive available fonts toggle chips with SELECT ALL and First Font Only Mode!)
  // TAB 2: FONTS SEQUENCE LIST (Primary Baseline Font + Subsequent Random Pool)
  Widget _buildSubTabButton({required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 28,
        decoration: BoxDecoration(
          color: isActive ? Colors.deepPurpleAccent.withOpacity(0.12) : Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
            width: isActive ? 1.2 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // TAB 2: FONTS SEQUENCE LIST (Primary Baseline Font + Subsequent Random Pool with Subtabs!)
  Widget _buildFontsTab() {
    final fontProvider = Provider.of<FontProvider>(context);
    final defaultFonts = [
      'Poppins', 'Bellota', 'BhuTukaExpandedOne', 'Bokor', 'BungeeHairline',
      'Caramel', 'Explora', 'GrandifloraOne', 'KleeOne', 'Lacquer',
      'LibreBarcode39Text', 'LuckiestGuy', 'MajorMonoDisplay', 'Metrophobic',
      'Michroma', 'NewRocker', 'NewTegomin', 'ProtestRevolution',
    ];
    final customFonts = fontProvider.customFonts.map((f) => f.family).toList();
    final allFonts = [...defaultFonts, ...customFonts];

    final areAllSelected = _selectedFonts.length == allFonts.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtabs Navigation
          Row(
            children: [
              Expanded(
                child: _buildSubTabButton(
                  title: 'STARTING FONT',
                  isActive: _fontsSubTabIndex == 0,
                  onTap: () => setState(() => _fontsSubTabIndex = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSubTabButton(
                  title: 'LOOPING POOL',
                  isActive: _fontsSubTabIndex == 1,
                  onTap: () => setState(() => _fontsSubTabIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subtab Content
          if (_fontsSubTabIndex == 0) ...[
            const Text(
              'SELECT STARTING / BASELINE FONT',
              style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: allFonts.map((font) {
                      final isSelected = _firstFont == font;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _firstFont = font;
                            _updateCurrentIndexFromTime();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepPurpleAccent.withOpacity(0.12)
                                : Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurpleAccent.withOpacity(0.4)
                                  : Colors.white10,
                            ),
                          ),
                          child: Text(
                            font,
                            style: TextStyle(
                              fontFamily: font,
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 9.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SELECT SUBSEQUENT LOOP POOL',
                  style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (areAllSelected) {
                        _selectedFonts = ['Poppins'];
                      } else {
                        _selectedFonts = allFonts.toList();
                      }
                      _updateCurrentIndexFromTime();
                    });
                  },
                  child: Text(
                    areAllSelected ? 'DESELECT ALL' : 'SELECT ALL',
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: allFonts.map((font) {
                      final isSelected = _selectedFonts.contains(font);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              if (_selectedFonts.length > 1) {
                                _selectedFonts.remove(font);
                              } else {
                                _showSnackBar('Must keep at least one active font in pool!');
                              }
                            } else {
                              _selectedFonts.add(font);
                            }
                            _updateCurrentIndexFromTime();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepPurpleAccent.withOpacity(0.12)
                                : Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurpleAccent.withOpacity(0.4)
                                  : Colors.white10,
                            ),
                          ),
                          child: Text(
                            font,
                            style: TextStyle(
                              fontFamily: font,
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 9.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 3: TRANSITION & EFFECTS
  Widget _buildTransitionTab() {
    final List<Map<String, dynamic>> transitions = [
      {'name': 'Cut', 'desc': 'Instant hard transition', 'icon': Icons.flash_on_rounded},
      {'name': 'Fade', 'desc': 'Smooth opacity blend', 'icon': Icons.blur_on_rounded},
      {'name': 'Ken Burns', 'desc': 'Zoom animation effect', 'icon': Icons.zoom_in_rounded},
      {'name': 'Slide', 'desc': 'Dynamic kinetic slide', 'icon': Icons.swap_horiz_rounded},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: transitions.length,
      itemBuilder: (context, index) {
        final t = transitions[index];
        final active = _transitionType == t['name'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _transitionType = t['name'] as String;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? Colors.deepPurpleAccent.withOpacity(0.05) : Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05), width: active ? 1.5 : 1.0),
            ),
            child: Row(
              children: [
                Icon(t['icon'] as IconData, color: active ? Colors.deepPurpleAccent : Colors.white30, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(t['desc'] as String, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9)),
                    ],
                  ),
                ),
                if (active) const Icon(Icons.check_circle_rounded, color: Colors.deepPurpleAccent, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 4: INTERVAL & GENERAL SETTINGS
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FONT SWITCH DELAY', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextField(
                            controller: _intervalController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onChanged: (text) {
                              final parsed = double.tryParse(text);
                              if (parsed != null && parsed >= 0.01 && parsed <= 10.0) {
                                setState(() {
                                  _secondsPerFont = parsed;
                                  _updateCurrentIndexFromTime();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          's / font',
                          style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL LOOP DURATION', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextField(
                            controller: _totalDurationController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onChanged: (text) {
                              final parsed = double.tryParse(text);
                              if (parsed != null && parsed >= 0.5 && parsed <= 60.0) {
                                setState(() {
                                  _totalDurationSeconds = parsed;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'seconds',
                          style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
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
              value: _secondsPerFont.clamp(0.01, 5.0),
              min: 0.01,
              max: 5.0,
              onChanged: (val) {
                setState(() {
                  _secondsPerFont = val;
                  _intervalController.text = _secondsPerFont.toStringAsFixed(2);
                  _updateCurrentIndexFromTime();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text('ASPECT RATIO FRAME', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRatioChoice('16:9', 'Widescreen'),
              const SizedBox(width: 10),
              _buildRatioChoice('9:16', 'Portrait'),
              const SizedBox(width: 10),
              _buildRatioChoice('1:1', 'Square'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioChoice(String ratio, String label) {
    final active = _aspectRatio == ratio;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _aspectRatio = ratio;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.deepPurpleAccent.withOpacity(0.08) : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Text(ratio, style: TextStyle(color: active ? Colors.white : Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: active ? Colors.white38 : Colors.white24, fontSize: 7)),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 5: AUDIO MANAGEMENT
  Widget _buildAudioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BACKGROUND MUSIC', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              if (_audioFile != null)
                GestureDetector(
                  onTap: _removeAudio,
                  child: const Text('REMOVE AUDIO', style: TextStyle(color: Colors.pinkAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_audioFile == null) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickAudio,
                    icon: const Icon(Icons.music_note_rounded, size: 16),
                    label: const Text('PICK MP3 / WAV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 42),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _extractAudioFromVideo,
                    icon: const Icon(Icons.movie_filter_rounded, size: 16),
                    label: const Text('FROM VIDEO FILE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 42),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.01),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audiotrack_rounded, color: Colors.deepPurpleAccent, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_audioFileName ?? 'Unknown Audio Track', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Synchronized loop duration to audio length!', style: TextStyle(color: Colors.white24, fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          AnimatedEqualizer(isPlaying: _isPlaying),
        ],
      ),
    );
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        _audioPlayer.stop();

        await _audioPlayer.setFilePath(path);
        final duration = _audioPlayer.duration;
        setState(() {
          _audioFile = file;
          _audioFileName = result.files.single.name;
          if (duration != null) {
            _totalDurationSeconds = duration.inMilliseconds / 1000.0;
            _totalDurationController.text = _totalDurationSeconds.toStringAsFixed(2);
          }
        });
        _showSnackBar('Audio track loaded successfully!');
      }
    } catch (e) {
      _showSnackBar('Failed to load audio: $e');
    }
  }

  Future<void> _extractAudioFromVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final path = video.path;
        final name = video.name;
        _audioPlayer.stop();

        await _audioPlayer.setFilePath(path);
        final duration = _audioPlayer.duration;

        setState(() {
          _audioFile = File(path);
          _audioFileName = name;
          if (duration != null) {
            _totalDurationSeconds = duration.inMilliseconds / 1000.0;
            _totalDurationController.text = _totalDurationSeconds.toStringAsFixed(2);
          }
        });
        _showSnackBar('Audio track extracted from video successfully!');
      }
    } catch (e) {
      _showSnackBar('Error loading audio from video: $e');
    }
  }

  void _removeAudio() {
    setState(() {
      _audioFile = null;
      _audioFileName = null;
    });
    _audioPlayer.stop();
  }

  // TAB 6: EXPORT COMPILER
  Widget _buildExportTab() {
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
                  value: '${_totalDurationSeconds.toStringAsFixed(1)} seconds',
                  icon: Icons.timer_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'RESOLUTION',
                  value: _aspectRatio == '9:16'
                      ? '720 x 1280 (HD)'
                      : _aspectRatio == '16:9'
                          ? '1280 x 720 (HD)'
                          : '1080 x 1080',
                  icon: Icons.hd_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'FONTS LOOP',
                  value: '${_selectedFonts.length} selected',
                  icon: Icons.font_download_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'AUDIO TRACK',
                  value: _audioFile != null ? 'Synchronized' : 'None',
                  icon: Icons.music_note_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _startVideoCompilation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.ios_share_rounded, size: 16),
            label: const Text(
              'COMPILE VIDEO LOOP',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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

  void _startVideoCompilation() {
    _pausePlayback();

    AdService.instance.showFontSequenceExportAd(
      onAdDismissed: () {
        _performVideoCompilation();
      },
    );
  }

  void _performVideoCompilation() {
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
    final durationPerFontMs = (_secondsPerFont * 1000).round().clamp(10, totalDurationMs);

    final clips = <Map<String, dynamic>>[];
    int i = 0;
    int currentMs = 0;

    while (currentMs < totalDurationMs) {
      final start = currentMs;
      final end = (currentMs + durationPerFontMs).clamp(0, totalDurationMs);

      final fontName = _getFontForIndex(i, _getAllAvailableFonts());

      Map<String, dynamic>? entranceAnim;
      Map<String, dynamic>? exitAnim;

      if (_transitionType == 'Fade') {
        entranceAnim = {'type': 1, 'easing': 2, 'durationMs': 150, 'intensity': 1.0};
        exitAnim = {'type': 2, 'easing': 2, 'durationMs': 150, 'intensity': 1.0};
      } else if (_transitionType == 'Slide') {
        entranceAnim = {'type': 5, 'easing': 2, 'durationMs': 150, 'intensity': 1.0};
        exitAnim = {'type': 6, 'easing': 2, 'durationMs': 150, 'intensity': 1.0};
      } else if (_transitionType == 'Ken Burns') {
        entranceAnim = {'type': 8, 'easing': 2, 'durationMs': 150, 'intensity': 1.0};
        exitAnim = {'type': 9, 'easing': 2, 'durationMs': 150, 'intensity': 1.0};
      }

      clips.add({
        'id': 'font_seq_${i}_$start',
        'text': _customText,
        'startTime': start,
        'endTime': end,
        'x': 0.5,
        'y': 0.5,
        'fontSize': _fontSize,
        'color': _textColor.value,
        'strokeColor': 0xFF000000,
        'strokeWidth': 0.0,
        'shadowColor': 0x00000000,
        'shadowBlur': 0.0,
        'shadowOffsetX': 0.0,
        'shadowOffsetY': 0.0,
        'backgroundColor': _canvasBgColor.value,
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
        'fontFamily': fontName,
        'entranceAnimation': entranceAnim,
        'exitAnimation': exitAnim,
        'loopAnimation': null,
        'blendMode': 0,
        'keyframes': [],
        'imagePath': '',
        'isText': true,
        'isBackground': false,
        'fillMode': 0,
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ExportProgressModal(
        width: width,
        height: height,
        durationMs: totalDurationMs,
        clips: clips,
        audioTracks: audioTracks,
        audioPath: _audioFile?.path,
        aspectRatio: doubleAspectRatio,
      ),
    );
  }
}

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
  String? _error;
  String? _outputPath;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  Future<void> _startExport() async {
    Timer? progressTimer;
    try {
      progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isDone || _error != null) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_progress < 0.95) {
            _progress += 0.05;
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
                backgroundColor: Colors.white10,
                minimumSize: const Size(120, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ] else if (!_isDone) ...[
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'COMPILING TEXT FONTS...',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'KleeOne'),
            ),
            const SizedBox(height: 8),
            Text(
              'Frame $activeFrame of $totalFrames',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
              ),
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
              'Successfully generated font sequence video at 30fps. Saved directly to Movies/TypographyEditor public folder!',
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
