import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:test_audio_analysis_app/features/audio_analysis/presentation/pages/intensity_pitch_analysis_page.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:test_audio_analysis_app/core/widgets/zoomable_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_audio_analysis_app/features/about/presentation/pages/about_page.dart';

class AudioAnalysisPage extends StatefulWidget {
  final String filePath;
  final double startSecond;
  final double endSecond;

  const AudioAnalysisPage({
    super.key,
    required this.filePath,
    required this.startSecond,
    required this.endSecond,
  });

  @override
  State<AudioAnalysisPage> createState() => _AudioAnalysisPageState();
}

class _AudioAnalysisPageState extends State<AudioAnalysisPage> {
  Uint8List? spectrogramBytes;
  Uint8List? sonogramBytes;
  late PlayerController playerController;
  bool isPlaying = false;
  String? trimmedAudioPath;
  Future<bool>? _analysisComplete;
  final GlobalKey _waveformKey = GlobalKey();
  Uint8List? waveformImageBytes;

  @override
  void initState() {
    super.initState();
    playerController = PlayerController();
    _analysisComplete = _performAnalysis();
  }

  Future<bool> _checkStoragePermission() async {
    Map<Permission, PermissionStatus> statuses = {
      Permission.storage: await Permission.storage.status,
      Permission.photos: await Permission.photos.status,
      Permission.manageExternalStorage: await Permission.manageExternalStorage.status,
    };

    return statuses.values.any((status) => status.isGranted);
  }

