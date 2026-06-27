import 'package:flutter/material.dart';
import '../../../models/editor_models.dart';
import 'common/common_controls.dart';
import 'common/overlay_color_picker.dart';

import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';

class RemoveBgTab extends StatefulWidget {
  final OverlayClip? selectedOverlay;
  final Function({
    bool? isChromaKeyEnabled,
    int? chromaKeyColor,
    double? chromaKeySimilarity,
    double? chromaKeySmoothness,
  }) onUpdate;

  const RemoveBgTab({
    super.key,
    required this.selectedOverlay,
    required this.onUpdate,
  });

  @override
  State<RemoveBgTab> createState() => _RemoveBgTabState();
}

class _RemoveBgTabState extends State<RemoveBgTab> {
  static const MethodChannel _channel = MethodChannel('com.typography/bridge');
  
  List<Color> _suggestedColors = [];
  bool _isLoadingColors = false;

  @override
  void initState() {
    super.initState();
    _extractSuggestedColors();
  }

  @override
  void didUpdateWidget(RemoveBgTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedOverlay?.imagePath != oldWidget.selectedOverlay?.imagePath) {
      _extractSuggestedColors();
    }
  }

  Future<void> _extractSuggestedColors() async {
    final imagePath = widget.selectedOverlay?.imagePath;
    if (imagePath == null) {
      setState(() {
        _suggestedColors = [];
      });
      return;
    }

    setState(() {
      _isLoadingColors = true;
      _suggestedColors = [];
    });

    try {
      final bytes = await _channel.invokeMethod<Uint8List>('getAssetThumbnail', {'path': imagePath});
      if (bytes != null && mounted) {
        final imageProvider = MemoryImage(bytes);
        final palette = await PaletteGenerator.fromImageProvider(
          imageProvider,
          maximumColorCount: 10,
        );
        
        if (mounted) {
          setState(() {
            _suggestedColors = palette.colors.toList();
            _isLoadingColors = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoadingColors = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingColors = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedOverlay == null) {
      return const Center(
        child: Text('Select an overlay to remove background', style: TextStyle(color: Colors.white54, fontSize: 13)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AUTO BACKGROUND REMOVAL', style: TextStyle(fontSize: 8, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Auto background removal coming soon!')),
            );
          },
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Remove Background', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent.withOpacity(0.2),
            foregroundColor: Colors.deepPurpleAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 32),
        const Text('CHROMA KEY (GREEN SCREEN)', style: TextStyle(fontSize: 8, color: Colors.greenAccent, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Enable Chroma Key', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            Switch(
              value: widget.selectedOverlay!.isChromaKeyEnabled,
              onChanged: (v) => widget.onUpdate(isChromaKeyEnabled: v),
              activeColor: Colors.greenAccent,
              activeTrackColor: Colors.greenAccent.withOpacity(0.3),
            ),
          ],
        ),
        if (widget.selectedOverlay!.isChromaKeyEnabled) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CommonControls.buildColorPicker(
                  context,
                  'Key Color',
                  widget.selectedOverlay!.chromaKeyColor,
                  (c) => widget.onUpdate(chromaKeyColor: c),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 16),
                child: IconButton(
                  icon: const Icon(Icons.colorize, color: Colors.greenAccent, size: 20),
                  tooltip: 'Pick color from overlay',
                  onPressed: () {
                    OverlayColorPicker.show(
                      context, 
                      widget.selectedOverlay!.imagePath, 
                      (c) => widget.onUpdate(chromaKeyColor: c)
                    );
                  },
                ),
              )
            ],
          ),
          
          if (_isLoadingColors)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent)
              ),
            )
          else if (_suggestedColors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SUGGESTED COLORS', style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestedColors.map((color) {
                        final isSelected = widget.selectedOverlay!.chromaKeyColor == color.value;
                        return GestureDetector(
                          onTap: () => widget.onUpdate(chromaKeyColor: color.value),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.greenAccent : Colors.white10,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 8)
                              ]
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
          const SizedBox(height: 12),
          CommonControls.buildSlider(
            context,
            'Similarity',
            widget.selectedOverlay!.chromaKeySimilarity,
            0.0,
            1.0,
            (v) => widget.onUpdate(chromaKeySimilarity: v),
          ),
          const SizedBox(height: 12),
          CommonControls.buildSlider(
            context,
            'Smoothness',
            widget.selectedOverlay!.chromaKeySmoothness,
            0.0,
            1.0,
            (v) => widget.onUpdate(chromaKeySmoothness: v),
          ),
        ],
      ],
    );
  }
}
