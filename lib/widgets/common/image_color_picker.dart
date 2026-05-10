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

  @override
  void initState() {
    super.initState();
    _selectedColors = List.from(widget.initialColors);
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

    // Apply offset to the sample point so it's not under the finger
    // We'll sample 50 pixels ABOVE the finger
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
      }
    });
  }

  void _addColor() {
    if (_hoverColor != null && _selectedColors.length < 12) {
      setState(() {
        _selectedColors.add(_hoverColor!);
      });
      // Small haptic or visual feedback could go here
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
        title: const Text('Manual Color Picker', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                    // Magnifier at the top
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
                                    top: _fingerPos!.dy - 80, // Pipette offset
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
                : 'DRAG TO PICK',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PALETTE PREVIEW', style: TextStyle(fontSize: 10, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  SizedBox(height: 4),
                  Text('Tap circles to remove', style: TextStyle(fontSize: 9, color: Colors.white38)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_selectedColors.length}/12', style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedColors.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColors.removeAt(index)),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _selectedColors[index],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10, width: 2),
                        boxShadow: [
                          BoxShadow(color: _selectedColors[index].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Center(child: Icon(Icons.close, size: 12, color: Colors.white24)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addColor,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('ADD COLOR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
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
