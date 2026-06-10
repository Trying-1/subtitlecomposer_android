import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../providers/editor_provider.dart';

class TyposyncService {
  /// Unpacks a .typosync file (which is a ZIP archive containing one audio file and one JSON subtitle file).
  /// Copies them to application documents directory and loads them into the editor provider.
  static Future<bool> importTyposyncFile(String filePath, EditorProvider provider) async {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? audioFile;
      ArchiveFile? jsonFile;

      // Extensions we consider as audio
      final audioExtensions = {'.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'};

      for (final file in archive) {
        final ext = p.extension(file.name).toLowerCase();
        if (audioExtensions.contains(ext)) {
          audioFile = file;
        } else if (ext == '.json') {
          jsonFile = file;
        }
      }

      if (audioFile == null || jsonFile == null) {
        throw Exception('A valid .typosync package must contain exactly one audio file and one JSON subtitle file.');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final importDir = Directory('${appDir.path}/typosync_imports/$timestamp');
      if (!importDir.existsSync()) {
        importDir.createSync(recursive: true);
      }

      // Write audio file
      final localAudioFile = File('${importDir.path}/${p.basename(audioFile.name)}');
      localAudioFile.writeAsBytesSync(audioFile.content as List<int>);

      // Write json file
      final localJsonFile = File('${importDir.path}/subtitles.json');
      localJsonFile.writeAsBytesSync(jsonFile.content as List<int>);

      // Load both into EditorProvider
      await provider.loadAudio(localAudioFile.path);
      await provider.loadSubtitles(localJsonFile.path, 'json');

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a .typosync archive by packaging the given audio file and JSON subtitle file.
  /// Returns the created File.
  static Future<File?> createTyposyncPackage({
    required String audioPath,
    required String subtitlesJsonPath,
    required String outputName,
  }) async {
    try {
      final audioFile = File(audioPath);
      final jsonFile = File(subtitlesJsonPath);

      if (!audioFile.existsSync() || !jsonFile.existsSync()) {
        throw Exception('Source files do not exist.');
      }

      final archive = Archive();

      // Read files
      final audioBytes = audioFile.readAsBytesSync();
      final jsonBytes = jsonFile.readAsBytesSync();

      // Add files to archive
      archive.addFile(ArchiveFile(p.basename(audioPath), audioBytes.length, audioBytes));
      archive.addFile(ArchiveFile('subtitles.json', jsonBytes.length, jsonBytes));

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      final directory = await getTemporaryDirectory();
      // Ensure extension is .typosync
      var fileName = outputName.replaceAll(RegExp(r'[^\w\s-]'), '_');
      if (!fileName.toLowerCase().endsWith('.typosync')) {
        fileName = '$fileName.typosync';
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(zipData);
      return file;
    } catch (e) {
      return null;
    }
  }
}
