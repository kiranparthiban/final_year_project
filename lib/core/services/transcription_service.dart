import 'dart:io';
import 'dart:typed_data';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class TranscriptionService {
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (!_initialized) {
      sherpa.initBindings();
      _initialized = true;
    }
  }

  static Future<List<Map<String, dynamic>>> transcribe({
    required String modelDir,
    required String encoderFile,
    required String decoderFile,
    required String tokensFile,
    required String pcmFilePath,
    required double audioDurationSec,
    Function(double)? onProgress,
  }) async {
    _ensureInitialized();
    onProgress?.call(0.1);

    final config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: '$modelDir/$encoderFile',
          decoder: '$modelDir/$decoderFile',
          language: 'en',
          task: 'transcribe',
          enableTokenTimestamps: true,
        ),
        tokens: '$modelDir/$tokensFile',
        modelType: 'whisper',
        numThreads: 2,
        debug: false,
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

    print("Sherpa result text: ${result.text}");
    print("Sherpa tokens count: ${result.tokens.length}");
    print("Sherpa timestamps count: ${result.timestamps.length}");

    List<Map<String, dynamic>> words;

    if (result.tokens.isNotEmpty && result.timestamps.isNotEmpty) {
      // Use token-level timestamps for word-level output
      words = _tokensToWords(
        tokens: result.tokens,
        timestamps: result.timestamps,
        audioDuration: audioDurationSec,
      );
    } else if (result.text.isNotEmpty) {
      // Fallback: split text into words without timestamps
      final textWords = result.text.trim().split(RegExp(r'\s+'));
      final duration = audioDurationSec;
      final wordDuration = duration / textWords.length;
      words = [];
      for (int i = 0; i < textWords.length; i++) {
        words.add({
          'word': textWords[i],
          'start': i * wordDuration,
          'end': (i + 1) * wordDuration,
        });
      }
    } else {
      words = [];
    }

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
      if (token.isEmpty) continue;

      // New word starts with a space or is the first token
      if (token.startsWith(' ') || currentWord.isEmpty) {
        // Save previous word
        if (currentWord.trim().isNotEmpty) {
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
    if (currentWord.trim().isNotEmpty) {
      words.add({
        'word': currentWord.trim(),
        'start': wordStart,
        'end': audioDuration,
      });
    }

    return words;
  }
}
