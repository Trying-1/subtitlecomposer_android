import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class OverlayColorPicker extends StatefulWidget {
  final String imagePath;
  final ValueChanged<int> onColorPicked;

  const OverlayColorPicker({
    super.key,
    required this.imagePath,
    required this.onColorPicked,
  });

  static Future<void> show(BuildContext context, String imagePath, ValueChanged<int> onColorPicked) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: OverlayColorPicker(
          imagePath: imagePath,
          onColorPicked: onColorPicked,
        ),
      ),
    );
  }

  @override
  State<OverlayColorPicker> createState() => _OverlayColorPickerState();
}

class _OverlayColorPickerState extends State<OverlayColorPicker> {
  static const MethodChannel _channel = MethodChannel('com.typography/bridge');
  
  bool _isLoading = true;
  Uint8List? _imageBytes;
  img.Image? _decodedImage;
  Color? _hoverColor;
  Offset? _hoverPos;
  
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }
  
  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('getAssetThumbnail', {'path': widget.imagePath});
      if (bytes != null && mounted) {
        setState(() {
          _imageBytes = bytes;
        });
        
        // Decode image in background thread
        final decoded = await img.decodeImageFile(widget.imagePath) ?? img.decodeImage(bytes);
        if (mounted) {
          setState(() {
            _decodedImage = decoded;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onPan(Offset localPosition, Size widgetSize) {
    if (_decodedImage == null) return;
    
    // Offset the target position so the crosshair is above the finger
    final Offset targetPos = Offset(localPosition.dx, localPosition.dy - 80);

    // Without InteractiveViewer, logicalPos is exactly targetPos
    final Offset logicalPos = targetPos;
    
    double imgRatio = _decodedImage!.width / _decodedImage!.height;
    double widgetRatio = widgetSize.width / widgetSize.height;
    
    double drawWidth, drawHeight;
    double startX = 0, startY = 0;
    
    if (widgetRatio > imgRatio) {
      drawHeight = widgetSize.height;
      drawWidth = drawHeight * imgRatio;
      startX = (widgetSize.width - drawWidth) / 2;
    } else {
      drawWidth = widgetSize.width;
      drawHeight = drawWidth / imgRatio;
      startY = (widgetSize.height - drawHeight) / 2;
    }
    
    final double xOnImage = logicalPos.dx - startX;
    final double yOnImage = logicalPos.dy - startY;
    
    if (xOnImage >= 0 && xOnImage <= drawWidth && yOnImage >= 0 && yOnImage <= drawHeight) {
      final int pixelX = (xOnImage / drawWidth * _decodedImage!.width).floor().clamp(0, _decodedImage!.width - 1);
      final int pixelY = (yOnImage / drawHeight * _decodedImage!.height).floor().clamp(0, _decodedImage!.height - 1);
      
      final pixel = _decodedImage!.getPixel(pixelX, pixelY);
      
      setState(() {
        _hoverColor = Color.fromARGB(
          pixel.a.toInt(),
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
        _hoverPos = targetPos;
      });
    } else {
      setState(() {
        _hoverPos = targetPos; // still track pos to show magnifier, but maybe keep last color
      });
    }
  }

  void _confirmSelection() {
    if (_hoverColor != null) {
      widget.onColorPicked(_hoverColor!.value);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
    }
    
    if (_imageBytes == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('Could not load overlay image.', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              )
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black87),
          ),
        ),
        
        // Image & Picker
        Positioned(
          top: 80,
          bottom: 100,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onPanUpdate: (details) => _onPan(details.localPosition, size),
                  onPanDown: (details) => _onPan(details.localPosition, size),
                  onTapUp: (details) => _onPan(details.localPosition, size),
                  child: Container(
                    color: Colors.transparent, // Ensure GestureDetector catches all drag events
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                );
              }
            ),
          ),
        ),
        
        // Floating Magnifier/Color Preview
        if (_hoverColor != null && _hoverPos != null)
          Positioned(
            left: _hoverPos!.dx - 40,
            top: _hoverPos!.dy + 40, // Centered perfectly on _hoverPos (the offset target)
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hoverColor,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12),
                ]
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white70, size: 24),
              ),
            ),
          ),
          
        // Header bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16, bottom: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pick Chroma Key Color',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom Panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, top: 16, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF16161E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _hoverColor ?? Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Selected Color', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          _hoverColor != null 
                              ? '#${_hoverColor!.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}' 
                              : 'None',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _hoverColor == null ? null : _confirmSelection,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
