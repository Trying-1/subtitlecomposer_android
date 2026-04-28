import 'package:flutter/foundation.dart';

class TransliterationUtils {
  /// Simple Phonetic Devanagari to Roman Transliteration
  /// This handles core characters, matras, and conjuncts.
  static String devanagariToRoman(String input) {
    if (input.isEmpty) return input;

    // 1. Pre-sanitize: Simplify accented Latin characters that Whisper sometimes hallucinations
    input = _normalizeAccentedChars(input);

    final Map<String, String> vowels = {
      'अ': 'a', 'आ': 'a', 'इ': 'i', 'ई': 'i', 'उ': 'u', 'ऊ': 'u',
      'ऋ': 'ri', 'ए': 'e', 'ै': 'ai', 'ओ': 'o', 'औ': 'au',
    };

    final Map<String, String> consonants = {
      'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'n',
      'च': 'ch', 'छ': 'ch', 'ज': 'j', 'झ': 'jh', 'ञ': 'n',
      'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
      'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
      'प': 'p', 'फ': 'f', 'ब': 'b', 'भ': 'bh', 'म': 'm',
      'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'v', 'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
      'ड़': 'd', 'ढ़': 'dh', 'क्ष': 'ksh', 'त्र': 'tr', 'ज्ञ': 'gy',
      'फ़': 'f', 'ज़': 'z', 'क़': 'q', 'ख़': 'kh', 'ग़': 'g',
    };

    final Map<String, String> matras = {
      'ा': 'a', 'ि': 'i', 'ी': 'i', 'ु': 'u', 'ू': 'u',
      'ृ': 'ri', 'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au',
      'ं': 'n', 'ः': 'h', 'ँ': 'n',
    };

    final String halant = '्';

    StringBuffer result = StringBuffer();
    List<int> runes = input.runes.toList();

    for (int i = 0; i < runes.length; i++) {
      String char = String.fromCharCode(runes[i]);
      
      // Look ahead for nukta (़)
      if (i + 1 < runes.length && String.fromCharCode(runes[i + 1]) == '़') {
        String withNukta = char + '़';
        if (consonants.containsKey(withNukta)) {
          char = withNukta;
          i++; 
        }
      }

      if (vowels.containsKey(char)) {
        result.write(vowels[char]);
      } else if (consonants.containsKey(char)) {
        result.write(consonants[char]!);
        
        if (i + 1 < runes.length) {
          String next = String.fromCharCode(runes[i + 1]);
          if (matras.containsKey(next)) {
            result.write(matras[next]!);
            i++; 
          } else if (next == halant) {
            i++; 
          } else {
            // Implicit 'a' handling (Schwa deletion)
            bool isEndOfWord = true;
            if (i + 1 < runes.length) {
              int nextRune = runes[i + 1];
              if (nextRune >= 0x0900 && nextRune <= 0x097F) isEndOfWord = false;
            }
            if (!isEndOfWord) result.write('a');
          }
        }
      } else {
        // Only keep standard alphanumeric, spaces, and common punctuation
        if (_isStandardChar(char)) {
          result.write(char);
        }
      }
    }

    return result.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _normalizeAccentedChars(String s) {
    // Whisper often hallucinations accented vowels when confused by Indian accents
    return s.replaceAll('à', 'a').replaceAll('á', 'a').replaceAll('â', 'a')
            .replaceAll('è', 'e').replaceAll('é', 'e').replaceAll('ê', 'e')
            .replaceAll('ì', 'i').replaceAll('í', 'i').replaceAll('î', 'i')
            .replaceAll('ò', 'o').replaceAll('ó', 'o').replaceAll('ô', 'o')
            .replaceAll('ù', 'u').replaceAll('ú', 'u').replaceAll('û', 'u')
            .replaceAll('`', '').replaceAll('\'', ''); // Strip confusing apostrophes
  }

  static bool _isStandardChar(String char) {
    final int code = char.codeUnitAt(0);
    // Allow A-Z, a-z, 0-9, space, and common punctuation
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || 
           (code >= 48 && code <= 57) || char == ' ' || char == '.' || 
           char == ',' || char == '?' || char == '!';
  }
}
