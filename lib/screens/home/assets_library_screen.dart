import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../providers/asset_provider.dart';
import '../../providers/font_provider.dart';
import '../../providers/editor_provider.dart';
import '../../models/editor_models.dart';
import '../../widgets/common/custom_color_picker.dart';
import '../../widgets/common/image_color_picker.dart';
import '../../utils/palette_presets.dart';
import '../../services/master_import_service.dart';
import '../../services/native_bridge.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';

class AssetsLibraryScreen extends StatefulWidget {
  const AssetsLibraryScreen({super.key});

  @override
  State<AssetsLibraryScreen> createState() => _AssetsLibraryScreenState();
}

class _AssetsLibraryScreenState extends State<AssetsLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingPath;
  bool _isMasterImportAvailable = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _checkMasterImportAvailability();
  }

  Future<void> _checkMasterImportAvailability() async {
    final available = await NativeBridge().isStoragePermissionDeclared();
    if (mounted) {
      setState(() {
        _isMasterImportAvailable = available;
      });
    }
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
    final editorProvider = context.read<EditorProvider>();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'],
      allowMultiple: true,
      initialDirectory: editorProvider.lastUsedDirectory,
    );
    
    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      editorProvider.updateLastUsedDirectory(paths.first);
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

  Future<void> _pickAudio(BuildContext context, AssetProvider provider, {required bool isSfx}) async {
    final editorProvider = context.read<EditorProvider>();
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
      initialDirectory: editorProvider.lastUsedDirectory,
    );
    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      editorProvider.updateLastUsedDirectory(paths.first);
      if (isSfx) {
        provider.addSfxAssets(paths);
      } else {
        provider.addMusicAssets(paths);
      }
    }
  }

  bool _isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  bool _isVideo(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', '3gp', 'avi', 'mkv', 'webm'].contains(ext);
  }

  Future<void> _pickFonts(BuildContext context, FontProvider provider) async {
    final editorProvider = context.read<EditorProvider>();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
      allowMultiple: true,
      initialDirectory: editorProvider.lastUsedDirectory,
    );
    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      editorProvider.updateLastUsedDirectory(paths.first);
      for (var path in paths) {
        await provider.importFont(path);
      }
    }
  }

  Future<void> _extractPaletteFromImage(BuildContext context, AssetProvider provider) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Show a loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
      );
    }

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(File(image.path)),
        maximumColorCount: 20,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        final initialColors = paletteGenerator.colors.take(8).toList();
        
        // Open Manual Picker
        final List<Color>? finalColors = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageColorPickerScreen(
              imageFile: File(image.path),
              initialColors: initialColors,
            ),
          ),
        );

        if (mounted && finalColors != null && finalColors.isNotEmpty) {
          _showAddPaletteDialog(context, provider, initialColors: finalColors, initialName: 'Image Palette');
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error extracting palette: $e");
    }
  }

  void _showAddPaletteDialog(BuildContext context, AssetProvider provider, {List<Color>? initialColors, String? initialName}) {
    final nameController = TextEditingController(text: initialName);
    List<Color> selectedColors = initialColors ?? [Colors.white, Colors.deepPurpleAccent, Colors.blueAccent];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Color(0xFF14141E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CREATE PALETTE', style: TextStyle(fontSize: 10, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                autofocus: initialColors == null,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Palette Name',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text('COLORS', style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...selectedColors.asMap().entries.map((entry) => GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CustomColorPicker(
                          initialColor: entry.value,
                          onColorChanged: (color) {
                            setModalState(() {
                              selectedColors[entry.key] = color;
                            });
                          },
                        ),
                      );
                    },
                    onLongPress: () {
                      if (selectedColors.length > 1) {
                        setModalState(() => selectedColors.removeAt(entry.key));
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                  )),
                  GestureDetector(
                    onTap: () {
                      if (selectedColors.length < 8) {
                        setModalState(() => selectedColors.add(Colors.white));
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white38),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      provider.savePalette(name, selectedColors.map((c) => c.value).toList());
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('CREATE PALETTE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importMasterFolder(
    BuildContext context,
    AssetProvider assetProvider,
    FontProvider fontProvider,
  ) async {
    try {
      final bridge = NativeBridge();
      bool hasPermission = await bridge.checkStoragePermission();
      if (!hasPermission) {
        if (!mounted) return;
        final bool proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF14141E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.folder_shared_rounded, color: Colors.deepPurpleAccent),
                SizedBox(width: 12),
                Text('Storage Access Required', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'On modern Android, raw directory crawling of external/SD card folders requires "All Files Access" permission. Please grant this permission on the next screen to proceed.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                child: const Text('GRANT ACCESS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ?? false;
        
        if (!proceed) return;
        
        await bridge.requestStoragePermission();
        
        await Future.delayed(const Duration(milliseconds: 1500));
        hasPermission = await bridge.checkStoragePermission();
        if (!hasPermission) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage access permission is required to import external folders.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      final String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            color: Color(0xFF14141E),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurpleAccent),
                  SizedBox(height: 16),
                  Text(
                    'Importing master folder...',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Organizing and copying assets...',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final importService = MasterImportService();
      final result = await importService.importMasterFolder(
        masterPath: selectedDirectory,
        assetProvider: assetProvider,
        fontProvider: fontProvider,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      _showImportResultDialog(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing master folder: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImportResultDialog(BuildContext context, ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14141E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.drive_folder_upload_rounded, color: Colors.deepPurpleAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Import Summary',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No valid subfolders (backgrounds, overlays, audio, fonts) or compatible assets found to import.',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  )
                else ...[
                  const Text(
                    'Successfully imported assets to your library:',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _buildResultRow(Icons.photo_size_select_actual_rounded, 'Backgrounds', result.backgroundsCount),
                  const SizedBox(height: 10),
                  _buildResultRow(Icons.layers_rounded, 'Overlays', result.overlaysCount),
                  const SizedBox(height: 10),
                  _buildResultRow(Icons.music_note_rounded, 'Audio & SFX', result.audiosCount),
                  const SizedBox(height: 10),
                  _buildResultRow(Icons.font_download_rounded, 'Fonts', result.fontsCount),
                ],
                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'LOGS & WARNINGS',
                    style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: result.warnings.length,
                      itemBuilder: (context, idx) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• ${result.warnings[idx]}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT', style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, int count) {
    return Row(
      children: [
        Icon(icon, color: count > 0 ? Colors.greenAccent : Colors.white24, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: count > 0 ? Colors.white : Colors.white38,
              fontSize: 13,
              fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: count > 0 ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '+$count',
            style: TextStyle(
              color: count > 0 ? Colors.greenAccent : Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.read<AssetProvider>();
    final fontProvider = context.read<FontProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Asset Library', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          if (_isMasterImportAvailable)
            IconButton(
              icon: const Icon(Icons.drive_folder_upload_rounded, color: Colors.deepPurpleAccent),
              tooltip: 'Import Master Folder',
              onPressed: () => _importMasterFolder(context, assetProvider, fontProvider),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurpleAccent,
          isScrollable: true,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          tabs: const [
            Tab(text: 'OVERLAY IMAGES'),
            Tab(text: 'OVERLAY VIDEOS'),
            Tab(text: 'BACKGROUND IMAGES'),
            Tab(text: 'BACKGROUND VIDEOS'),
            Tab(text: 'MUSIC'),
            Tab(text: 'SFX'),
            Tab(text: 'FONTS'),
            Tab(text: 'PALETTES'),
          ],
        ),
      ),
      body: Consumer2<AssetProvider, FontProvider>(
        builder: (context, assetProvider, fontProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Overlay Images
              _buildGrid(
                context, 
                assetProvider.overlayAssets.where((p) => _isImage(p)).toList(), 
                (path) => assetProvider.removeAsset(path), 
                () => _showPickerOptions(context, assetProvider, isBackground: false)
              ),
              // 2. Overlay Videos
              _buildGrid(
                context, 
                assetProvider.overlayAssets.where((p) => _isVideo(p)).toList(), 
                (path) => assetProvider.removeAsset(path), 
                () => _showPickerOptions(context, assetProvider, isBackground: false)
              ),
              // 3. Background Images
              _buildGrid(
                context, 
                assetProvider.backgroundAssets.where((p) => _isImage(p)).toList(), 
                (path) => assetProvider.removeBackgroundAsset(path), 
                () => _showPickerOptions(context, assetProvider, isBackground: true)
              ),
              // 4. Background Videos
              _buildGrid(
                context, 
                assetProvider.backgroundAssets.where((p) => _isVideo(p)).toList(), 
                (path) => assetProvider.removeBackgroundAsset(path), 
                () => _showPickerOptions(context, assetProvider, isBackground: true)
              ),
              // 5. Music
              _buildAudioList(
                context, 
                assetProvider.musicAssets, 
                (path) => assetProvider.removeMusicAsset(path), 
                () => _pickAudio(context, assetProvider, isSfx: false)
              ),
              // 6. SFX
              _buildAudioList(
                context, 
                assetProvider.sfxAssets, 
                (path) => assetProvider.removeSfxAsset(path), 
                () => _pickAudio(context, assetProvider, isSfx: true)
              ),
              // 7. Fonts
              _buildFontList(context, fontProvider.customFonts, (font) => fontProvider.deleteFont(font), () => _pickFonts(context, fontProvider)),
              // 8. Palettes
              _buildPalettesTab(assetProvider),
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
        _buildAddButton('ADD ASSETS', onAdd),
      ],
    );
  }

  Widget _buildPalettesTab(AssetProvider provider) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.deepPurpleAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'SAVED'),
                Tab(text: 'PRESETS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSavedPalettes(provider),
                _buildPresetPalettes(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPalettes(AssetProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(child: _buildAddButton('CREATE', () => _showAddPaletteDialog(context, provider))),
              const SizedBox(width: 12),
              Expanded(child: _buildAddButton('EXTRACT', () => _extractPaletteFromImage(context, provider), icon: Icons.colorize_rounded)),
            ],
          ),
        ),
        Expanded(
          child: provider.palettes.isEmpty
              ? _buildEmptyState('No palettes saved yet', Icons.palette_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: provider.palettes.length,
                  itemBuilder: (context, index) {
                    final palette = provider.palettes[index];
                    return _buildPaletteItem(palette, () => provider.deletePalette(palette.id), isPreset: false);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPresetPalettes(AssetProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: PalettePresets.categories.length,
      itemBuilder: (context, catIndex) {
        final category = PalettePresets.categories[catIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
              child: Text(category.name, style: const TextStyle(fontSize: 9, color: Colors.deepPurpleAccent, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
            ...category.palettes.map((palette) => _buildPaletteItem(
              palette, 
              () {
                provider.savePalette(palette.name, palette.colors);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved "${palette.name}" to your library'),
                    backgroundColor: Colors.deepPurpleAccent,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              isPreset: true,
            )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildPaletteItem(ColorPalette palette, VoidCallback onAction, {required bool isPreset}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(palette.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(isPreset ? Icons.add_circle_outline_rounded : Icons.delete_outline_rounded, 
                  color: isPreset ? Colors.deepPurpleAccent : Colors.redAccent.withOpacity(0.5), 
                  size: 20),
                onPressed: onAction,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: palette.colors.map((c) => Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Color(c),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white10, width: 0.5),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
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
        _buildAddButton('ADD FONTS', onAdd),
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
        _buildAddButton('ADD AUDIO', onAdd),
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

  Widget _buildAddButton(String label, VoidCallback onTap, {IconData? icon, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon ?? Icons.add_rounded, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
