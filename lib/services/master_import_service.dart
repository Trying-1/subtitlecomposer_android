import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/font_provider.dart';
import '../models/editor_models.dart';

class ImportResult {
  final int backgroundsCount;
  final int overlaysCount;
  final int audiosCount;
  final int fontsCount;
  final int palettesCount;
  final List<String> importedNames;
  final List<String> warnings;

  ImportResult({
    this.backgroundsCount = 0,
    this.overlaysCount = 0,
    this.audiosCount = 0,
    this.fontsCount = 0,
    this.palettesCount = 0,
    required this.importedNames,
    required this.warnings,
  });

  bool get isEmpty => backgroundsCount == 0 && overlaysCount == 0 && audiosCount == 0 && fontsCount == 0 && palettesCount == 0;
}

class MasterImportService {
  // Allowed extensions for each asset class
  static const _visualExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.mp4', '.mov'};
  static const _audioExtensions = {'.mp3', '.wav', '.m4a', '.aac', '.ogg'};
  static const _fontExtensions = {'.ttf', '.otf'};

  String _cleanPath(String path) {
    var pStr = path;
    while (pStr.endsWith('/') || pStr.endsWith('\\')) {
      pStr = pStr.substring(0, pStr.length - 1);
    }
    return pStr;
  }

  List<Directory> _findMatchingDirectories(Directory root, {int maxDepth = 3}) {
    List<Directory> result = [];
    result.add(root); // Include the selected root itself
    _crawl(root, 1, maxDepth, result);
    return result;
  }

  void _crawl(Directory dir, int currentDepth, int maxDepth, List<Directory> result) {
    if (currentDepth > maxDepth) return;
    try {
      final entities = dir.listSync(recursive: false);
      for (final entity in entities) {
        if (FileSystemEntity.isDirectorySync(entity.path)) {
          final clean = _cleanPath(entity.path);
          final name = p.basename(clean).toLowerCase().trim();
          // Skip hidden directories and build artifacts
          if (name.startsWith('.') || name == 'android' || name == 'ios' || name == 'build') {
            continue;
          }
          final subDir = Directory(entity.path);
          result.add(subDir);
          _crawl(subDir, currentDepth + 1, maxDepth, result);
        }
      }
    } catch (e) {
      // Ignore reading/permission errors for nested system folders
    }
  }

