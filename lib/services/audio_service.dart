import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'native_bridge.dart';

class AudioService {
  final NativeBridge _bridge = NativeBridge();
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickVideoAndExtractAudio() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return null;

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'extracted_audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      final String outputPath = '${tempDir.path}/$fileName';

      await _bridge.extractAudio(video.path, outputPath);

      if (await File(outputPath).exists()) {
        return outputPath;
      }
      return null;
    } catch (e) {
      print("Error picking video or extracting audio: $e");
      return null;
    }
  }
}
