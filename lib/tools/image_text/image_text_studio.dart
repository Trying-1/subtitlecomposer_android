import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../providers/font_provider.dart';
import '../../providers/asset_provider.dart';
import '../../services/native_bridge.dart';
import '../../services/ads/ad_service.dart';
import '../../services/image_text_export_service.dart';
import '../../widgets/common/custom_color_picker.dart';
import '../../config/app_config.dart';

class ImageTextStudio extends StatefulWidget {
  const ImageTextStudio({super.key});

  @override
  State<ImageTextStudio> createState() => _ImageTextStudioState();
}

class _ImageTextStudioState extends State<ImageTextStudio> {
  // GlobalKey to capture high-res canvas repaint boundary
  final GlobalKey _repaintKey = GlobalKey();

  // Control tabs & UI states
  int _activeTabIndex = 0;
  bool _isControlPanelCollapsed = false;
  String _aspectRatio = '9:16'; // '9:16', '16:9', '1:1'
  
  // Background configuration
  String? _bgImagePath;
  Color _canvasBgColor = const Color(0xFF1E1E2C);
  bool _useGradientBg = false;
  Color _gradientEndColor = const Color(0xFF0F0F1A);

  // Overlay text properties
  String _customText = 'Double tap to change';
  late TextEditingController _textOverlayController;
  double _fontSize = 45.0; // Export font size
  double _letterSpacing = 0.0;
  Color _textColor = Colors.white;
  String _selectedFont = 'Poppins';

  // Position & Alignment variables
  double _textX = 0.5; // fractional X offset (0.0 to 1.0)
  double _textY = 0.5; // fractional Y offset (0.0 to 1.0)
  double _rotationAngle = 0.0; // rotation in degrees (-180 to 180)
  bool _enableStroke = false;
  bool _enableShadow = true;

  // Stroke effects
  double _strokeWidth = 2.0; // stroke width (0.0 to 12.0)
  Color _strokeColor = Colors.black;

  // Shadow effects
  Color _shadowColor = Colors.black.withOpacity(0.5);
  double _shadowBlur = 4.0;
  double _shadowOffsetX = 2.0;
  double _shadowOffsetY = 2.0;

  // Background Box effects
  Color _boxColor = Colors.transparent;
  double _boxOpacity = 0.6;
  double _boxPadding = 12.0;
  double _boxRadius = 8.0;

  // Export states
  bool _isCompiling = false;
  String? _exportedImagePath;

  // Persistence Box and Lists
  Box? _projectsBox;
  List<Map<String, dynamic>> _savedProjects = [];

  final List<Map<String, dynamic>> _controlTabs = [
    {'name': 'Image', 'icon': Icons.photo_size_select_actual_rounded},
    {'name': 'Text', 'icon': Icons.font_download_rounded},
    {'name': 'Position', 'icon': Icons.open_with_rounded},
    {'name': 'Effects', 'icon': Icons.auto_awesome_rounded},
    {'name': 'Export', 'icon': Icons.download_done_rounded},
  ];

  final List<Color> _curatedColors = [
    Colors.white,
    Colors.black,
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.amberAccent,
    Colors.lightGreenAccent,
    Colors.greenAccent,
    Colors.cyanAccent,
    Colors.blueAccent,
    Colors.indigoAccent,
    Colors.deepPurpleAccent,
    Colors.pinkAccent,
  ];

  final List<Color> _bgCanvasColors = [
    const Color(0xFF1E1E2C),
    const Color(0xFF0F2027),
    const Color(0xFF2C3E50),
    const Color(0xFF1A1C20),
    const Color(0xFF111111),
    const Color(0xFF3F2B96),
    const Color(0xFF7F00FF),
    const Color(0xFFE94057),
    const Color(0xFFF27121),
  ];

  @override
  void initState() {
    super.initState();
    _textOverlayController = TextEditingController(text: _customText);
    _initHive();
    // Default starting font
    final allFonts = _getAllAvailableFonts();
    if (allFonts.contains('KleeOne')) {
      _selectedFont = 'KleeOne';
    } else if (allFonts.isNotEmpty) {
      _selectedFont = allFonts.first;
    }
  }

