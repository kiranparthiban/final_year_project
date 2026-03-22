// This file was created to move audio analysis and playback logic from playback_page.dart
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

class AudioAnalysisModel {
  Future<String?> convertToPCM(String inputFilePath) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String outputFilePath = '${tempDir.path}/output.pcm';

      final String command =
          "-y -i \"$inputFilePath\" -ar 16000 -ac 1 -f s16le \"$outputFilePath\"";

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (returnCode!.isValueSuccess()) {
        await Future.delayed(Duration(milliseconds: 100));
        return outputFilePath;
      } else {
        return null;
      }
    } catch (e) {
      print("Conversion error: $e");
      return null;
    }
  }
}
