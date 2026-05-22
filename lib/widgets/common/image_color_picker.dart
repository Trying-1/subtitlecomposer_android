import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageColorPickerScreen extends StatefulWidget {
  final File imageFile;
  final List<Color> initialColors;

  const ImageColorPickerScreen({
    super.key,
    required this.imageFile,
    required this.initialColors,
  });

  @override
  State<ImageColorPickerScreen> createState() => _ImageColorPickerScreenState();
}

class _ImageColorPickerScreenState extends State<ImageColorPickerScreen> {
  img.Image? _decodedImage;
  List<Color> _selectedColors = [];
  Offset? _fingerPos;
  Color? _hoverColor;
  bool _isLoading = true;
  int _activeRoleIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedColors = List.from(widget.initialColors);
    while (_selectedColors.length < 4) {
      if (_selectedColors.isEmpty) {
        _selectedColors.add(Colors.black);
      } else if (_selectedColors.length == 1) {
        _selectedColors.add(Colors.white);
      } else if (_selectedColors.length == 2) {
        _selectedColors.add(Colors.deepPurpleAccent);
      } else {
        _selectedColors.add(Colors.grey);
      }
    }
    if (_selectedColors.length > 4) {
      _selectedColors = _selectedColors.sublist(0, 4);
    }
    _loadAndDecodeImage();
  }

  Future<void> _loadAndDecodeImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      _decodedImage = img.decodeImage(bytes);
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error decoding image: $e");
      if (mounted) Navigator.pop(context);
    }
  }

  Color _getColorAt(Offset localPosition, Size widgetSize) {
    if (_decodedImage == null) return Colors.transparent;

    // Sample 60 pixels above finger to not block the view
    final Offset samplePos = Offset(localPosition.dx, localPosition.dy - 60);

    final double imageWidth = _decodedImage!.width.toDouble();
    final double imageHeight = _decodedImage!.height.toDouble();
    final double widgetWidth = widgetSize.width;
    final double widgetHeight = widgetSize.height;

    final double imageAspect = imageWidth / imageHeight;
    final double widgetAspect = widgetWidth / widgetHeight;

    double actualWidth, actualHeight, offsetX = 0, offsetY = 0;

    if (imageAspect > widgetAspect) {
      actualWidth = widgetWidth;
      actualHeight = widgetWidth / imageAspect;
      offsetY = (widgetHeight - actualHeight) / 2;
    } else {
      actualHeight = widgetHeight;
      actualWidth = widgetHeight * imageAspect;
      offsetX = (widgetWidth - actualWidth) / 2;
    }

    final double relativeX = (samplePos.dx - offsetX) / actualWidth;
    final double relativeY = (samplePos.dy - offsetY) / actualHeight;

    if (relativeX < 0 || relativeX > 1 || relativeY < 0 || relativeY > 1) {
      return Colors.transparent;
    }

    final int px = (relativeX * imageWidth).toInt().clamp(0, _decodedImage!.width - 1);
    final int py = (relativeY * imageHeight).toInt().clamp(0, _decodedImage!.height - 1);

    final pixel = _decodedImage!.getPixel(px, py);
    return Color.fromARGB(
      pixel.a.toInt(),
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }

  void _updateHover(Offset localPosition, Size widgetSize) {
    final color = _getColorAt(localPosition, widgetSize);
    setState(() {
      _fingerPos = localPosition;
      if (color != Colors.transparent) {
        _hoverColor = color;
        if (_activeRoleIndex >= 0 && _activeRoleIndex < _selectedColors.length) {
          _selectedColors[_activeRoleIndex] = color;
        }
      }
    });
  }

  String _getColorRoleLabel(int index) {
    switch (index) {
      case 0:
        return 'BACKGROUND';
      case 1:
        return 'MAIN TEXT';
      case 2:
        return 'SUB MAIN';
      case 3:
        return 'NORMAL TEXT';
      default:
        return 'EXTRA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sample Colors from Image', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedColors),
            child: const Text('CONFIRM', style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : Stack(
              children: [
                Column(
                  children: [
                    _buildTopMagnifier(),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onPanUpdate: (details) => _updateHover(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                            onPanStart: (details) => _updateHover(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                            onTapDown: (details) => _updateHover(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                            child: Stack(
                              children: [
                                Center(
                                  child: Image.file(
                                    widget.imageFile,
                                    fit: BoxFit.contain,
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                  ),
                                ),
                                if (_fingerPos != null)
                                  Positioned(
                                    left: _fingerPos!.dx - 20,
                                    top: _fingerPos!.dy - 80,
                                    child: _PipetteMarker(color: _hoverColor ?? Colors.transparent),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    _buildBottomSection(),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildTopMagnifier() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _hoverColor ?? Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  if (_hoverColor != null)
                    BoxShadow(color: _hoverColor!.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: const Center(
                child: Icon(Icons.colorize_rounded, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hoverColor != null 
                ? '#${_hoverColor!.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}'
                : 'DRAG TO SAMPLE COLOR',
              style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SELECT COLORS FOR EACH ROLE',
            style: TextStyle(
              fontSize: 11,
              color: Colors.deepPurpleAccent,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a role card below, then drag on the image to sample its color.',
            style: TextStyle(fontSize: 9, color: Colors.white38),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final label = _getColorRoleLabel(index);
              final isSelected = _activeRoleIndex == index;
              final color = _selectedColors[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeRoleIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == 3 ? 0 : 4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurpleAccent.withOpacity(0.08)
                          : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurpleAccent
                            : Colors.white.withOpacity(0.05),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : Colors.white38,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_activeRoleIndex == 0) _selectedColors[0] = Colors.black;
                      if (_activeRoleIndex == 1) _selectedColors[1] = Colors.white;
                      if (_activeRoleIndex == 2) _selectedColors[2] = Colors.deepPurpleAccent;
                      if (_activeRoleIndex == 3) _selectedColors[3] = Colors.grey;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('RESET ROLE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedColors),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('USE THIS PALETTE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipetteMarker extends StatelessWidget {
  final Color color;

  const _PipetteMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
          Center(
            child: Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          ),
          Center(
            child: Container(width: 40, height: 1, color: Colors.white.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }
}
