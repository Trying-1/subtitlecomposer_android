import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../../services/typosync_service.dart';

class SyncPackager extends StatefulWidget {
  const SyncPackager({super.key});

  @override
  State<SyncPackager> createState() => _SyncPackagerState();
}

class _SyncPackagerState extends State<SyncPackager> {
  String? _audioPath;
  String? _jsonPath;
  final TextEditingController _nameController = TextEditingController();
  bool _isPackaging = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = "my_sync_package_${DateTime.now().millisecondsSinceEpoch}";
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioPath = result.files.single.path;
        // Pre-fill name if empty
        final base = p.basenameWithoutExtension(_audioPath!);
        _nameController.text = "${base}_pack";
      });
    }
  }

  Future<void> _pickJson() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _jsonPath = result.files.single.path;
      });
    }
  }

  Future<void> _createPackage() async {
    if (_audioPath == null || _jsonPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both audio and subtitle JSON files first.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a package name.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isPackaging = true;
    });

    try {
      final packageFile = await TyposyncService.createTyposyncPackage(
        audioPath: _audioPath!,
        subtitlesJsonPath: _jsonPath!,
        outputName: name,
      );

      setState(() {
        _isPackaging = false;
      });

      if (packageFile != null) {
        // Share package
        await Share.shareXFiles(
          [XFile(packageFile.path)],
          text: 'Share Typosync Package: ${p.basename(packageFile.path)}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Typosync package created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to generate package file.');
      }
    } catch (e) {
      setState(() {
        _isPackaging = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Sync Packager Studio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'KleeOne'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurpleAccent.withValues(alpha: 0.15),
                    Colors.cyanAccent.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.cyanAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'WHAT IS TYPOSYNC?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'A .typosync file packages both your project audio and JSON subtitles into a single unified file. This allows you to import everything into the main editor at once, avoiding tedious multi-step imports.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tip: You can also create this manually on your laptop by zipping the audio file and JSON file together, then renaming the extension from .zip to .typosync.',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Step 1: Pick Audio
            const Text(
              'STEP 1: SELECT AUDIO FILE',
              style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            _buildFileSelector(
              title: _audioPath != null ? p.basename(_audioPath!) : 'Choose Audio File',
              subtitle: _audioPath != null ? 'Selected' : 'Supports MP3, WAV, M4A, etc.',
              icon: Icons.audiotrack_rounded,
              color: Colors.cyanAccent,
              onTap: _pickAudio,
              isSelected: _audioPath != null,
            ),
            const SizedBox(height: 24),

            // Step 2: Pick Subtitles JSON
            const Text(
              'STEP 2: SELECT SUBTITLES (WHISPER JSON)',
              style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            _buildFileSelector(
              title: _jsonPath != null ? p.basename(_jsonPath!) : 'Choose JSON Subtitles',
              subtitle: _jsonPath != null ? 'Selected' : 'Must be Whisper JSON format',
              icon: Icons.subtitles_rounded,
              color: Colors.deepPurpleAccent,
              onTap: _pickJson,
              isSelected: _jsonPath != null,
            ),
            const SizedBox(height: 28),

            // Step 3: Package Name Input
            const Text(
              'STEP 3: PACKAGE NAME',
              style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  hintText: 'Enter package name...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  suffixText: '.typosync',
                  suffixStyle: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Package Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isPackaging ? null : _createPackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                ),
                child: _isPackaging
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.archive_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Package & Share',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04),
          width: isSelected ? 1.2 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Icon(icon, color: isSelected ? color : Colors.white24, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isSelected ? color.withValues(alpha: 0.8) : Colors.white24,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                    color: isSelected ? color : Colors.white24,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
