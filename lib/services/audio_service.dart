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

      // CORE FIX: Do not artificially extract the audio to an intermediate .aac file.
      // The intermediate extraction strips container timestamps and extradata, which 
      // degrades FFmpeg's ability to cleanly decode it in SWR, leading to transcription 
      // artifacts. We simply pass the raw .mp4 video path everywhere. Both our native 
      // whisper-lib.cpp and exportVideo function fully support demuxing audio straight from mp4.
      return video.path;
    } catch (e) {
      print("Error picking video or extracting audio: $e");
      return null;
    }
  }
}
