import 'dart:io';
import 'dart:typed_data';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class TranscriptionService {
  static Future<List<Map<String, dynamic>>> transcribe({
    required String modelDir,
    required String pcmFilePath,
    required double audioDurationSec,
    Function(double)? onProgress,
  }) async {
    onProgress?.call(0.1);

    final config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: '$modelDir/tiny.en-encoder.int8.onnx',
          decoder: '$modelDir/tiny.en-decoder.int8.onnx',
        ),
        tokens: '$modelDir/tiny.en-tokens.txt',
        modelType: 'whisper',
        numThreads: 2,
      ),
    );

    final recognizer = sherpa.OfflineRecognizer(config);
    onProgress?.call(0.3);

    // Read PCM file and convert s16le bytes to Float32
    final bytes = await File(pcmFilePath).readAsBytes();
    final samples = _convertS16leToFloat32(bytes);
    onProgress?.call(0.5);

    // Create stream and feed audio
    final stream = recognizer.createStream();
    stream.acceptWaveform(samples: samples, sampleRate: 16000);
    recognizer.decode(stream);
    onProgress?.call(0.8);

    // Get result
    final result = recognizer.getResult(stream);

    // Convert token-level timestamps to word-level
    final words = _tokensToWords(
      tokens: result.tokens,
      timestamps: result.timestamps,
      audioDuration: audioDurationSec,
    );

    stream.free();
    recognizer.free();
    onProgress?.call(1.0);

    return words;
  }

  static Float32List _convertS16leToFloat32(Uint8List bytes) {
    final numSamples = bytes.length ~/ 2;
    final samples = Float32List(numSamples);
    final byteData = ByteData.sublistView(bytes);

    for (int i = 0; i < numSamples; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      samples[i] = sample / 32768.0;
    }

    return samples;
  }

  static List<Map<String, dynamic>> _tokensToWords({
    required List<String> tokens,
    required List<double> timestamps,
    required double audioDuration,
  }) {
    final List<Map<String, dynamic>> words = [];

    if (tokens.isEmpty) return words;

    String currentWord = '';
    double wordStart = 0;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final time = i < timestamps.length ? timestamps[i] : audioDuration;

      // Skip special tokens
      if (token.startsWith('<') || token.startsWith('[')) continue;

      // New word starts with a space or is the first token
      if (token.startsWith(' ') || currentWord.isEmpty) {
        // Save previous word
        if (currentWord.isNotEmpty) {
          words.add({
            'word': currentWord.trim(),
            'start': wordStart,
            'end': time,
          });
        }
        currentWord = token.trimLeft();
        wordStart = time;
      } else {
        currentWord += token;
      }
    }

    // Save last word
    if (currentWord.isNotEmpty) {
      words.add({
        'word': currentWord.trim(),
        'start': wordStart,
        'end': audioDuration,
      });
    }

    // Filter out empty words
    words.removeWhere((w) => (w['word'] as String).isEmpty);

    return words;
  }
}
