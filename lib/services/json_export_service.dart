import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/editor_models.dart';

class JsonExportService {
  static Future<bool> exportToJson(Project project) async {
    try {
      final List<Map<String, dynamic>> subtitleList = [];
      
      // Collect and sort all subtitle clips by startTime
      final List<SubtitleClip> clips = [];
      for (var track in project.tracks) {
        for (var clip in track.clips) {
          clips.add(clip);
        }
      }
      clips.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      for (var clip in clips) {
        subtitleList.add({
          'text': clip.text,
          'startMs': clip.startTime.inMilliseconds,
          'endMs': clip.endTime.inMilliseconds,
          'fontFamily': clip.fontFamily,
          'fontSize': clip.fontSize,
          'color': '0x${clip.color.toRadixString(16).padLeft(8, '0').toUpperCase()}',
          'x': clip.x,
          'y': clip.y,
          'rotation': clip.rotation,
          'scale': clip.scale,
          'opacity': clip.textOpacity,
          'isStrokeEnabled': clip.isStrokeEnabled,
          'strokeColor': '0x${clip.strokeColor.toRadixString(16).padLeft(8, '0').toUpperCase()}',
          'strokeWidth': clip.strokeWidth,
          'isShadowEnabled': clip.isShadowEnabled,
          'shadowColor': '0x${clip.shadowColor.toRadixString(16).padLeft(8, '0').toUpperCase()}',
          'shadowOffsetX': clip.shadowOffsetX,
          'shadowOffsetY': clip.shadowOffsetY,
          'entranceAnimation': clip.entranceAnimation.type.toString().split('.').last,
          'exitAnimation': clip.exitAnimation.type.toString().split('.').last,
        });
      }
      
      final Map<String, dynamic> exportData = {
        'projectName': project.name,
        'exportTime': DateTime.now().toIso8601String(),
        'subtitles': subtitleList,
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      final tempDir = await getTemporaryDirectory();
      final safeName = project.name.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final jsonFile = File('${tempDir.path}/$safeName.json');
      await jsonFile.writeAsString(jsonString);
      
      await Share.shareXFiles([XFile(jsonFile.path)], text: 'Exported Subtitles JSON: ${project.name}');
      return true;
    } catch (e) {
      debugPrint('Error exporting to JSON: $e');
      return false;
    }
  }
}
