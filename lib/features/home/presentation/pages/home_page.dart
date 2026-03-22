import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:test_audio_analysis_app/core/utils/list_model_dialog.dart';
import 'package:test_audio_analysis_app/core/services/model_manager.dart';
import 'package:test_audio_analysis_app/features/play_recordings/presentation/pages/playback_page.dart';
import 'package:test_audio_analysis_app/features/about/presentation/pages/about_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late RecorderController recorderController;
  bool isRecording = false;
  bool isPaused = false;
  List<FileSystemEntity> recordings = [];
  late Directory appDirectory;

  @override
  void initState() {
    super.initState();
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
    
    // Sort files by modification time, newest first
    files.sort((a, b) {
      return File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync());
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
    setState(() {
      isRecording = true;
      isPaused = false;
    });
  }

  void pauseRecording() async {
    if (isRecording && !isPaused) {
      await recorderController.pause();
      setState(() => isPaused = true);
    } else if (isRecording && isPaused) {
      await recorderController.record();
      setState(() => isPaused = false);
    }
  }

  void stopRecording() async {
    await recorderController.stop();
    setState(() {
      isRecording = false;
      isPaused = false;
    });
    loadRecordings();
  }

  void saveRecording() async {
    if (isRecording) {
      await recorderController.stop();
      setState(() {
        isRecording = false;
        isPaused = false;
      });
      loadRecordings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recording saved successfully")),
      );
    }
  }

  void deleteAudioFile(File file) async {
    try {
      await file.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File deleted successfully")),
      );
      loadRecordings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting file: $e")),
      );
    }
  }

  Future<void> pickAndStoreAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3',
        'm4a',
        'wav',
        "pcm"
      ], // Multiple extensions allowed
    );

    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        final pickedFile = File(file.path!);
        final fileName = pickedFile.path.split('/').last;
        final savedPath = "${appDirectory.path}/$fileName";
        final savedFile = await pickedFile.copy(savedPath);
        
        // Touch the file to update its modification time to now
        await savedFile.setLastModified(DateTime.now());
        print("File saved to: $savedPath");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${result.files.length} files imported")),
      );

      loadRecordings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No files selected")),
      );
    }
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("CSS SPEECH ANALYZER",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 2,
        centerTitle: true,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Row(
          children: [
            /// LEFT SIDE
            Expanded(
              flex: 5,
              child: Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Waveform Preview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: AudioWaveforms(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          enableGesture: false,
                          size: Size(screenWidth * 0.4, 60),
                          recorderController: recorderController,
                          waveStyle: WaveStyle(
                            scaleFactor: 50,
                            waveColor: Theme.of(context).primaryColor,
                            extendWaveform: true,
                            showMiddleLine: false,
                            spacing: 1.5,
                            waveThickness: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isRecording
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isRecording
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3)
                                      : Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed:
                                  isRecording ? stopRecording : startRecording,
                              icon: Icon(
                                isRecording
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip: isRecording ? "Stop" : "Record",
                              padding: const EdgeInsets.all(12),
                              iconSize: 28,
                            ),
                          ),
                          if (isRecording)
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: pauseRecording,
                                icon: Icon(
                                  isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                tooltip: isPaused ? "Resume" : "Pause",
                                padding: const EdgeInsets.all(12),
                                iconSize: 28,
                              ),
                            ),
                          if (isRecording)
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: saveRecording,
                                icon: const Icon(
                                  Icons.save_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                tooltip: "Save",
                                padding: const EdgeInsets.all(12),
                                iconSize: 28,
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: pickAndStoreAudioFiles,
                              icon: const Icon(
                                Icons.upload_file_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip: "Import Audio",
                              padding: const EdgeInsets.all(12),
                              iconSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// RIGHT SIDE
            Expanded(
              flex: 6,
              child: Card(
                margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.audio_file,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            "Audio Files",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          thickness: 1),
                      const SizedBox(height: 8),
                      Expanded(
                        child: recordings.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.audio_file_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No audio files yet",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: recordings.length,
                                itemBuilder: (context, index) {
                                  final file = recordings[index];
                                  final fileName = file.path.split('/').last;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      child: Icon(Icons.audio_file,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    title: Text(
                                      fileName.length > 15
                                          ? '${fileName.substring(0, 15)}...'
                                          : fileName,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              deleteAudioFile(File(file.path)),
                                        ),
                                      ],
                                    ),
                                    onTap: () => showModelSelectionDialog(
                                        context: context,
                                        onModelSelected: (modelDir, model) {
                                          Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PlaybackPage(
                                                        filePath: file.path,
                                                        selectedModelPath:
                                                            modelDir,
                                                        selectedModel: model,
                                                        screenWidth:
                                                            MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width,
                                                      )));
                                        }),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
