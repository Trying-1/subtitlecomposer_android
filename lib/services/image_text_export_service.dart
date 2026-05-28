import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class ImageTextExportService {
  /// Exports a single project by sharing it as a .typostudio file.
  static Future<bool> exportProject(Map<String, dynamic> project) async {
    try {
      final jsonMap = {
        'type': 'single_image_text_project',
        'version': 1,
        'project': project,
      };
      
      final jsonStr = jsonEncode(jsonMap);
      
      final tempDir = await getTemporaryDirectory();
      final name = project['name'] ?? 'Untitled Poster';
      final safeName = name.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
      final filePath = p.join(tempDir.path, '${safeName.isEmpty ? "project" : safeName}.typostudio');
      final file = File(filePath);
      await file.writeAsString(jsonStr);
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Share Poster Project: $name',
      );
      return true;
    } catch (e) {
      debugPrint("Error exporting project: $e");
      return false;
    }
  }

  /// Imports project(s) from a picked file.
  /// Returns a list of parsed project maps if successful, otherwise empty list.
  static Future<List<Map<String, dynamic>>> importProjectsFromFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['typostudio', 'json'],
      );

      if (result == null || result.files.single.path == null) {
        return [];
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;

      final type = jsonMap['type'] as String?;
      final List<Map<String, dynamic>> imported = [];

      if (type == 'single_image_text_project') {
        final projectData = jsonMap['project'];
        if (projectData != null) {
          imported.add(Map<String, dynamic>.from(projectData));
        }
      } else {
        // Fallback: Check if it is a raw map representing a project
        if (jsonMap.containsKey('canvasBgColorValue') || jsonMap.containsKey('customText')) {
          imported.add(jsonMap);
        }
      }

      return imported;
    } catch (e) {
      debugPrint("Error importing projects from file: $e");
      return [];
    }
  }
}
