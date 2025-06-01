// imports remain unchanged
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:test_audio_analysis_app/features/play_recordings/presentation/data/audio_analysis_model.dart';
import 'package:test_audio_analysis_app/features/play_recordings/presentation/widgets/edit_drawer.dart';
import 'package:vosk_flutter_2/vosk_flutter_2.dart';
// Add new widget imports
import 'package:test_audio_analysis_app/features/play_recordings/presentation/widgets/loading_indicator.dart';
import 'package:test_audio_analysis_app/features/play_recordings/presentation/widgets/audio_waveform_selector.dart';
import 'package:test_audio_analysis_app/features/play_recordings/presentation/widgets/audio_player_controls.dart';
import 'package:test_audio_analysis_app/features/play_recordings/presentation/widgets/word_list_view.dart';
import 'package:test_audio_analysis_app/features/about/presentation/pages/about_page.dart';

class PlaybackPage extends StatefulWidget {
  final String filePath;
  final String selectedModelName;
  final double screenWidth;

  const PlaybackPage(
      {super.key,
      required this.filePath,
      required this.selectedModelName,
      required this.screenWidth});

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  PageController pageController = PageController(viewportFraction: 0.2);
  late PlayerController playerController;
  bool isPlaying = false;
  StreamSubscription? _completionSub;
  StreamSubscription? _playerState;
  Duration currentDuration = Duration.zero;
  Duration maxDuration = Duration.zero;
  bool isTranscribing = true;
  double _loadingProgress = 0.0;
  AudioAnalysisModel audioAnalysisModel = AudioAnalysisModel();

  final VoskFlutterPlugin _voskFlutterPlugin = VoskFlutterPlugin.instance();
  Model? _voskModel;

  List<Map<String, dynamic>> words = [];
  bool isModelLoaded = false;

  final ScrollController _scrollController = ScrollController();
  int _lastHighlightedIndex = -1;
  final GlobalKey _waveformKey = GlobalKey();

  double? _selectionStartPx;
  double? _selectionEndPx;
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  double startSec = 0;
  double endSec = 0;
  bool isTimeLine = false;

  double? get _waveformWidth {
    final ctx = _waveformKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    return box?.size.width;
  }