  @override
  void dispose() {
    _autoSaveLastActiveProject();
    _textOverlayController.dispose();
    super.dispose();
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

  double _getExportHeight() {
    switch (_aspectRatio) {
      case '16:9':
        return 1080;
      case '1:1':
        return 1080;
      case '9:16':
      default:
        return 1920;
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
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

  Future<void> _pickBackgroundImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _bgImagePath = image.path;
      });
      _showSnackBar('Background image loaded successfully!');
      _autoSaveLastActiveProject();
    }
  }

  void _clearBackgroundImage() {
    setState(() {
      _bgImagePath = null;
    });
    _autoSaveLastActiveProject();
  }

  Future<void> _compileAndExportPoster() async {
    if (_isCompiling) return;
    
    await AdService.instance.showImageTextInterAd(
      onAdDismissed: () async {
        setState(() {
          _isCompiling = true;
        });
        await _performCompileAndExportPoster();
      },
    );
  }

  Future<void> _performCompileAndExportPoster() async {
    try {
      // 1. Give framework extra frame to settle down
      await Future.delayed(const Duration(milliseconds: 200));

      // 2. Locate repaint boundary
      final RenderRepaintBoundary? boundary = 
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Could not find canvas workspace element boundary.");
      }

      // 3. Render high-res image and resize to exact target resolution
      final ui.Image capturedImage = await boundary.toImage(pixelRatio: 4.0);
      
      double targetWidth;
      double targetHeight;
      switch (_aspectRatio) {
        case '16:9':
          targetWidth = 1920;
          targetHeight = 1080;
          break;
        case '1:1':
          targetWidth = 1080;
          targetHeight = 1080;
          break;
        case '9:16':
        default:
          targetWidth = 1080;
          targetHeight = 1920;
          break;
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = Paint()
        ..filterQuality = ui.FilterQuality.high
        ..isAntiAlias = true;

      canvas.drawImageRect(
        capturedImage,
        Rect.fromLTWH(0, 0, capturedImage.width.toDouble(), capturedImage.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth, targetHeight),
        paint,
      );

      final picture = recorder.endRecording();
      final resizedImage = await picture.toImage(targetWidth.toInt(), targetHeight.toInt());
      final ByteData? byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to read captured pixel array bytes.");
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 4. Save to temporary storage directory for sharing
      final tempDir = await getTemporaryDirectory();
      final String exportPath = 
          '${tempDir.path}/poster_${DateTime.now().millisecondsSinceEpoch}.png';
      
      final File file = File(exportPath);
      await file.writeAsBytes(pngBytes);

      // 5. Save to Public Movies/TypographyEditor directory using native MediaStore ContentResolver
      String? publicExportPath;
      if (kIsWeb) {
        // web fallback
      } else {
        if (Platform.isAndroid) {
          try {
            final String? savedUri = await NativeBridge().saveImageToGallery(pngBytes);
            if (savedUri != null) {
              publicExportPath = savedUri;
            }
          } catch (e) {
            debugPrint('Error writing to public gallery: $e');
          }
        }
      }

      setState(() {
        _exportedImagePath = exportPath;
        _isCompiling = false;
      });

      if (publicExportPath != null) {
        _showSnackBar('Poster exported successfully directly to Movies/TypographyEditor!');
      } else {
        _showSnackBar('High-Resolution Poster compiled successfully!');
      }
    } catch (e) {
      setState(() {
        _isCompiling = false;
      });
      _showSnackBar('Export error: $e');
    }
  }

  Future<void> _sharePoster() async {
    if (_exportedImagePath == null) return;
    try {
      await Share.shareXFiles([XFile(_exportedImagePath!)], text: 'My typography poster created with Typo Edit!');
    } catch (e) {
      _showSnackBar('Sharing error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double doubleAspectRatio = _getAspectRatioValue();
    final originalTheme = Theme.of(context);

    return Theme(
      data: originalTheme.copyWith(
        textTheme: originalTheme.textTheme.apply(fontFamily: 'KleeOne'),
        primaryTextTheme: originalTheme.primaryTextTheme.apply(fontFamily: 'KleeOne'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Image Text Studio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'KleeOne'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: Colors.white70),
            tooltip: 'New Project',
            onPressed: _resetToNewProject,
          ),
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Colors.white70),
            tooltip: 'Save Poster Project',
            onPressed: _showSaveProjectDialog,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_rounded, color: Colors.white70),
            tooltip: 'Load Saved Projects',
            onPressed: _showLoadProjectsDialog,
          ),
          IconButton(
            icon: Icon(
              _bgImagePath != null ? Icons.photo_rounded : Icons.photo_outlined, 
              color: _bgImagePath != null ? Colors.deepPurpleAccent : Colors.white60,
            ),
            tooltip: 'Upload background image',
            onPressed: _pickBackgroundImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. LIVE PREVIEW CANVAS WORKSPACE
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
                  // Workspace grid pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPatternPainter(),
                    ),
                  ),
                  // Render aspect ratio locked viewport with capturing boundary
                  Center(
                    child: AspectRatio(
                      aspectRatio: doubleAspectRatio,
                      child: ClipRect(
                        child: RepaintBoundary(
                          key: _repaintKey,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final previewHeight = constraints.maxHeight;
                              final previewWidth = constraints.maxWidth;
                              
                              // Convert fractional positions to local offsets
                              final textLocalX = _textX * previewWidth;
                              final textLocalY = _textY * previewHeight;

                              // UI Font Size Parity Calculation
                              final scaledFontSize = 
                                  _fontSize * (previewHeight / _getExportHeight());

                              return GestureDetector(
                                onPanUpdate: (details) {
                                  // Update fractional coordinate coordinates based on local drag physics
                                  setState(() {
                                    _textX = (_textX + (details.delta.dx / previewWidth)).clamp(0.0, 1.0);
                                    _textY = (_textY + (details.delta.dy / previewHeight)).clamp(0.0, 1.0);
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: _bgImagePath != null ? Colors.transparent : _canvasBgColor,
                                    gradient: (_bgImagePath == null && _useGradientBg)
                                        ? LinearGradient(
                                            colors: [_canvasBgColor, _gradientEndColor],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    image: _bgImagePath != null
                                        ? DecorationImage(
                                            image: FileImage(File(_bgImagePath!)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Render the draggable text component precisely
                                      Positioned(
                                        left: textLocalX,
                                        top: textLocalY,
                                        child: FractionalTranslation(
                                          translation: const Offset(-0.5, -0.5),
                                          child: Transform.rotate(
                                            angle: _rotationAngle * math.pi / 180,
                                            child: GestureDetector(
                                              onDoubleTap: _showTextInputDialog,
                                              child: _buildTextOverlayWidget(scaledFontSize),
                                            ),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. BOTTOM CONTROL PANEL
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
    ),
  );
}

  Widget _buildTextOverlayWidget(double size) {
    return Stack(
      children: [
        // Stroke Outline (rendered behind)
        if (_enableStroke && _strokeWidth > 0)
          Text(
            _customText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _selectedFont,
              fontSize: size,
              fontWeight: FontWeight.bold,
              letterSpacing: _letterSpacing,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = _strokeWidth
                ..color = _strokeColor,
            ),
          ),
        // Filled Text Overlay
        Text(
          _customText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _selectedFont,
            fontSize: size,
            color: _textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: _letterSpacing,
            shadows: _enableShadow
                ? [
                    Shadow(
                      color: _shadowColor,
                      blurRadius: _shadowBlur,
                      offset: Offset(_shadowOffsetX, _shadowOffsetY),
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return _buildImageTab();
      case 1:
        return _buildTextTab();
      case 2:
        return _buildPositionTab();
      case 3:
        return _buildEffectsTab();
      case 4:
        return _buildExportTab();
      default:
        return const SizedBox();
    }
  }

  // TABS IMPLEMENTATION
  
  // 1. IMAGE TAB
  Widget _buildImageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CANVAS ASPECT RATIO',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['9:16', '16:9', '1:1'].map((ratio) {
              final isSel = _aspectRatio == ratio;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _aspectRatio = ratio;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.deepPurpleAccent.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        ratio,
                        style: TextStyle(
                          color: isSel ? Colors.white : Colors.white54,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'BACKGROUND SOURCE',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickBackgroundImage,
                  icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: const Text('PICK BG IMAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.04),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.08)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_bgImagePath != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearBackgroundImage,
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: const Text('REMOVE IMAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_bgImagePath == null) ...[
            const SizedBox(height: 20),
            const Text(
              'SOLID BG PRESET COLORS',
              style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCustomColorPickerButton(
                  currentColor: _canvasBgColor,
                  onColorChanged: (color) {
                    setState(() {
                      _canvasBgColor = color;
                      _useGradientBg = false;
                    });
                  },
                  size: 40.0,
                ),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _bgCanvasColors.length,
                      itemBuilder: (context, index) {
                        final color = _bgCanvasColors[index];
                        final isSel = _canvasBgColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _canvasBgColor = color;
                              _useGradientBg = false;
                            });
                          },
                          child: Container(
                            width: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.deepPurpleAccent : Colors.white24,
                                width: isSel ? 3 : 1,
                              ),
                            ),
                            child: isSel 
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 2. TEXT TAB
  Widget _buildTextTab() {
    final allFonts = _getAllAvailableFonts();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TEXT OVERLAY STRING',
                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              GestureDetector(
                onTap: _showTextInputDialog,
                child: const Text(
                  'EDIT STRING',
                  style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _textOverlayController,
            onChanged: (val) {
              setState(() {
                _customText = val;
              });
            },
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            decoration: InputDecoration(
              hintText: 'Type text overlay here...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withOpacity(0.02),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'FONT SIZE',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: Colors.deepPurpleAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.deepPurpleAccent,
                  ),
                  child: Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 180.0,
                    onChanged: (val) {
                      setState(() {
                        _fontSize = val;
                      });
                    },
                  ),
                ),
              ),
              Text(
                '${_fontSize.toInt()} px',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LETTER SPACING',
                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              Text(
                '${_letterSpacing.toStringAsFixed(1)} px',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: Colors.deepPurpleAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.deepPurpleAccent,
                  ),
                  child: Slider(
                    value: _letterSpacing,
                    min: -5.0,
                    max: 30.0,
                    onChanged: (val) {
                      setState(() {
                        _letterSpacing = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'TEXT COLOR',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
            Row(
              children: [
                _buildCustomColorPickerButton(
                  currentColor: _textColor,
                  onColorChanged: (color) {
                    setState(() {
                      _textColor = color;
                    });
                  },
                  size: 35.0,
                ),
                Expanded(
                  child: SizedBox(
                    height: 35,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _curatedColors.length,
                      itemBuilder: (context, idx) {
                        final c = _curatedColors[idx];
                        final isSel = _textColor == c;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _textColor = c;
                            });
                          },
                          child: Container(
                            width: 35,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.deepPurpleAccent : Colors.white24,
                                width: isSel ? 3 : 1,
                              ),
                            ),
                            child: isSel 
                                ? Icon(Icons.check_rounded, color: c == Colors.white ? Colors.black : Colors.white, size: 14)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          const Text(
            'SELECTED FONT FAMILY',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allFonts.map((font) {
              final isSel = _selectedFont == font;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFont = font;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? Colors.deepPurpleAccent.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSel ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Text(
                    font,
                    style: TextStyle(
                      fontFamily: font,
                      color: isSel ? Colors.white : Colors.white54,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 3. POSITION TAB
  Widget _buildPositionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COORDINATE POSITION SLIDERS',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          // X Slider
          Row(
            children: [
              const SizedBox(width: 45, child: Text('Horizontal', style: TextStyle(color: Colors.white54, fontSize: 10))),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 1.5,
                    activeTrackColor: Colors.deepPurpleAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.deepPurpleAccent,
                  ),
                  child: Slider(
                    value: _textX,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() {
                        _textX = val;
                      });
                    },
                  ),
                ),
              ),
              Text(
                '${(_textX * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Y Slider
          Row(
            children: [
              const SizedBox(width: 45, child: Text('Vertical', style: TextStyle(color: Colors.white54, fontSize: 10))),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 1.5,
                    activeTrackColor: Colors.deepPurpleAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.deepPurpleAccent,
                  ),
                  child: Slider(
                    value: _textY,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() {
                        _textY = val;
                      });
                    },
                  ),
                ),
              ),
              Text(
                '${(_textY * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'ROTATION ANGLE',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 1.5,
                    activeTrackColor: Colors.deepPurpleAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.deepPurpleAccent,
                  ),
                  child: Slider(
                    value: _rotationAngle,
                    min: -180.0,
                    max: 180.0,
                    onChanged: (val) {
                      setState(() {
                        _rotationAngle = val;
                      });
                    },
                  ),
                ),
              ),
              Text(
                '${_rotationAngle.toInt()}°',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'ALIGNMENT GRID PRESETS',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 140,
              height: 100,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildAlignPresetButton('Top-Left', 0.1, 0.1),
                  _buildAlignPresetButton('Top-Center', 0.5, 0.1),
                  _buildAlignPresetButton('Top-Right', 0.9, 0.1),
                  _buildAlignPresetButton('Mid-Left', 0.1, 0.5),
                  _buildAlignPresetButton('Center', 0.5, 0.5),
                  _buildAlignPresetButton('Mid-Right', 0.9, 0.5),
                  _buildAlignPresetButton('Bot-Left', 0.1, 0.9),
                  _buildAlignPresetButton('Bot-Center', 0.5, 0.9),
                  _buildAlignPresetButton('Bot-Right', 0.9, 0.9),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignPresetButton(String tooltip, double x, double y) {
    final isMatching = (_textX - x).abs() < 0.05 && (_textY - y).abs() < 0.05;
    return GestureDetector(
      onTap: () {
        setState(() {
          _textX = x;
          _textY = y;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isMatching ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // 4. EFFECTS TAB
  Widget _buildEffectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STROKE OUTLINE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TEXT OUTLINE STROKE',
                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              Transform.scale(
                scale: 0.75,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: _enableStroke,
                  activeColor: Colors.deepPurpleAccent,
                  onChanged: (val) {
                    setState(() {
                      _enableStroke = val;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_enableStroke) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'STROKE WIDTH',
                  style: TextStyle(color: Colors.white24, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Text(
                  '${_strokeWidth.toStringAsFixed(1)}px',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.5,
                activeTrackColor: Colors.deepPurpleAccent,
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.deepPurpleAccent,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Slider(
                  value: _strokeWidth,
                  min: 0.5,
                  max: 12.0,
                  onChanged: (val) {
                    setState(() {
                      _strokeWidth = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCustomColorPickerButton(
                  currentColor: _strokeColor,
                  onColorChanged: (color) {
                    setState(() {
                      _strokeColor = color;
                    });
                  },
                  size: 30.0,
                ),
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _curatedColors.length,
                      itemBuilder: (context, idx) {
                        final c = _curatedColors[idx];
                        final isSel = _strokeColor == c;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _strokeColor = c;
                            });
                          },
                          child: Container(
                            width: 30,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.deepPurpleAccent : Colors.white24,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 30, color: Colors.white10),

          // DROP SHADOW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TEXT DROP SHADOW',
                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              Transform.scale(
                scale: 0.75,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: _enableShadow,
                  activeColor: Colors.deepPurpleAccent,
                  onChanged: (val) {
                    setState(() {
                      _enableShadow = val;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_enableShadow) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DROP SHADOW BLUR',
                  style: TextStyle(color: Colors.white24, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Text(
                  '${_shadowBlur.toInt()}px',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.5,
                activeTrackColor: Colors.deepPurpleAccent,
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.deepPurpleAccent,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Slider(
                  value: _shadowBlur,
                  min: 0.0,
                  max: 20.0,
                  onChanged: (val) {
                    setState(() {
                      _shadowBlur = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SHADOW X OFFSET
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SHADOW X OFFSET',
                  style: TextStyle(color: Colors.white24, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Text(
                  '${_shadowOffsetX.toInt()}px',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.5,
                activeTrackColor: Colors.deepPurpleAccent,
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.deepPurpleAccent,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Slider(
                  value: _shadowOffsetX,
                  min: -15.0,
                  max: 15.0,
                  onChanged: (val) {
                    setState(() {
                      _shadowOffsetX = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SHADOW Y OFFSET
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SHADOW Y OFFSET',
                  style: TextStyle(color: Colors.white24, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Text(
                  '${_shadowOffsetY.toInt()}px',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.5,
                activeTrackColor: Colors.deepPurpleAccent,
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.deepPurpleAccent,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Slider(
                  value: _shadowOffsetY,
                  min: -15.0,
                  max: 15.0,
                  onChanged: (val) {
                    setState(() {
                      _shadowOffsetY = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SHADOW COLOR PRESETS
            const Text(
              'SHADOW COLOR PRESETS',
              style: TextStyle(color: Colors.white24, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCustomColorPickerButton(
                  currentColor: _shadowColor,
                  onColorChanged: (color) {
                    setState(() {
                      _shadowColor = color.withOpacity(0.7);
                    });
                  },
                  size: 30.0,
                ),
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _curatedColors.length,
                      itemBuilder: (context, idx) {
                        final c = _curatedColors[idx];
                        final isSel = _shadowColor.value == c.withOpacity(0.7).value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _shadowColor = c.withOpacity(0.7);
                            });
                          },
                          child: Container(
                            width: 30,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.deepPurpleAccent : Colors.white24,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 5. EXPORT TAB
  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'METRICS & SUMMARY',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.8,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildMetricTile('Aspect Ratio', _aspectRatio, Icons.aspect_ratio_rounded),
              _buildMetricTile('Export Scale', '${_getExportHeight().toInt()}p', Icons.photo_size_select_large_rounded),
              _buildMetricTile('Typography Font', _selectedFont, Icons.font_download_rounded),
              _buildMetricTile('BG Media Source', _bgImagePath != null ? 'Uploaded Image' : 'Canvas Preset', Icons.image_rounded),
            ],
          ),
          const SizedBox(height: 24),
          if (_isCompiling) ...[
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Colors.deepPurpleAccent),
                  SizedBox(height: 12),
                  Text('Compiling high-resolution image...', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _compileAndExportPoster,
                icon: const Icon(Icons.palette_rounded, size: 16),
                label: const Text('COMPILE AND EXPORT POSTER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (_exportedImagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Image.file(
                  File(_exportedImagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.folder_open_rounded, color: Colors.deepPurpleAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saved to: Gallery / Movies / TypographyEditor',
                      style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sharePoster,
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('SHARE / SAVE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomColorPickerButton({
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
    double size = 35.0,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.transparent,
          elevation: 0,
          isScrollControlled: true,
          builder: (context) => CustomColorPicker(
            initialColor: currentColor,
            onColorChanged: onColorChanged,
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Colors.red, Colors.yellow, Colors.green,
              Colors.cyan, Colors.blue, Color(0xFFFF00FF),
              Colors.red
            ],
          ),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: const Icon(Icons.colorize_rounded, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.deepPurpleAccent, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
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

  void _showTextInputDialog() {
    final controller = TextEditingController(text: _customText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161622),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Overlay Text', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter typography text...',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _customText = controller.text.trim();
                  _textOverlayController.text = _customText;
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: const Text('UPDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // PERSISTENCE ENGINE & DATA LAYER
  Future<void> _initHive() async {
    _projectsBox = await Hive.openBox('image_text_projects');
    _loadSavedProjectsList();
    
    // Silent auto-resume last active project
    final lastState = _projectsBox!.get('last_active_project_state');
    if (lastState != null) {
      final stateMap = Map<String, dynamic>.from(lastState as Map);
      _loadLastActiveProject(stateMap);
    }
  }

  Future<void> _autoSaveLastActiveProject() async {
    if (_projectsBox == null) return;
    final projectData = {
      'aspectRatio': _aspectRatio,
      'bgImagePath': _bgImagePath,
      'canvasBgColorValue': _canvasBgColor.value,
      'useGradientBg': _useGradientBg,
      'gradientEndColorValue': _gradientEndColor.value,
      'customText': _customText,
      'fontSize': _fontSize,
      'letterSpacing': _letterSpacing,
      'textColorValue': _textColor.value,
      'selectedFont': _selectedFont,
      'textX': _textX,
      'textY': _textY,
      'rotationAngle': _rotationAngle,
      'enableStroke': _enableStroke,
      'enableShadow': _enableShadow,
      'strokeWidth': _strokeWidth,
      'strokeColorValue': _strokeColor.value,
      'shadowColorValue': _shadowColor.value,
      'shadowBlur': _shadowBlur,
      'shadowOffsetX': _shadowOffsetX,
      'shadowOffsetY': _shadowOffsetY,
      'boxColorValue': _boxColor.value,
      'boxOpacity': _boxOpacity,
      'boxRadius': _boxRadius,
    };
    await _projectsBox!.put('last_active_project_state', projectData);
  }

  void _loadLastActiveProject(Map<String, dynamic> proj) {
    setState(() {
      _aspectRatio = proj['aspectRatio'] ?? '9:16';
      _bgImagePath = proj['bgImagePath'];
      _canvasBgColor = Color(proj['canvasBgColorValue'] ?? const Color(0xFF1E1E2C).value);
      _useGradientBg = proj['useGradientBg'] ?? false;
      _gradientEndColor = Color(proj['gradientEndColorValue'] ?? const Color(0xFF0F0F1A).value);
      _customText = proj['customText'] ?? 'Typography text';
      _textOverlayController.text = _customText;
      _fontSize = (proj['fontSize'] as num?)?.toDouble() ?? 45.0;
      _letterSpacing = (proj['letterSpacing'] as num?)?.toDouble() ?? 0.0;
      _textColor = Color(proj['textColorValue'] ?? Colors.white.value);
      _selectedFont = proj['selectedFont'] ?? 'Poppins';
      _textX = (proj['textX'] as num?)?.toDouble() ?? 0.5;
      _textY = (proj['textY'] as num?)?.toDouble() ?? 0.5;
      _rotationAngle = (proj['rotationAngle'] as num?)?.toDouble() ?? 0.0;
      _enableStroke = proj['enableStroke'] ?? (((proj['strokeWidth'] as num?)?.toDouble() ?? 0.0) > 0);
      _enableShadow = proj['enableShadow'] ?? true;
      _strokeWidth = (proj['strokeWidth'] as num?)?.toDouble() ?? 2.0;
      _strokeColor = Color(proj['strokeColorValue'] ?? Colors.black.value);
      _shadowColor = Color(proj['shadowColorValue'] ?? Colors.black.withOpacity(0.5).value);
      _shadowBlur = (proj['shadowBlur'] as num?)?.toDouble() ?? 4.0;
      _shadowOffsetX = (proj['shadowOffsetX'] as num?)?.toDouble() ?? 2.0;
      _shadowOffsetY = (proj['shadowOffsetY'] as num?)?.toDouble() ?? 2.0;
      _boxColor = Color(proj['boxColorValue'] ?? Colors.transparent.value);
      _boxOpacity = (proj['boxOpacity'] as num?)?.toDouble() ?? 0.6;
      _boxRadius = (proj['boxRadius'] as num?)?.toDouble() ?? 8.0;
    });
  }

  void _loadSavedProjectsList() {
    if (_projectsBox == null) return;
    setState(() {
      _savedProjects = _projectsBox!.values
          .where((v) => v is Map && v.containsKey('id') && v.containsKey('lastModified'))
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList()
        ..sort((a, b) => (b['lastModified'] as String? ?? '').compareTo(a['lastModified'] as String? ?? ''));
    });
  }

  Future<void> _saveCurrentProject(String name) async {
    if (_projectsBox == null) return;
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final projectData = {
      'id': id,
      'name': name,
      'lastModified': DateTime.now().toIso8601String(),
      'aspectRatio': _aspectRatio,
      'bgImagePath': _bgImagePath,
      'canvasBgColorValue': _canvasBgColor.value,
      'useGradientBg': _useGradientBg,
      'gradientEndColorValue': _gradientEndColor.value,
      'customText': _customText,
      'fontSize': _fontSize,
      'letterSpacing': _letterSpacing,
      'textColorValue': _textColor.value,
      'selectedFont': _selectedFont,
      'textX': _textX,
      'textY': _textY,
      'rotationAngle': _rotationAngle,
      'enableStroke': _enableStroke,
      'enableShadow': _enableShadow,
      'strokeWidth': _strokeWidth,
      'strokeColorValue': _strokeColor.value,
      'shadowColorValue': _shadowColor.value,
      'shadowBlur': _shadowBlur,
      'shadowOffsetX': _shadowOffsetX,
      'shadowOffsetY': _shadowOffsetY,
      'boxColorValue': _boxColor.value,
      'boxOpacity': _boxOpacity,
      'boxRadius': _boxRadius,
    };

    await _projectsBox!.put(id, projectData);
    _loadSavedProjectsList();
    _showSnackBar('Project "$name" saved successfully!');
    _autoSaveLastActiveProject();
  }

  void _loadProject(Map<String, dynamic> proj) {
    setState(() {
      _aspectRatio = proj['aspectRatio'] ?? '9:16';
      _bgImagePath = proj['bgImagePath'];
      _canvasBgColor = Color(proj['canvasBgColorValue'] ?? const Color(0xFF1E1E2C).value);
      _useGradientBg = proj['useGradientBg'] ?? false;
      _gradientEndColor = Color(proj['gradientEndColorValue'] ?? const Color(0xFF0F0F1A).value);
      _customText = proj['customText'] ?? 'Typography text';
      _textOverlayController.text = _customText;
      _fontSize = (proj['fontSize'] as num?)?.toDouble() ?? 45.0;
      _letterSpacing = (proj['letterSpacing'] as num?)?.toDouble() ?? 0.0;
      _textColor = Color(proj['textColorValue'] ?? Colors.white.value);
      _selectedFont = proj['selectedFont'] ?? 'Poppins';
      _textX = (proj['textX'] as num?)?.toDouble() ?? 0.5;
      _textY = (proj['textY'] as num?)?.toDouble() ?? 0.5;
      _rotationAngle = (proj['rotationAngle'] as num?)?.toDouble() ?? 0.0;
      _enableStroke = proj['enableStroke'] ?? (((proj['strokeWidth'] as num?)?.toDouble() ?? 0.0) > 0);
      _enableShadow = proj['enableShadow'] ?? true;
      _strokeWidth = (proj['strokeWidth'] as num?)?.toDouble() ?? 2.0;
      _strokeColor = Color(proj['strokeColorValue'] ?? Colors.black.value);
      _shadowColor = Color(proj['shadowColorValue'] ?? Colors.black.withOpacity(0.5).value);
      _shadowBlur = (proj['shadowBlur'] as num?)?.toDouble() ?? 4.0;
      _shadowOffsetX = (proj['shadowOffsetX'] as num?)?.toDouble() ?? 2.0;
      _shadowOffsetY = (proj['shadowOffsetY'] as num?)?.toDouble() ?? 2.0;
      _boxColor = Color(proj['boxColorValue'] ?? Colors.transparent.value);
      _boxOpacity = (proj['boxOpacity'] as num?)?.toDouble() ?? 0.6;
      _boxRadius = (proj['boxRadius'] as num?)?.toDouble() ?? 8.0;
    });
    _showSnackBar('Project "${proj['name']}" loaded!');
    _autoSaveLastActiveProject();
  }

  Future<void> _deleteSavedProject(String id) async {
    if (_projectsBox == null) return;
    await _projectsBox!.delete(id);
    _loadSavedProjectsList();
    _showSnackBar('Project deleted.');
  }

  void _showRenameProjectDialog(Map<String, dynamic> proj, StateSetter setDialogState) {
    final controller = TextEditingController(text: proj['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161622),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Project',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'New Project Name',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _renameSavedProject(proj['id'], newName);
                setDialogState(() {});
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: const Text('RENAME',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _renameSavedProject(String id, String newName) async {
    if (_projectsBox == null) return;
    final projData = _projectsBox!.get(id);
    if (projData != null) {
      final updatedData = Map<String, dynamic>.from(projData as Map);
      updatedData['name'] = newName;
      updatedData['lastModified'] = DateTime.now().toIso8601String();
      await _projectsBox!.put(id, updatedData);
      _loadSavedProjectsList();
      _showSnackBar('Project renamed to "$newName" successfully!');
      _autoSaveLastActiveProject();
    }
  }

  void _resetToNewProject() {
    setState(() {
      _aspectRatio = '9:16';
      _bgImagePath = null;
      _canvasBgColor = const Color(0xFF1E1E2C);
      _useGradientBg = false;
      _gradientEndColor = const Color(0xFF0F0F1A);
      _customText = 'Typography text';
      _textOverlayController.text = _customText;
      _fontSize = 45.0;
      _letterSpacing = 0.0;
      _textColor = Colors.white;
      
      final allFonts = _getAllAvailableFonts();
      if (allFonts.contains('KleeOne')) {
        _selectedFont = 'KleeOne';
      } else if (allFonts.isNotEmpty) {
        _selectedFont = allFonts.first;
      } else {
        _selectedFont = 'Poppins';
      }
      
      _textX = 0.5;
      _textY = 0.5;
      _rotationAngle = 0.0;
      _enableStroke = false;
      _enableShadow = true;
      _strokeWidth = 2.0;
      _strokeColor = Colors.black;
      _shadowColor = Colors.black.withOpacity(0.5);
      _shadowBlur = 4.0;
      _shadowOffsetX = 2.0;
      _shadowOffsetY = 2.0;
      _boxColor = Colors.transparent;
      _boxOpacity = 0.6;
      _boxRadius = 8.0;
    });
    _showSnackBar('New Project workspace initialized!');
    _autoSaveLastActiveProject();
  }

  Future<void> _importProject() async {
    try {
      final imported = await ImageTextExportService.importProjectsFromFile();
      if (imported.isEmpty) return;

      if (_projectsBox == null) return;
      int count = 0;
      for (var proj in imported) {
        final String newId = '${DateTime.now().millisecondsSinceEpoch}_$count';
        final projectData = Map<String, dynamic>.from(proj);
        projectData['id'] = newId;

        final originalName = projectData['name'] ?? 'Imported Poster';
        projectData['name'] = '$originalName (Imported)';
        projectData['lastModified'] = DateTime.now().toIso8601String();

        await _projectsBox!.put(newId, projectData);
        count++;
      }

      _loadSavedProjectsList();
      _showSnackBar('Successfully imported $count project(s)!');
    } catch (e) {
      debugPrint('Error importing project: $e');
      _showSnackBar('Failed to import project: $e');
    }
  }

  // DIALOG SHEETS
  void _showSaveProjectDialog() {
    final controller = TextEditingController(
        text: 'Poster Project ${DateTime.now().hour}:${DateTime.now().minute}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161622),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Poster Project',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Project Name',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _saveCurrentProject(name);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: const Text('SAVE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showLoadProjectsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161622),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saved Poster Projects',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  if (AppConfig.showImageTextImportExport)
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, color: Colors.deepPurpleAccent, size: 20),
                      tooltip: 'Import Project (.typostudio)',
                      onPressed: () async {
                        await _importProject();
                        setDialogState(() {});
                      },
                    ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: _savedProjects.isEmpty
                    ? Center(
                        child: Text(
                          'No saved projects yet.',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _savedProjects.length,
                        itemBuilder: (context, index) {
                          final proj = _savedProjects[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                _loadProject(proj);
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurpleAccent.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.palette_rounded,
                                          color: Colors.deepPurpleAccent, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            proj['name'] ?? 'Untitled Poster',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                overflow: TextOverflow.ellipsis),
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Modified: ${proj['lastModified'] != null ? proj['lastModified'].toString().substring(0, 10) : ""}',
                                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                          icon: const Icon(Icons.edit_rounded,
                                              color: Colors.amberAccent, size: 18),
                                          tooltip: 'Rename Project',
                                          onPressed: () => _showRenameProjectDialog(proj, setDialogState),
                                        ),
                                        if (AppConfig.showImageTextImportExport)
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                            icon: const Icon(Icons.share_rounded,
                                                color: Colors.blueAccent, size: 18),
                                            tooltip: 'Export/Share Project',
                                            onPressed: () async {
                                              final success = await ImageTextExportService.exportProject(proj);
                                              if (success) {
                                                _showSnackBar('Project exported successfully!');
                                              } else {
                                                _showSnackBar('Failed to export project.');
                                              }
                                            },
                                          ),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                          icon: const Icon(Icons.delete_outline_rounded,
                                              color: Colors.redAccent, size: 18),
                                          tooltip: 'Delete Project',
                                          onPressed: () async {
                                            await _deleteSavedProject(proj['id']);
                                            setDialogState(() {});
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios_rounded,
                                            color: Colors.white.withOpacity(0.2), size: 12),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
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
