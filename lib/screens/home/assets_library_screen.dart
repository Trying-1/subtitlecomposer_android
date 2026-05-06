import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/asset_provider.dart';
import '../../providers/font_provider.dart';

class AssetsLibraryScreen extends StatefulWidget {
  const AssetsLibraryScreen({super.key});

  @override
  State<AssetsLibraryScreen> createState() => _AssetsLibraryScreenState();
}

class _AssetsLibraryScreenState extends State<AssetsLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingPath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudioPreview(String path) async {
    try {
      if (_playingPath == path) {
        await _audioPlayer.stop();
        setState(() => _playingPath = null);
      } else {
        await _audioPlayer.setFilePath(path);
        setState(() => _playingPath = path);
        await _audioPlayer.play();
        await _audioPlayer.stop();
        if (mounted) setState(() => _playingPath = null);
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void _renameAsset(BuildContext context, AssetProvider provider, String path) {
    final controller = TextEditingController(text: provider.getAssetName(path));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A23),
        title: const Text('Rename Asset', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.renameAsset(path, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('RENAME', style: TextStyle(color: Colors.deepPurpleAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVisualAssets(BuildContext context, AssetProvider provider, {bool isBackground = false}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'],
      allowMultiple: true,
    );
    
    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      if (isBackground) {
        provider.addBackgroundAssets(paths);
      } else {
        provider.addAssets(paths);
      }
    }
  }

  void _showPickerOptions(BuildContext context, AssetProvider provider, {bool isBackground = false}) {
     showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF14141E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IMPORT ASSETS', style: TextStyle(fontSize: 10, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            _buildPickerOption(
              icon: Icons.photo_library_rounded,
              label: 'Gallery (Photos)',
              subtitle: 'Pick multiple images or GIFs',
              onTap: () {
                Navigator.pop(context);
                _pickFromImagePicker(provider, isVideo: false, isBackground: isBackground);
              },
            ),
            const SizedBox(height: 12),
            _buildPickerOption(
              icon: Icons.video_library_rounded,
              label: 'Gallery (Videos)',
              subtitle: 'Pick video files',
              onTap: () {
                Navigator.pop(context);
                _pickFromImagePicker(provider, isVideo: true, isBackground: isBackground);
              },
            ),
             const SizedBox(height: 12),
            _buildPickerOption(
              icon: Icons.file_copy_rounded,
              label: 'Files (Browser)',
              subtitle: 'Pick any supported media',
              onTap: () {
                Navigator.pop(context);
                _pickVisualAssets(context, provider, isBackground: isBackground);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.deepPurpleAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromImagePicker(AssetProvider provider, {required bool isVideo, bool isBackground = false}) async {
    final picker = ImagePicker();
    if (isVideo) {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        if (isBackground) provider.addBackgroundAssets([video.path]);
        else provider.addAssets([video.path]);
      }
    } else {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        final paths = images.map((i) => i.path).toList();
        if (isBackground) provider.addBackgroundAssets(paths);
        else provider.addAssets(paths);
      }
    }
  }

  Future<void> _pickAudio(BuildContext context, AssetProvider provider) async {
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result != null && result.paths.isNotEmpty) {
      provider.addAudioAssets(result.paths.whereType<String>().toList());
    }
  }

  Future<void> _pickFonts(BuildContext context, FontProvider provider) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
      allowMultiple: true,
    );
    if (result != null && result.paths.isNotEmpty) {
      for (var path in result.paths.whereType<String>()) {
        await provider.importFont(path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Asset Library', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurpleAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          tabs: const [
            Tab(text: 'OVERLAYS'),
            Tab(text: 'BACKGROUNDS'),
            Tab(text: 'AUDIO & SFX'),
            Tab(text: 'FONTS'),
          ],
        ),
      ),
      body: Consumer2<AssetProvider, FontProvider>(
        builder: (context, assetProvider, fontProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildGrid(context, assetProvider.overlayAssets, (path) => assetProvider.removeAsset(path), () => _showPickerOptions(context, assetProvider)),
              _buildGrid(context, assetProvider.backgroundAssets, (path) => assetProvider.removeBackgroundAsset(path), () => _showPickerOptions(context, assetProvider, isBackground: true)),
              _buildAudioList(context, assetProvider.audioAssets, (path) => assetProvider.removeAudioAsset(path), () => _pickAudio(context, assetProvider)),
              _buildFontList(context, fontProvider.customFonts, (font) => fontProvider.deleteFont(font), () => _pickFonts(context, fontProvider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<String> paths, Function(String) onRemove, VoidCallback onAdd) {
    return Column(
      children: [
        Expanded(
          child: paths.isEmpty
              ? _buildEmptyState('No assets added yet', Icons.collections_outlined)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: paths.length,
                  itemBuilder: (context, index) {
                    final path = paths[index];
                    return _buildAssetItem(context, path, onRemove);
                  },
                ),
        ),
        _buildAddButton(onAdd),
      ],
    );
  }

  Widget _buildFontList(BuildContext context, List<CustomFont> fonts, Function(CustomFont) onRemove, VoidCallback onAdd) {
    return Column(
      children: [
        Expanded(
          child: fonts.isEmpty
              ? _buildEmptyState('No custom fonts added yet', Icons.font_download_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: fonts.length,
                  itemBuilder: (context, index) {
                    final font = fonts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              font.family,
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 18, 
                                fontFamily: font.family,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => onRemove(font),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        _buildAddButton(onAdd),
      ],
    );
  }

  Widget _buildAudioList(BuildContext context, List<String> paths, Function(String) onRemove, VoidCallback onAdd) {
    return Column(
      children: [
        Expanded(
          child: paths.isEmpty
              ? _buildEmptyState('No audio files added yet', Icons.audiotrack_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: paths.length,
                  itemBuilder: (context, index) {
                    final path = paths[index];
                    final name = context.read<AssetProvider>().getAssetName(path);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.deepPurpleAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.music_note_rounded, color: Colors.deepPurpleAccent, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _renameAsset(context, context.read<AssetProvider>(), path),
                              child: Text(
                                name,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _toggleAudioPreview(path),
                            icon: Icon(
                              _playingPath == path ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, 
                              color: _playingPath == path ? Colors.redAccent : Colors.deepPurpleAccent, 
                              size: 24,
                            ),
                          ),
                          IconButton(
                            onPressed: () => onRemove(path),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        _buildAddButton(onAdd),
      ],
    );
  }

  Widget _buildAssetItem(BuildContext context, String path, Function(String) onRemove) {
    final isVideo = path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov');
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            image: isVideo
                ? null
                : DecorationImage(
                    image: FileImage(File(path)),
                    fit: BoxFit.cover,
                  ),
          ),
          child: isVideo
              ? const Center(child: Icon(Icons.videocam_rounded, color: Colors.white38, size: 32))
              : null,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemove(path),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.redAccent, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAddButton(VoidCallback onTap) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 20),
              SizedBox(width: 8),
              Text('ADD ASSETS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
