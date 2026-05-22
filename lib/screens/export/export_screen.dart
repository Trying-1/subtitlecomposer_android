import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';
import 'dart:async';
import '../video_player_screen.dart';
import '../../services/app_review_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  double _progress = 0.0;
  String _status = 'Initializing renderer...';
  bool _isFinished = false;
  String? _outputPath;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  void _startExport() {
    // Simulate export progress for professional feel
    // In a real app, this would be tied to the native encoder progress
    int step = 0;
    const List<String> statuses = [
      'Initializing renderer...',
      'Optimizing textures...',
      'Encoding audio tracks...',
      'Rendering frames...',
      'Finalizing video...',
      'Saving to gallery...'
    ];

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_progress < 0.95) {
          _progress += 0.005;
          
          int statusIdx = (_progress * statuses.length).floor();
          if (statusIdx < statuses.length) {
            _status = statuses[statusIdx];
          }
        }
      });
    });

    // Actually trigger the native export
    final provider = context.read<EditorProvider>();
    provider.exportVideo().then((path) {
      _timer?.cancel();
      setState(() {
        _progress = 1.0;
        _status = 'Export successful!';
        _isFinished = true;
        _outputPath = path;
      });
      AppReviewService.requestReviewIfNeeded();
    }).catchError((e) {
      _timer?.cancel();
      setState(() {
        _status = 'Export failed: $e';
        _isFinished = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF001F3F).withOpacity(0.5),
              const Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 60),
                _buildProgressIndicator(),
                const SizedBox(height: 40),
                _buildStatusText(),
                const SizedBox(height: 80),
                if (_isFinished) _buildActions() else _buildCancelButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isFinished ? Icons.check_circle_rounded : Icons.ios_share_rounded,
            color: Colors.blueAccent,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isFinished ? 'EXPORT READY' : 'EXPORTING VIDEO',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isFinished ? 'Your creation is ready to share' : 'Please keep the app open during rendering',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(
            value: _progress,
            strokeWidth: 12,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'COMPLETE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _status.toUpperCase(),
        key: ValueKey(_status),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(
        'CANCEL EXPORT',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  String _getFriendlyPath(String path) {
    if (path.startsWith('content://')) {
      return "Gallery / Movies / TypographyEditor";
    }
    return path;
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_outputPath != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open_rounded, color: Colors.white38, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getFriendlyPath(_outputPath!),
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('PREVIEW VIDEO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              // Share functionality
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.share_rounded, size: 20),
            label: const Text('SHARE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'DONE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