  void _onPanStart(DragStartDetails details) {
    final localX = details.localPosition.dx;
    if (_selectionStartPx != null && (localX - _selectionStartPx!).abs() < 20) {
      _isDraggingStart = true;
    } else if (_selectionEndPx != null &&
        (localX - _selectionEndPx!).abs() < 20) {
      _isDraggingEnd = true;
    } else {
      // Start new selection
      setState(() {
        _selectionStartPx = localX;
        _selectionEndPx = localX;
        _isDraggingStart = true;
        _isDraggingEnd = false;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final localX = details.localPosition.dx;
    setState(() {
      if (_isDraggingStart && _selectionEndPx != null) {
        _selectionStartPx = localX.clamp(0.0, _selectionEndPx!);
      } else if (_isDraggingEnd && _selectionStartPx != null) {
        _selectionEndPx =
            localX.clamp(_selectionStartPx!, _waveformWidth ?? double.infinity);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDraggingStart = false;
      _isDraggingEnd = false;
    });
  }

  @override
  void initState() {
    super.initState();
    playerController = PlayerController();
    loadWaveform();
    loadModelAndTranscribe();

    _playerState =
        playerController.onCurrentDurationChanged.listen((milliseconds) {
      currentDuration = Duration(milliseconds: milliseconds);
      scrollToCurrentWord();
      setState(() {});
    });
  }

  Future<void> loadWaveform() async {
    playerController.updateFrequency = UpdateFrequency.low;
    await playerController.preparePlayer(
      path: widget.filePath,
      noOfSamples: (widget.screenWidth * 0.93) ~/ 2.5,
      shouldExtractWaveform: true,
    );

    final maxDurationMillis =
        await playerController.getDuration(DurationType.max);
    setState(() {
      maxDuration = Duration(milliseconds: maxDurationMillis);
    });

    _completionSub?.cancel();
    _completionSub = playerController.onCompletion.listen((_) {
      setState(() => isPlaying = false);
    });

    playerController.setFinishMode(finishMode: FinishMode.pause);
  }

  void handleConversion() async {
    String? pcmFile = await audioAnalysisModel.convertToPCM(widget.filePath);
    if (pcmFile != null) {
      transcribeAudio(pcmFile);
    }
  }

  Future<void> loadModelAndTranscribe() async {
    try {
      await audioAnalysisModel.checkModelFile(
          selectedModelName: widget.selectedModelName);
      String modelPath = await ModelLoader()
          .loadFromAssets("assets/models/${widget.selectedModelName}.zip");
      _voskModel = await _voskFlutterPlugin.createModel(modelPath);
      if (!mounted) return;
      setState(() => isModelLoaded = true);
      handleConversion();
    } catch (e) {
      print("Model load error: $e");
    }
  }

  Future<void> transcribeAudio(String convertedFilePath) async {
    try {
      List<Map<String, dynamic>> finalWords = [];
      const int sampleRate = 16000;
      const int chunkSize = 4000;

      final recognizer = await _voskFlutterPlugin.createRecognizer(
        model: _voskModel!,
        sampleRate: sampleRate,
      );
      await recognizer.setWords(words: true);

      final file = File(convertedFilePath);
      final totalBytes = await file.length();
      final inputStream = file.openRead();

      finalWords.clear();
      int processedBytes = 0;

      await for (final chunk
          in inputStream.transform(StreamTransformer.fromBind(
        (Stream<List<int>> stream) async* {
          final buffer = BytesBuilder();
          await for (var data in stream) {
            buffer.add(data);
            if (buffer.length >= chunkSize) {
              yield buffer.takeBytes();
            }
          }
          if (buffer.isNotEmpty) yield buffer.takeBytes();
        },
      ))) {
        processedBytes += chunk.length;
        await recognizer.acceptWaveformBytes(Uint8List.fromList(chunk));
        setState(() {
          _loadingProgress = processedBytes / totalBytes;
        });
      }

      final result = await recognizer.getFinalResult();
      final decoded = json.decode(result);

      if (decoded['result'] != null) {
        for (var wordData in decoded['result']) {
          finalWords.add({
            'word': wordData['word'],
            'start': wordData['start'],
            'end': wordData['end'],
          });
        }
      }

      setState(() {
        isTranscribing = false;
        words = finalWords;
        _lastHighlightedIndex = 0;
      });
    } catch (e) {
      print("Transcription error: $e");
    }
  }

  void togglePlayPause() async {
    if (isPlaying) {
      await playerController.pausePlayer();
    } else {
      await playerController.startPlayer();
    }
    setState(() => isPlaying = !isPlaying);
  }

  void seekForward() async {
    final newPosition = currentDuration.inMilliseconds + 5000;
    final maxDurationMs = maxDuration.inMilliseconds;
    final targetPosition =
        newPosition > maxDurationMs ? maxDurationMs : newPosition;

    setState(() {
      currentDuration = Duration(milliseconds: targetPosition);
    });
    await playerController.seekTo(targetPosition);
  }

  void seekBackward() async {
    final newPosition = currentDuration.inMilliseconds - 5000;
    final targetPosition = newPosition < 0 ? 0 : newPosition;

    setState(() {
      currentDuration = Duration(milliseconds: targetPosition);
    });
    await playerController.seekTo(targetPosition);
  }

  bool isCurrentWord(Duration current, double start, double end) {
    final currentMs = current.inMilliseconds;
    final startMs = start * 1000;
    final endMs = end * 1000;
    return currentMs >= startMs && currentMs < endMs;
  }

  void scrollToCurrentWord() {
    if (words.isEmpty) return;

    for (int i = 0; i < words.length; i++) {
      final start = words[i]['start'] as double;
      final end = words[i]['end'] as double;

      if (isCurrentWord(currentDuration, start, end)) {
        if (i != _lastHighlightedIndex) {
          _lastHighlightedIndex = i;

          pageController.animateToPage(
            _lastHighlightedIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        break;
      }
    }
  }

  void onWordTap(int index) async {
    setState(() {
      _lastHighlightedIndex = index;
      isTimeLine = false;
    });
    final start = words[index]['start'] as double;
    await playerController.seekTo((start * 1000).toInt());
  }

  void onSliderChanged(double value) async {
    setState(() {
      currentDuration = Duration(milliseconds: value.toInt());
    });
    await playerController.seekTo(value.toInt());
  }

  @override
  void dispose() {
    _completionSub?.cancel();
    _playerState?.cancel();
    playerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;

    return Scaffold(
      endDrawer: _lastHighlightedIndex != -1
          ? EditDrawer(
              initialValue: isTimeLine
                  ? "${startSec.toStringAsFixed(2)} - ${endSec.toStringAsFixed(2)}"
                  : words[_lastHighlightedIndex]['word'],
              title: "Access Menu",
              onConfirm: !isTimeLine
                  ? (value) {
                      setState(() {
                        words[_lastHighlightedIndex]['word'] = value;
                      });
                    }
                  : null,
              isTimeLine: isTimeLine,
              onConfirmTimeLine: isTimeLine
                  ? (start, end) {
                      setState(() {
                        if (double.tryParse(start) != null &&
                            double.tryParse(end) != null) {
                          startSec = double.parse(start);
                          endSec = double.parse(end);
                          final waveformWidth = _waveformWidth ?? 1.0;
                          final duration = maxDuration.inSeconds > 0
                              ? maxDuration.inSeconds
                              : 1;
                          _selectionStartPx =
                              (startSec / duration) * (waveformWidth + 20);
                          _selectionEndPx =
                              (endSec / duration) * (waveformWidth + 20);
                        }
                      });
                    }
                  : null,
            )
          : null,
      appBar: AppBar(
        title: Text("Playback: $fileName"),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: "About & How to Use",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
      body: !isModelLoaded || isTranscribing
          ? LoadingIndicator(
              progress: _loadingProgress,
              message: "Transcribing audio...",
            )
          : words.isEmpty
              ? const Center(child: Text("No transcription found."))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 8, right: 8, top: 8, bottom: 0),
                            child: Column(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final waveformWidth = constraints.maxWidth;
                                    // Set initial selection to full range if not already set
                                    if (_selectionStartPx == null ||
                                        _selectionEndPx == null) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (mounted) {
                                          setState(() {
                                            _selectionStartPx = 0;
                                            _selectionEndPx = waveformWidth;
                                          });
                                        }
                                      });
                                    }
                                    startSec = 0;
                                    endSec = 0;
                                    if (_selectionStartPx != null &&
                                        _selectionEndPx != null &&
                                        waveformWidth > 0 &&
                                        maxDuration.inMilliseconds > 0) {
                                      startSec =
                                          (_selectionStartPx! / waveformWidth) *
                                              maxDuration.inSeconds;
                                      endSec =
                                          (_selectionEndPx! / waveformWidth) *
                                              maxDuration.inSeconds;
                                      if (startSec < 0) startSec = 0;
                                      if (endSec > maxDuration.inSeconds)
                                        endSec =
                                            maxDuration.inSeconds.toDouble();
                                    }
                                    return AudioWaveformSelector(
                                      editTimeLine: () {
                                        setState(() {
                                          isTimeLine = true;
                                        });
                                        Scaffold.of(context).openEndDrawer();
                                      },
                                      playerController: playerController,
                                      waveformKey: _waveformKey,
                                      screenWidth: widget.screenWidth,
                                      selectionStartPx: _selectionStartPx,
                                      selectionEndPx: _selectionEndPx,
                                      startSec: startSec,
                                      endSec: endSec,
                                      onPanStart: _onPanStart,
                                      onPanUpdate: _onPanUpdate,
                                      onPanEnd: _onPanEnd,
                                      onSelectionStartChanged: (value) {
                                        setState(() {
                                          _selectionStartPx = value;
                                        });
                                      },
                                      onSelectionEndChanged: (value) {
                                        setState(() {
                                          _selectionEndPx = value;
                                        });
                                      },
                                    );
                                  },
                                ),
                                AudioPlayerControls(
                                  isPlaying: isPlaying,
                                  currentDuration: currentDuration,
                                  maxDuration: maxDuration,
                                  startSec: startSec,
                                  endSec: endSec,
                                  filePath: widget.filePath,
                                  onPlayPause: togglePlayPause,
                                  onSeekForward: seekForward,
                                  onSeekBackward: seekBackward,
                                  onSliderChanged: onSliderChanged,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        WordListView(
                          words: words,
                          highlightedIndex: _lastHighlightedIndex,
                          pageController: pageController,
                          onWordTap: onWordTap,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