  Future<bool> _requestStoragePermission() async {
    bool hasPermission = await _checkStoragePermission();
    if (hasPermission) {
      return true;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.manageExternalStorage,
    ].request();

    bool denied = statuses.values.any((status) => status.isDenied);

    if (denied && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Storage and photo permissions are needed to save audio visualizations. '
            'Please grant all permissions in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _requestStoragePermissionIfNecessary() async {
    bool hasPermission = await _checkStoragePermission();
    if (!hasPermission) {
      await _requestStoragePermission();
    }
  }

  Future<void> _saveImageToFile(Uint8List bytes, String name) async {
    try {
      await _requestStoragePermissionIfNecessary();

      Directory? directory;
      String? downloadsPath;

      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          String externalPath = externalDir.path;
          final pathParts = externalPath.split('/');

          int androidIndex = pathParts.indexOf('Android');
          if (androidIndex != -1 && androidIndex > 0) {
            final rootPath = pathParts.sublist(0, androidIndex).join('/');
            downloadsPath = '$rootPath/Download';
            directory = Directory(downloadsPath);

            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          }
        }
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        downloadsPath = '${appDir.path}/Downloads';
        directory = Directory(downloadsPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }

      if (directory == null || downloadsPath == null) {
        debugPrint(
            'Downloads directory not available, falling back to app directory');
        try {
          directory = await getApplicationDocumentsDirectory();
          downloadsPath = directory.path;
        } catch (e) {
          debugPrint('Could not get application documents directory: $e');

          try {
            directory = await getTemporaryDirectory();
            downloadsPath = directory.path;
          } catch (e) {
            debugPrint('Could not get temporary directory: $e');
          }
        }
      }

      if (directory == null || downloadsPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not access any storage directory')),
        );
        return;
      }

      final appDir = Directory('$downloadsPath/AudioAnalysis');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      final file = File('${appDir.path}/$name');
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name saved to ${appDir.path}'),
          action: SnackBarAction(
            label: 'View Folder',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Files are in: ${appDir.path}')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving file: $e')),
      );
    }
  }

  Future<void> _saveWaveform() async {
    try {
      await _requestStoragePermissionIfNecessary();

      final RenderRepaintBoundary? boundary = _waveformKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture waveform image')),
        );
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to convert waveform to image')),
        );
        return;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      await _saveImageToFile(
          bytes, 'waveform_${DateTime.now().millisecondsSinceEpoch}.png');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing waveform: $e')),
      );
    }
  }
  
  Future<void> _captureWaveformAsImage() async {
    try {
      final RenderRepaintBoundary? boundary = _waveformKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture waveform image')),
        );
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to convert waveform to image')),
        );
        return;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();
      final screenSize = MediaQuery.of(context).size;
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(8),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.85,
              maxWidth: screenSize.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Audio Waveform',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing waveform: $e')),
      );
    }
  }

  Future<void> _saveSonogram() async {
    if (sonogramBytes != null) {
      await _requestStoragePermissionIfNecessary();

      await _saveImageToFile(sonogramBytes!,
          'sonogram_${DateTime.now().millisecondsSinceEpoch}.png');
    }
  }

  Future<void> _saveSpectrogram() async {
    if (spectrogramBytes != null) {
      await _requestStoragePermissionIfNecessary();

      await _saveImageToFile(spectrogramBytes!,
          'spectrogram_${DateTime.now().millisecondsSinceEpoch}.png');
    }
  }

  Future<bool> _performAnalysis() async {
    await analyzeAudio();
    return true;
  }

  @override
  void dispose() {
    playerController.dispose();
    super.dispose();
  }

  Future<void> _initializeWaveform() async {
    try {
      if (trimmedAudioPath == null) return;
      playerController.setFinishMode(finishMode: FinishMode.pause);

      await playerController.preparePlayer(
        path: trimmedAudioPath!,
        noOfSamples: MediaQuery.of(context).size.width.toInt() * 0.77 ~/ 2,
        shouldExtractWaveform: true,
      );

      setState(() {});
    } catch (e) {
      debugPrint('Error initializing waveform: $e');
    }
  }

  Future<void> analyzeAudio() async {
    final directory = await getTemporaryDirectory();
    final trimmedPath = '${directory.path}/trimmed_audio.wav';
    final duration = widget.endSecond - widget.startSecond;

    await FFmpegKit.execute(
        '-y -ss ${widget.startSecond} -t $duration -i "${widget.filePath}" "$trimmedPath"');

    setState(() {
      trimmedAudioPath = trimmedPath;
    });
    await _initializeWaveform();
    final outputImage = File('${directory.path}/spectrogram.png');
    if (await outputImage.exists()) {
      await outputImage.delete();
      await outputImage.create(); // Optional: ensure it gets reset
    }

    final localSpectrogramPath = outputImage.path;

    await FFmpegKit.executeAsync(
      '-y -i "$trimmedPath" -lavfi showspectrumpic=s=1980x400 "$localSpectrogramPath"',
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          final bytes = await File(localSpectrogramPath).readAsBytes();
          setState(() {
            spectrogramBytes = bytes;
          });
        }
      },
    );

    final sonogramImage = File('${directory.path}/sonogram.png');
    if (await sonogramImage.exists()) {
      await sonogramImage.delete();
      await sonogramImage.create();
    }
    final localSonogramPath = sonogramImage.path;

    await FFmpegKit.executeAsync(
      '-y -i "$trimmedPath" -lavfi "showspectrumpic=s=1980x400:legend=disabled:start=0:stop=4000:mode=combined,format=gray" "$localSonogramPath"',
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          final sonogramBytes = await File(localSonogramPath).readAsBytes();
          setState(() {
            this.sonogramBytes = sonogramBytes;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Analysis"),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<bool>(
          future: _analysisComplete,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing audio...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (trimmedAudioPath != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: RepaintBoundary(
                            key: _waveformKey,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: GestureDetector(
                                onTap: _captureWaveformAsImage,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AudioFileWaveforms(
                                  animationCurve: Curves.decelerate,
                                  animationDuration:
                                      const Duration(milliseconds: 500),
                                  size: Size(
                                      MediaQuery.of(context).size.width, 150),
                                  playerController: playerController,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[100],
                                  ),
                                  continuousWaveform: true,
                                  enableSeekGesture: false,
                                  waveformType: WaveformType.fitWidth,
                                  playerWaveStyle: PlayerWaveStyle(
                                    fixedWaveColor:
                                        Theme.of(context).primaryColor,
                                    liveWaveColor:
                                        Theme.of(context).primaryColor,
                                    showSeekLine: true,
                                    scaleFactor: 300,
                                    waveThickness: 2,
                                    spacing: 2.5,
                                  ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.save_alt),
                          tooltip: 'Save waveform',
                          onPressed: _saveWaveform,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  sonogramBytes != null && spectrogramBytes != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('📊 Sonogram:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.save_alt),
                                  tooltip: 'Save sonogram',
                                  onPressed: _saveSonogram,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ZoomableImage(
                              imageBytes: sonogramBytes!,
                              fit: BoxFit.cover,
                              title: 'Sonogram',
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Text('📊 Spectrogram:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.save_alt),
                                  tooltip: 'Save spectrogram',
                                  onPressed: _saveSpectrogram,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ZoomableImage(
                              imageBytes: spectrogramBytes!,
                              fit: BoxFit.cover,
                              title: 'Spectrogram',
                            ),
                            SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    IntensityPitchAnalysisPage(
                                      filePath: trimmedAudioPath!,
                                      startSecond: widget.startSecond,
                                      endSecond: widget.endSecond,
                                      sonogramBytes: sonogramBytes,
                                    )));
                      },
                      style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Theme.of(context).primaryColor),
                      child: Text("Show Intensity and Pitch"))
                          ],
                        )
                      : SizedBox(
                          height: 30,
                          width: 30,
                          child: const CircularProgressIndicator()),
                  
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