  /// Selects and imports a master folder containing subfolders of assets.
  /// Categorizes files dynamically based on subfolder naming conventions.
  Future<ImportResult> importMasterFolder({
    required String masterPath,
    required AssetProvider assetProvider,
    required FontProvider fontProvider,
  }) async {
    final masterDir = Directory(masterPath);
    final List<String> warnings = [];

    if (!masterDir.existsSync()) {
      warnings.add('Selected directory does not exist or is inaccessible.');
      return ImportResult(
        warnings: warnings,
        importedNames: [],
      );
    }

    int backgrounds = 0;
    int overlays = 0;
    int audios = 0;
    int fonts = 0;
    int palettes = 0;
    final List<String> importedNames = [];

    final appDocDir = await getApplicationDocumentsDirectory();

    // Persistent target directories
    final targetDirs = {
      'backgrounds': Directory(p.join(appDocDir.path, 'backgrounds')),
      'overlays': Directory(p.join(appDocDir.path, 'overlays')),
      'music': Directory(p.join(appDocDir.path, 'music')),
      'sfx': Directory(p.join(appDocDir.path, 'sfx')),
      'palettes': Directory(p.join(appDocDir.path, 'palettes')),
    };

    // Ensure target directories exist
    for (var dir in targetDirs.values) {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }

    try {
      final directoriesToProcess = _findMatchingDirectories(masterDir);
      final processedPaths = <String>{};

      for (final dir in directoriesToProcess) {
        final cleanPathStr = _cleanPath(dir.path);
        if (!processedPaths.add(cleanPathStr)) continue;

        final dirName = p.basename(cleanPathStr).toLowerCase().trim();
        
        if (_isBackgroundDir(dirName)) {
          final count = await _importFolderFiles(
            folder: dir,
            targetDir: targetDirs['backgrounds']!,
            allowedExtensions: _visualExtensions,
            onImport: (path) => assetProvider.addBackgroundAssets([path]),
            importedNames: importedNames,
          );
          backgrounds += count;
        } else if (_isOverlayDir(dirName)) {
          // 1. Process files directly inside the primary overlays directory
          final countDirect = await _importFolderFiles(
            folder: dir,
            targetDir: targetDirs['overlays']!,
            allowedExtensions: _visualExtensions,
            onImport: (path) => assetProvider.addAssets([path]),
            importedNames: importedNames,
          );
          overlays += countDirect;

          // 2. Scan and process any subfolders under this overlays folder
          try {
            final entities = dir.listSync(recursive: false);
            for (final entity in entities) {
              if (FileSystemEntity.isDirectorySync(entity.path)) {
                final subDir = Directory(entity.path);
                final subDirCleanPath = _cleanPath(subDir.path);
                processedPaths.add(subDirCleanPath); // Mark processed to avoid duplicates

                final subDirName = p.basename(subDirCleanPath);

                // Create category-specific target subdirectory
                final targetSubDir = Directory(p.join(targetDirs['overlays']!.path, subDirName));
                if (!targetSubDir.existsSync()) {
                  targetSubDir.createSync(recursive: true);
                }

                final countSub = await _importFolderFiles(
                  folder: subDir,
                  targetDir: targetSubDir,
                  allowedExtensions: _visualExtensions,
                  onImport: (path) => assetProvider.addAssets([path]),
                  importedNames: importedNames,
                );
                overlays += countSub;
              }
            }
          } catch (e) {
            warnings.add('Failed to process subfolders of overlays folder: $e');
          }
        } else if (_isMusicDir(dirName)) {
          final count = await _importFolderFiles(
            folder: dir,
            targetDir: targetDirs['music']!,
            allowedExtensions: _audioExtensions,
            onImport: (path) => assetProvider.addMusicAssets([path]),
            importedNames: importedNames,
          );
          audios += count;
        } else if (_isSfxDir(dirName)) {
          final count = await _importFolderFiles(
            folder: dir,
            targetDir: targetDirs['sfx']!,
            allowedExtensions: _audioExtensions,
            onImport: (path) => assetProvider.addSfxAssets([path]),
            importedNames: importedNames,
          );
          audios += count;
        } else if (_isFontDir(dirName)) {
          try {
            final entities = dir.listSync(recursive: false);
            for (final entity in entities) {
              if (FileSystemEntity.isDirectorySync(entity.path)) continue;
              final ext = p.extension(entity.path).toLowerCase();
              if (_fontExtensions.contains(ext)) {
                try {
                  final baseName = p.basename(entity.path);
                  await fontProvider.importFont(entity.path);
                  fonts++;
                  importedNames.add('Font: $baseName');
                } catch (e) {
                  warnings.add('Failed to import font $entity: $e');
                }
              }
            }
          } catch (e) {
            warnings.add('Failed to read font folder ${p.basename(dir.path)}: $e');
          }
        } else if (_isPaletteDir(dirName)) {
          try {
            final entities = dir.listSync(recursive: false);
            for (final entity in entities) {
              if (FileSystemEntity.isDirectorySync(entity.path)) continue;
              final ext = p.extension(entity.path).toLowerCase();
              if (ext == '.typopalette' || ext == '.json') {
                try {
                  final baseName = p.basename(entity.path);
                  final targetPath = p.join(targetDirs['palettes']!.path, baseName);
                  
                  // Copy to persistent folder
                  await File(entity.path).copy(targetPath);
                  
                  // Parse palette and import into Hive
                  final content = await File(entity.path).readAsString();
                  final jsonMap = jsonDecode(content) as Map<String, dynamic>;
                  final type = jsonMap['type'] as String?;
                  final List<ColorPalette> imported = [];

                  if (type == 'single_palette') {
                    final paletteData = jsonMap['palette'];
                    if (paletteData != null) {
                      imported.add(ColorPalette.fromJson(Map<String, dynamic>.from(paletteData)));
                    }
                  } else if (type == 'palette_package') {
                    final palettesList = jsonMap['palettes'] as List?;
                    if (palettesList != null) {
                      for (var item in palettesList) {
                        imported.add(ColorPalette.fromJson(Map<String, dynamic>.from(item)));
                      }
                    }
                  } else {
                    // Fallback: Check if it's a raw array of palettes
                    if (jsonMap.containsKey('colors') && jsonMap.containsKey('name')) {
                      imported.add(ColorPalette.fromJson(jsonMap));
                    } else if (jsonMap.containsKey('palettes') && jsonMap['palettes'] is List) {
                      final palettesList = jsonMap['palettes'] as List;
                      for (var item in palettesList) {
                        imported.add(ColorPalette.fromJson(Map<String, dynamic>.from(item)));
                      }
                    }
                  }

                  if (imported.isNotEmpty) {
                    final count = assetProvider.importPalettes(imported);
                    if (count > 0) {
                      palettes += count;
                      importedNames.add('Palettes: $baseName (+$count)');
                    }
                  }
                } catch (e) {
                  warnings.add('Failed to import palette $entity: $e');
                }
              }
            }
          } catch (e) {
            warnings.add('Failed to read palette folder ${p.basename(dir.path)}: $e');
          }
        }
      }
    } catch (e) {
      warnings.add('ERROR during directory crawling/parsing: $e');
    }

    return ImportResult(
      backgroundsCount: backgrounds,
      overlaysCount: overlays,
      audiosCount: audios,
      fontsCount: fonts,
      palettesCount: palettes,
      importedNames: importedNames,
      warnings: warnings,
    );
  }

  // --- Subfolder Identification Utilities ---

  bool _isBackgroundDir(String name) =>
      name == 'background' || name == 'backgrounds' || name == 'bg';

  bool _isOverlayDir(String name) =>
      name == 'overlay' || name == 'overlays' || name == 'overlay_assets' || name == 'sticker' || name == 'stickers';

  bool _isMusicDir(String name) =>
      name == 'music' || name == 'sound' || name == 'sounds' || name == 'audio' || name == 'audios';

  bool _isSfxDir(String name) =>
      name == 'sfx' || name == 'effects';

  bool _isFontDir(String name) =>
      name == 'font' || name == 'fonts';

  bool _isPaletteDir(String name) =>
      name == 'palette' || name == 'palettes' || name == 'color' || name == 'colors';

  // --- Helper file importer and copy executor ---

  Future<int> _importFolderFiles({
    required Directory folder,
    required Directory targetDir,
    required Set<String> allowedExtensions,
    required Function(String) onImport,
    required List<String> importedNames,
  }) async {
    int count = 0;
    try {
      final entities = folder.listSync(recursive: false);
      for (final entity in entities) {
        if (FileSystemEntity.isDirectorySync(entity.path)) continue;
        final ext = p.extension(entity.path).toLowerCase();
        if (allowedExtensions.contains(ext)) {
          try {
            final fileName = p.basename(entity.path);
            final targetPath = p.join(targetDir.path, fileName);
            
            // Persistent Copy
            await File(entity.path).copy(targetPath);
            onImport(targetPath);
            count++;
            importedNames.add(fileName);
          } catch (e) {
            // Quiet fail
          }
        }
      }
    } catch (e) {
      // Quiet fail
    }
    return count;
  }
}
