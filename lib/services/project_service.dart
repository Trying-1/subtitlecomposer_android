import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../models/editor_models.dart';
import '../providers/font_provider.dart';

class ProjectService {
  static const String _boxName = 'projects';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<void> saveProject(Project project) async {
    final box = Hive.box(_boxName);
    await box.put(project.id, project.toJson());
  }

  static Future<void> deleteProject(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }

  static List<Project> getAllProjects() {
    final box = Hive.box(_boxName);
    return box.values.map((v) => Project.fromJson(Map<String, dynamic>.from(v))).toList()
      ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  static Project? getProject(String id) {
    final box = Hive.box(_boxName);
    final data = box.get(id);
    if (data == null) return null;
    return Project.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<void> duplicateProject(String id) async {
    final project = getProject(id);
    if (project != null) {
      final newProject = project.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${project.name} Copy',
        lastModified: DateTime.now(),
      );
      await saveProject(newProject);
    }
  }

  static Future<void> exportProject(Project project) async {
    final archive = Archive();
    final Map<String, String> assetMap = {}; // Original Path -> Archive Name

    void addAsset(String? path) {
      if (path != null && path.isNotEmpty && !assetMap.containsKey(path)) {
        final file = File(path);
        if (file.existsSync()) {
          final name = 'assets/${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}';
          assetMap[path] = name;
          final bytes = file.readAsBytesSync();
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }
    }

    // Collect all assets
    addAsset(project.videoPath);
    addAsset(project.backgroundImagePath);
    for (var track in project.tracks) {
      for (var clip in track.overlays) {
        addAsset(clip.imagePath);
      }
      for (var clip in track.backgrounds) {
        addAsset(clip.imagePath);
      }
      for (var clip in track.audioClips) {
        addAsset(clip.audioPath);
      }
    }

    // Package any custom fonts used in subtitle clips
    try {
      final fontBox = Hive.box('font_box');
      final savedFonts = fontBox.get('fonts', defaultValue: []) as List;
      final List<Map<String, dynamic>> customFonts = savedFonts
          .map((f) => Map<String, dynamic>.from(f as Map))
          .toList();

      final Map<String, String> fontMap = {}; // Font Family -> Font Local Path
      for (var font in customFonts) {
        final family = font['family'] as String?;
        final path = font['path'] as String?;
        if (family != null && path != null) {
          fontMap[family] = path;
        }
      }

      final Set<String> packagedFonts = {};
      for (var track in project.tracks) {
        for (var clip in track.clips) {
          final family = clip.fontFamily;
          if (fontMap.containsKey(family) && !packagedFonts.contains(family)) {
            final fontPath = fontMap[family]!;
            final fontFile = File(fontPath);
            if (fontFile.existsSync()) {
              packagedFonts.add(family);
              final ext = p.extension(fontPath);
              final archiveName = 'fonts/$family$ext';
              final bytes = fontFile.readAsBytesSync();
              archive.addFile(ArchiveFile(archiveName, bytes.length, bytes));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error collecting custom fonts for export: $e');
    }

    // Update Project with archive paths
    final exportedProject = project.copyWith(
      videoPath: assetMap[project.videoPath] ?? project.videoPath,
      backgroundImagePath: assetMap[project.backgroundImagePath] ?? project.backgroundImagePath,
      tracks: project.tracks.map((t) {
        return t.copyWith(
          overlays: t.overlays.map((c) => c.copyWith(imagePath: assetMap[c.imagePath] ?? c.imagePath)).toList(),
          backgrounds: t.backgrounds.map((c) => c.copyWith(imagePath: assetMap[c.imagePath] ?? c.imagePath)).toList(),
          audioClips: t.audioClips.map((c) => c.copyWith(audioPath: assetMap[c.audioPath] ?? c.audioPath)).toList(),
        );
      }).toList(),
    );

    final jsonStr = jsonEncode(exportedProject.toJson());
    archive.addFile(ArchiveFile('project.json', jsonStr.length, utf8.encode(jsonStr)));

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    
    if (zipData.isEmpty) return;

    final directory = await getTemporaryDirectory();
    final safeName = project.name.replaceAll(RegExp(r'[^\w\s-]'), '_');
    final file = File('${directory.path}/$safeName.typo');
    await file.writeAsBytes(zipData);
    
    await Share.shareXFiles([XFile(file.path)], text: 'Exporting Typo Edit Project: ${project.name}');
  }

  static Future<bool> importProject(BuildContext context) async {
    final fontProvider = Provider.of<FontProvider>(context, listen: false);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['typo', 'zip'],
      );
      if (result != null && result.files.single.path != null) {
        final bytes = File(result.files.single.path!).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        final projectFile = archive.findFile('project.json');
        if (projectFile == null) return false;
        
        final projectJson = utf8.decode(projectFile.content as List<int>);
        final projectData = jsonDecode(projectJson);
        var project = Project.fromJson(Map<String, dynamic>.from(projectData));

        final appDir = await getApplicationDocumentsDirectory();
        final assetDir = Directory('${appDir.path}/imported_assets/${project.id}');
        if (!assetDir.existsSync()) assetDir.createSync(recursive: true);

        final Map<String, String> pathMap = {}; // Archive Path -> New Local Path

        for (var file in archive) {
          if (file.name.startsWith('assets/')) {
            final localFile = File('${assetDir.path}/${p.basename(file.name)}');
            localFile.writeAsBytesSync(file.content as List<int>);
            pathMap[file.name] = localFile.path;
          } else if (file.name.startsWith('fonts/')) {
            final tempDir = await getTemporaryDirectory();
            final tempFontPath = '${tempDir.path}/${p.basename(file.name)}';
            final tempFile = File(tempFontPath);
            tempFile.writeAsBytesSync(file.content as List<int>);
            try {
              await fontProvider.importFont(tempFontPath);
            } catch (fe) {
              debugPrint('Error importing packaged font ${file.name}: $fe');
            }
            try {
              if (tempFile.existsSync()) {
                tempFile.deleteSync();
              }
            } catch (_) {}
          }
        }

        // Update Project with new local paths
        final importedProject = project.copyWith(
          id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
          name: '${project.name} (Imported)',
          lastModified: DateTime.now(),
          videoPath: pathMap[project.videoPath] ?? project.videoPath,
          backgroundImagePath: pathMap[project.backgroundImagePath] ?? project.backgroundImagePath,
          tracks: project.tracks.map((t) {
            return t.copyWith(
              overlays: t.overlays.map((c) => c.copyWith(imagePath: pathMap[c.imagePath] ?? c.imagePath)).toList(),
              backgrounds: t.backgrounds.map((c) => c.copyWith(imagePath: pathMap[c.imagePath] ?? c.imagePath)).toList(),
              audioClips: t.audioClips.map((c) => c.copyWith(audioPath: pathMap[c.audioPath] ?? c.audioPath)).toList(),
            );
          }).toList(),
        );

        await saveProject(importedProject);
        return true;
      }
    } catch (e) {
      debugPrint('Error importing project: $e');
    }
    return false;
  }
}
