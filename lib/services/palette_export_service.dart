import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/editor_models.dart';

class PaletteExportService {
  /// Exports a single palette by creating a temp file and sharing it.
  static Future<bool> exportSinglePalette(ColorPalette palette) async {
    try {
      final jsonMap = {
        'type': 'single_palette',
        'version': 1,
        'palette': palette.toJson(),
      };
      
      final jsonStr = jsonEncode(jsonMap);
      
      final tempDir = await getTemporaryDirectory();
      final safeName = palette.name.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
      final filePath = p.join(tempDir.path, '${safeName.isEmpty ? "palette" : safeName}.typopalette');
      final file = File(filePath);
      await file.writeAsString(jsonStr);
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Share Color Palette: ${palette.name}',
      );
      return true;
    } catch (e) {
      debugPrint("Error exporting single palette: $e");
      return false;
    }
  }

  /// Exports all saved palettes as a combined package file and shares it.
  static Future<bool> exportAllPalettes(List<ColorPalette> palettes) async {
    if (palettes.isEmpty) return false;
    try {
      final jsonMap = {
        'type': 'palette_package',
        'version': 1,
        'palettes': palettes.map((p) => p.toJson()).toList(),
      };
      
      final jsonStr = jsonEncode(jsonMap);
      
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, 'my_custom_palettes.typopalette');
      final file = File(filePath);
      await file.writeAsString(jsonStr);
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Share Custom Color Palettes Pack',
      );
      return true;
    } catch (e) {
      debugPrint("Error exporting all palettes: $e");
      return false;
    }
  }

  /// Launches the file picker to import custom palettes from a file.
  /// Returns a list of parsed ColorPalette objects if successful, otherwise empty.
  static Future<List<ColorPalette>> importPalettesFromFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['typopalette', 'json'],
      );

      if (result == null || result.files.single.path == null) {
        return [];
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
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

      return imported;
    } catch (e) {
      debugPrint("Error importing palettes from file: $e");
      return [];
    }
  }
}
