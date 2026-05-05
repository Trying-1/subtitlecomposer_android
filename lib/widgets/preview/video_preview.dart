import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';
import '../../models/editor_models.dart';
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
      final provider = context.read<EditorProvider>();
      provider.syncToNative(); // Trigger full sync after native engine is ready
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
  bool _isSeeking = false;
  Duration _initialSeekTime = Duration.zero;
  double _startFocalPointX = 0;

  void _handleScaleStart(ScaleStartDetails details, BoxConstraints constraints) {
    final provider = context.read<EditorProvider>();
    
    _isSeeking = false;
    // Direct Selection: Find clip at touch point
    final tapX = details.localFocalPoint.dx / constraints.maxWidth;
    final tapY = details.localFocalPoint.dy / constraints.maxHeight;
    provider.selectClipAt(tapX, tapY, deselectIfEmpty: false, toggle: false);

    // Now that selection is updated (if any), capture base scale
    _baseScale = provider.selectedTimelineClip?.scale ?? 1.0;
  }

  void _handleScaleUpdate(BuildContext context, ScaleUpdateDetails details, BoxConstraints constraints) {
    final provider = context.read<EditorProvider>();
    
    final clip = provider.selectedTimelineClip;
    if (clip == null || clip is BackgroundClip) return;

    // Handle drag (focalPointDelta is the movement since last update)
    final dx = details.focalPointDelta.dx / constraints.maxWidth;
    final dy = details.focalPointDelta.dy / constraints.maxHeight;

    if (provider.selectedClipIds.length > 1) {
      // Move all selected clips equally
      provider.moveClips(provider.selectedClipIds, dx, dy);
    } else {
      // Move single clip and handle scaling
      final newScale = (_baseScale * details.scale).clamp(0.1, 5.0);
      provider.updateClip(
        clip.id,
        x: (clip.x + dx).clamp(-0.5, 1.5),
        y: (clip.y + dy).clamp(-0.5, 1.5),
        scale: newScale,
      );
    }
  }

  void _handleFocusSeekStart(ScaleStartDetails details) {
    final provider = context.read<EditorProvider>();
    _isSeeking = true;
    _initialSeekTime = provider.currentTime;
    _startFocalPointX = details.localFocalPoint.dx;
  }

  void _handleFocusSeekUpdate(ScaleUpdateDetails details, double totalWidth) {
    final provider = context.read<EditorProvider>();
    final dx = details.localFocalPoint.dx - _startFocalPointX;
    // Sensitivity: Swiping full width = 20 seconds of timeline
    final double sensitivitySeconds = 20.0;
    final double offsetSeconds = (dx / totalWidth) * sensitivitySeconds;
    final Duration newPos = _initialSeekTime + Duration(milliseconds: (offsetSeconds * 1000).toInt());
    
    Duration clampedPos = newPos;
    if (clampedPos < Duration.zero) clampedPos = Duration.zero;
    if (clampedPos > provider.totalDuration) clampedPos = provider.totalDuration;
    
    provider.seek(clampedPos);
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

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        return Container(
          color: const Color(0xFF1A1A1E), // Dark studio workspace
          child: Stack(
            children: [
              // 1. Canvas Layer
              Center(
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
                          onScaleEnd: (_) => _isSeeking = false,
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
              
              // 2. Focused Seek Zone Overlay (Bottom 25% of the total widget area)
              if (provider.isTimelineCollapsed)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: outerConstraints.maxHeight * 0.25,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _handleFocusSeekStart,
                    onScaleUpdate: (details) => _handleFocusSeekUpdate(details, outerConstraints.maxWidth),
                    onScaleEnd: (_) => _isSeeking = false,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black26,
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.swap_horiz_rounded, color: Colors.white12, size: 32),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
