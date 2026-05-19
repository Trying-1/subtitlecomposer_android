import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/font_provider.dart';

class ImportResult {
  final int backgroundsCount;
  final int overlaysCount;
  final int audiosCount;
  final int fontsCount;
  final List<String> importedNames;
  final List<String> warnings;

  ImportResult({
    this.backgroundsCount = 0,
    this.overlaysCount = 0,
    this.audiosCount = 0,
    this.fontsCount = 0,
    required this.importedNames,
    required this.warnings,
  });

  bool get isEmpty => backgroundsCount == 0 && overlaysCount == 0 && audiosCount == 0 && fontsCount == 0;
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
    final List<String> importedNames = [];

    final appDocDir = await getApplicationDocumentsDirectory();

    // Persistent target directories
    final targetDirs = {
      'backgrounds': Directory(p.join(appDocDir.path, 'backgrounds')),
      'overlays': Directory(p.join(appDocDir.path, 'overlays')),
      'music': Directory(p.join(appDocDir.path, 'music')),
      'sfx': Directory(p.join(appDocDir.path, 'sfx')),
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
          final count = await _importFolderFiles(
            folder: dir,
            targetDir: targetDirs['overlays']!,
            allowedExtensions: _visualExtensions,
            onImport: (path) => assetProvider.addAssets([path]),
            importedNames: importedNames,
          );
          overlays += count;
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
