import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';
import '../../services/native_bridge.dart';

class VideoPreview extends StatefulWidget {
  const VideoPreview({super.key});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  final NativeBridge _bridge = NativeBridge();
  int? _textureId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  Future<void> _initPreview() async {
    final textureId = await _bridge.initRenderer(1280, 720);
    if (mounted) {
      setState(() {
        _textureId = textureId;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _bridge.disposeRenderer();
    super.dispose();
  }

  double _baseScale = 1.0;

  void _handleScaleStart(ScaleStartDetails details, BoxConstraints constraints) {
    final provider = context.read<EditorProvider>();
    
    // Direct Selection: Find clip at touch point
    final tapX = details.localFocalPoint.dx / constraints.maxWidth;
    final tapY = details.localFocalPoint.dy / constraints.maxHeight;
    provider.selectClipAt(tapX, tapY, deselectIfEmpty: false);

    // Now that selection is updated (if any), capture base scale
    _baseScale = provider.selectedClip?.scale ?? 1.0;
  }

  void _handleScaleUpdate(BuildContext context, ScaleUpdateDetails details, BoxConstraints constraints) {
    final provider = context.read<EditorProvider>();
    final clip = provider.selectedClip;
    if (clip == null) return;

    // Handle drag (focalPointDelta is the movement since last update)
    final dx = details.focalPointDelta.dx / constraints.maxWidth;
    final dy = details.focalPointDelta.dy / constraints.maxHeight;

    // Handle scale (details.scale is the total scale since start of gesture)
    final newScale = (_baseScale * details.scale).clamp(0.1, 5.0);

    provider.updateClip(
      clip.id,
      x: (clip.x + dx).clamp(0.0, 1.0),
      y: (clip.y + dy).clamp(0.0, 1.0),
      scale: newScale,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_textureId == null) {
      return const Center(child: Text("Failed to initialize OpenGL preview"));
    }

    final provider = context.watch<EditorProvider>();

    return Container(
      color: const Color(0xFF1A1A1E), // Dark studio workspace
      child: Center(
        child: AspectRatio(
          key: ValueKey('preview_${provider.aspectRatio}'),
          aspectRatio: provider.aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dpr = MediaQuery.of(context).devicePixelRatio;
              // Sync actual dimensions to native for viewport and buffer management
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.updateProjectSync(
                  width: (constraints.maxWidth * dpr).toInt(),
                  height: (constraints.maxHeight * dpr).toInt(),
                );
              });

              return Container(
                color: Color(provider.backgroundColor), // Actual video background
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) => _handleScaleStart(details, constraints),
                  onScaleUpdate: (details) => _handleScaleUpdate(context, details, constraints),
                  onTapUp: (details) {
                    final provider = context.read<EditorProvider>();
                    final tapX = details.localPosition.dx / constraints.maxWidth;
                    final tapY = details.localPosition.dy / constraints.maxHeight;
                    provider.selectClipAt(tapX, tapY);
                  },
                  child: Texture(textureId: _textureId!),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
