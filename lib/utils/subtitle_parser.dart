import 'dart:convert';
import '../models/editor_models.dart';
import 'package:uuid/uuid.dart';

class SubtitleParser {
  static const _uuid = Uuid();

  /// Parses JSON transcription (Whisper format)
  /// Expected: [{"start": 0.0, "end": 2.0, "text": "..."}, ...]
  static List<SubtitleClip> parseJson(String content) {
    final List<dynamic> data = jsonDecode(content);
    return data.map((item) {
      return SubtitleClip(
        id: _uuid.v4(),
        text: item['text'] ?? '',
        startTime: Duration(milliseconds: ((item['start'] as num) * 1000).toInt()),
        endTime: Duration(milliseconds: ((item['end'] as num) * 1000).toInt()),
      );
    }).toList();
  }

  /// Parses ASS subtitle files
  /// Very basic implementation focused on Dialogue lines
  static List<SubtitleClip> parseAss(String content) {
    final List<SubtitleClip> clips = [];
    final lines = content.split('\n');
    
    for (var line in lines) {
      if (line.startsWith('Dialogue:')) {
        final parts = line.split(',');
        if (parts.length >= 10) {
          final startStr = parts[1].trim();
          final endStr = parts[2].trim();
          final text = parts.sublist(9).join(',').trim();

          clips.add(SubtitleClip(
            id: _uuid.v4(),
            text: _stripAssTags(text),
            startTime: _parseAssTime(startStr),
            endTime: _parseAssTime(endStr),
          ));
        }
      }
    }
    return clips;
  }

  static Duration _parseAssTime(String timeStr) {
    // Format: H:MM:SS.CC
    final parts = timeStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split('.');
    final seconds = int.parse(secondsParts[0]);
    final centiseconds = int.parse(secondsParts[1]);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: centiseconds * 10,
    );
  }

  static String _stripAssTags(String text) {
    // Remove tags like {\fnArial\fs20}
    return text.replaceAll(RegExp(r'\{.*?\}'), '');
  }
}
