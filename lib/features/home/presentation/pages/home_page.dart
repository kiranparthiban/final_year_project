import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:test_audio_analysis_app/core/theme/app_colors.dart';
import 'package:test_audio_analysis_app/core/utils/list_model_dialog.dart';
import 'package:test_audio_analysis_app/core/services/model_manager.dart';
import 'package:test_audio_analysis_app/features/play_recordings/presentation/pages/playback_page.dart';
import 'package:test_audio_analysis_app/features/about/presentation/pages/about_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late RecorderController recorderController;
  bool isRecording = false;
  bool isPaused = false;
  List<FileSystemEntity> recordings = [];
  late Directory appDirectory;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    initRecorder();
  }

  Future<void> initRecorder() async {
    recorderController = RecorderController();
    await Permission.microphone.request();
    appDirectory = await getApplicationDocumentsDirectory();
    loadRecordings();
  }

  void loadRecordings() {
    final files = appDirectory
        .listSync()
        .where((f) =>
            f.path.endsWith('.mp3') ||
            f.path.endsWith('.m4a') ||
            f.path.endsWith('.wav') ||
            f.path.endsWith('.pcm'))
        .toList();
    files.sort((a, b) {
      return File(b.path)
          .lastModifiedSync()
          .compareTo(File(a.path).lastModifiedSync());
    });
    setState(() {
      recordings = files;
    });
  }

  void startRecording() async {
    if (await Permission.microphone.request().isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission denied")),
      );
      return;
    }
    final path =
        "${appDirectory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.pcm";
    await recorderController.record(path: path);
    _pulseController.repeat(reverse: true);
    setState(() {
      isRecording = true;
      isPaused = false;
    });
  }

  void pauseRecording() async {
    if (isRecording && !isPaused) {
      await recorderController.pause();
      _pulseController.stop();
      setState(() => isPaused = true);
    } else if (isRecording && isPaused) {
      await recorderController.record();
      _pulseController.repeat(reverse: true);
      setState(() => isPaused = false);
    }
  }

  void stopRecording() async {
    await recorderController.stop();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      isRecording = false;
      isPaused = false;
    });
    loadRecordings();
  }

  void saveRecording() async {
    if (isRecording) {
      await recorderController.stop();
      _pulseController.stop();
      _pulseController.reset();
      setState(() {
        isRecording = false;
        isPaused = false;
      });
      loadRecordings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recording saved")),
      );
    }
  }

  void deleteAudioFile(File file) async {
    try {
      await file.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File deleted")),
      );
      loadRecordings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> pickAndStoreAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'pcm'],
    );
    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        final pickedFile = File(file.path!);
        final fileName = pickedFile.path.split('/').last;
        final savedPath = "${appDirectory.path}/$fileName";
        final savedFile = await pickedFile.copy(savedPath);
        await savedFile.setLastModified(DateTime.now());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${result.files.length} files imported")),
      );
      loadRecordings();
    }
  }

  String _formatFileName(String path) {
    final name = path.split('/').last;
    if (name.length > 25) return '${name.substring(0, 22)}...';
    return name;
  }

  String _getFileSize(String path) {
    final file = File(path);
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.accentGradient.createShader(bounds),
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            const Text("CSS SPEECH ANALYZER"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: "About & How to Use",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // LEFT - Recording panel
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.accentGradient.createShader(bounds),
                      child: const Text(
                        "RECORDER",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Waveform
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.bgSurface,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: AudioWaveforms(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enableGesture: false,
                        size: Size(screenWidth * 0.35, 60),
                        recorderController: recorderController,
                        waveStyle: const WaveStyle(
                          scaleFactor: 50,
                          waveColor: AppColors.primaryColor,
                          extendWaveform: true,
                          showMiddleLine: false,
                          spacing: 2,
                          waveThickness: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Record / Stop
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final glow = isRecording && !isPaused
                                ? _pulseController.value * 12
                                : 0.0;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  if (isRecording && !isPaused)
                                    BoxShadow(
                                      color: AppColors.accentRed.withOpacity(0.4),
                                      blurRadius: glow + 8,
                                      spreadRadius: glow / 2,
                                    ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: _buildControlButton(
                            icon: isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            color: isRecording ? AppColors.accentRed : AppColors.primaryColor,
                            onTap: isRecording ? stopRecording : startRecording,
                            size: 52,
                          ),
                        ),
                        if (isRecording) ...[
                          const SizedBox(width: 20),
                          _buildControlButton(
                            icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            color: AppColors.accentOrange,
                            onTap: pauseRecording,
                          ),
                          const SizedBox(width: 20),
                          _buildControlButton(
                            icon: Icons.save_rounded,
                            color: AppColors.accentGreen,
                            onTap: saveRecording,
                          ),
                        ],
                        if (!isRecording) ...[
                          const SizedBox(width: 20),
                          _buildControlButton(
                            icon: Icons.upload_file_rounded,
                            color: AppColors.accentBlue,
                            onTap: pickAndStoreAudioFiles,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // RIGHT - File list
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.audio_file_rounded,
                            color: AppColors.primaryColor, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          "Audio Files",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${recordings.length} files',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: recordings.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.audio_file_outlined,
                                      size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "No audio files yet",
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Record or import audio to get started",
                                    style: TextStyle(
                                        color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: recordings.length,
                              itemBuilder: (context, index) {
                                final file = recordings[index];
                                final fileName = _formatFileName(file.path);
                                final fileSize = _getFileSize(file.path);
                                final ext = file.path.split('.').last.toUpperCase();

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => showModelSelectionDialog(
                                        context: context,
                                        onModelSelected: (modelDir, model) {
                                          Navigator.of(context).push(
                                            PageRouteBuilder(
                                              pageBuilder: (_, __, ___) =>
                                                  PlaybackPage(
                                                filePath: file.path,
                                                selectedModelPath: modelDir,
                                                selectedModel: model,
                                                screenWidth:
                                                    MediaQuery.of(context)
                                                        .size
                                                        .width,
                                              ),
                                              transitionDuration:
                                                  const Duration(milliseconds: 400),
                                              transitionsBuilder:
                                                  (_, anim, __, child) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(1, 0),
                                                    end: Offset.zero,
                                                  ).animate(CurvedAnimation(
                                                    parent: anim,
                                                    curve: Curves.easeOutCubic,
                                                  )),
                                                  child: child,
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppColors.border
                                                  .withOpacity(0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                gradient: AppColors.primaryGradient,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  ext,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    fileName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    fileSize,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: AppColors.textMuted,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  deleteAudioFile(File(file.path)),
                                            ),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppColors.textMuted,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 44,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
