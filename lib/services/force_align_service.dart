import 'native_bridge.dart';

class ForceAlignService {
  final NativeBridge _bridge = NativeBridge();

  Future<List<Map<String, dynamic>>> alignText(String text, String audioPath) async {
    // 1. Get Speech Segments from VAD
    final segments = await _bridge.getSpeechSegments(audioPath);
    if (segments.isEmpty) {
      // Fallback: If no speech detected, return empty or handle error
      return [];
    }

    // 2. Tokenize Text into Words
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [];

    // 3. Align words across segments using character-weighted distribution
    final List<Map<String, dynamic>> result = [];
    
    // Calculate total character count and total speech duration
    int totalChars = 0;
    for (var word in words) {
      totalChars += word.length;
    }

    double totalSpeechMs = 0;
    for (var seg in segments) {
      totalSpeechMs += (seg['end'] - seg['start']);
    }

    if (totalSpeechMs <= 0 || totalChars <= 0) return [];

    int wordIdx = 0;
    int charsProcessed = 0;

    for (int sIdx = 0; sIdx < segments.length; sIdx++) {
      final seg = segments[sIdx];
      final startMs = seg['start'] as double;
      final endMs = seg['end'] as double;
      final segDuration = endMs - startMs;
      
      // Calculate how many characters fit in this segment proportionally
      final double weight = segDuration / totalSpeechMs;
      final targetCharsInSeg = weight * totalChars;
      
      final actualWords = <String>[];
      int currentSegChars = 0;

      // Fill this segment with words until we hit the character target
      while (wordIdx < words.length) {
        final word = words[wordIdx];
        
        // If it's the last segment, take all remaining words
        if (sIdx == segments.length - 1) {
          actualWords.add(words[wordIdx++]);
          continue;
        }

        // If adding this word keeps us close to the target, or if it's the first word in a segment
        if (actualWords.isEmpty || (currentSegChars + word.length) <= targetCharsInSeg * 1.1) {
          actualWords.add(words[wordIdx++]);
          currentSegChars += word.length;
        } else {
          // This word belongs in the next segment
          break;
        }
      }

      if (actualWords.isNotEmpty) {
        // Distribute words WITHIN the segment based on their own character weights
        int segTotalChars = 0;
        for (var w in actualWords) segTotalChars += w.length;

        double currentWStart = startMs;
        for (int i = 0; i < actualWords.length; i++) {
          final word = actualWords[i];
          final double wWeight = word.length / segTotalChars;
          final double wDuration = wWeight * segDuration;
          
          result.add({
            'start': currentWStart.toInt(),
            'end': (currentWStart + wDuration).toInt(),
            'text': word,
          });
          currentWStart += wDuration;
        }
      }
    }

    return result;
  }
}
