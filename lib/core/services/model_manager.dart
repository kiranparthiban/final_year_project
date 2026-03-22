import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WhisperModel {
  final String name;
  final String displayName;
  final String encoderFile;
  final String decoderFile;
  final String tokensFile;
  final Map<String, String> files; // filename -> download URL

  const WhisperModel({
    required this.name,
    required this.displayName,
    required this.encoderFile,
    required this.decoderFile,
    required this.tokensFile,
    required this.files,
  });
}

const List<WhisperModel> availableModels = [
  WhisperModel(
    name: 'whisper-tiny.en-int8',
    displayName: 'Whisper Tiny English (103 MB)',
    encoderFile: 'tiny.en-encoder.int8.onnx',
    decoderFile: 'tiny.en-decoder.int8.onnx',
    tokensFile: 'tiny.en-tokens.txt',
    files: {
      'tiny.en-encoder.int8.onnx':
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny.en/resolve/main/tiny.en-encoder.int8.onnx',
      'tiny.en-decoder.int8.onnx':
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny.en/resolve/main/tiny.en-decoder.int8.onnx',
      'tiny.en-tokens.txt':
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny.en/resolve/main/tiny.en-tokens.txt',
    },
  ),
  WhisperModel(
    name: 'whisper-base.en-int8',
    displayName: 'Whisper Base English (161 MB) - Better accuracy',
    encoderFile: 'base.en-encoder.int8.onnx',
    decoderFile: 'base.en-decoder.int8.onnx',
    tokensFile: 'base.en-tokens.txt',
    files: {
      'base.en-encoder.int8.onnx':
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base.en/resolve/main/base.en-encoder.int8.onnx',
      'base.en-decoder.int8.onnx':
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base.en/resolve/main/base.en-decoder.int8.onnx',
      'base.en-tokens.txt':
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base.en/resolve/main/base.en-tokens.txt',
    },
  ),
  WhisperModel(
    name: 'whisper-small.en-int8',
    displayName: 'Whisper Small English (375 MB) - Best accuracy',
    encoderFile: 'small.en-encoder.int8.onnx',
    decoderFile: 'small.en-decoder.int8.onnx',
    tokensFile: 'small.en-tokens.txt',
    files: {
      'small.en-encoder.int8.onnx':
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-small.en/resolve/main/small.en-encoder.int8.onnx',
      'small.en-decoder.int8.onnx':
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-small.en/resolve/main/small.en-decoder.int8.onnx',
      'small.en-tokens.txt':
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-small.en/resolve/main/small.en-tokens.txt',
    },
  ),
];

class ModelManager {
  static Future<String> get _modelsDir async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/sherpa_models';
  }

  static Future<String> modelDir(WhisperModel model) async {
    final base = await _modelsDir;
    return '$base/${model.name}';
  }

  static Future<bool> isModelDownloaded(WhisperModel model) async {
    final dir = await modelDir(model);
    for (final filename in model.files.keys) {
      if (!await File('$dir/$filename').exists()) return false;
    }
    return true;
  }

  static Future<void> downloadModel(
    WhisperModel model, {
    Function(double progress, String status)? onProgress,
  }) async {
    final dir = await modelDir(model);
    await Directory(dir).create(recursive: true);

    final entries = model.files.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final filename = entries[i].key;
      final url = entries[i].value;
      final filePath = '$dir/$filename';

      if (await File(filePath).exists()) {
        onProgress?.call((i + 1) / entries.length, 'Skipping $filename');
        continue;
      }

      onProgress?.call(i / entries.length, 'Downloading $filename...');

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = File(filePath).openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final fileProgress = receivedBytes / totalBytes;
          final overallProgress = (i + fileProgress) / entries.length;
          onProgress?.call(overallProgress, 'Downloading $filename...');
        }
      }
      await sink.close();
    }

    onProgress?.call(1.0, 'Download complete');
  }

  static Future<void> deleteModel(WhisperModel model) async {
    final dir = await modelDir(model);
    final directory = Directory(dir);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
