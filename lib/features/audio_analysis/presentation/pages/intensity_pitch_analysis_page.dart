import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:test_audio_analysis_app/features/about/presentation/pages/about_page.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:test_audio_analysis_app/core/utils/format_duration.dart';

class IntensityPitchAnalysisPage extends StatefulWidget {
  final String filePath;
  final double startSecond;
  final double endSecond;
  final Uint8List? sonogramBytes;

  const IntensityPitchAnalysisPage({
    super.key,
    required this.filePath,
    required this.startSecond,
    required this.endSecond,
    this.sonogramBytes,
  });

  @override
  State<IntensityPitchAnalysisPage> createState() =>
      _IntensityPitchAnalysisPageState();
}

class _IntensityPitchAnalysisPageState
    extends State<IntensityPitchAnalysisPage> {
  bool isLoading = false;
  List<double> intensity = [];
  List<double> pitch = [];
  Map<double, double> timeToIntensityMap = {};
  Map<double, double> timeToPitchMap = {};
  
  // Chart references for zooming
  final GlobalKey _intensityChartKey = GlobalKey();
  final GlobalKey _pitchChartKey = GlobalKey();
  
  // Audio player variables
  late PlayerController playerController;
  bool isPlaying = false;
  final ValueNotifier<Duration> _currentDuration = ValueNotifier(Duration.zero);
  Duration maxDuration = Duration.zero;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _completionSub;

  // Range selectors for pitch and intensity
  RangeValues intensityRange =
      const RangeValues(-60, 0); // Default full range for dB
  RangeValues pitchRange = const RangeValues(0, 500); // Default 0-500 Hz range

  Future<void> processAudioFile() async {
    setState(() => isLoading = true);
    String? inputPath = widget.filePath;
    final wavPath = await convertToWav(inputPath);
    final samples = await readWavSamples(wavPath);

    final extractedIntensity = extractIntensity(samples);
    final extractedPitch = extractPitch(samples);

    final duration = widget.endSecond - widget.startSecond;
    final timeStep = duration / extractedIntensity.length;

    for (int i = 0; i < extractedIntensity.length; i++) {
      final timePoint = widget.startSecond + (i * timeStep);
      timeToIntensityMap[timePoint] = extractedIntensity[i];
    }

    for (int i = 0; i < extractedPitch.length; i++) {
      final timePoint = widget.startSecond + (i * timeStep);
      timeToPitchMap[timePoint] = extractedPitch[i];
    }

    setState(() {
      intensity = extractedIntensity;
      pitch = extractedPitch;
      isLoading = false;
    });
  }

  Future<String> convertToWav(String inputPath) async {
    if (inputPath.endsWith('.wav')) {
      return inputPath; // Already WAV, no need to convert
    }

    final outputDir = await getTemporaryDirectory();
    final outputPath = '${outputDir.path}/converted.wav';

    await FFmpegKit.execute(
        '-i "$inputPath" -ar 44100 -ac 1 -f wav "$outputPath"');

    return outputPath;
  }

  Future<List<int>> readWavSamples(String wavPath) async {
    final file = File(wavPath);
    final bytes = await file.readAsBytes();

    // Skip WAV header (44 bytes)
    final audioBytes = bytes.sublist(44);

    // Read as 16-bit signed PCM
    final samples = Int16List.view(audioBytes.buffer);

    return samples.toList();
  }

  List<double> extractIntensity(List<int> samples, {int frameSize = 2048}) {
    List<double> intensity = [];

    for (int i = 0; i < samples.length; i += frameSize) {
      int end =
          (i + frameSize < samples.length) ? i + frameSize : samples.length;
      List<int> frame = samples.sublist(i, end);

      double sum = frame.fold(0, (prev, val) => prev + val * val);
      double rms = sqrt(sum / frame.length);
      double normalizedRms = rms / 32768; // Normalize

      // Convert to dB
      double dB = 20 * log(normalizedRms) / log(10);
      // Ensure dB values are in a reasonable range (-60dB to 0dB)
      dB = dB.clamp(-60.0, 0.0);

      intensity.add(dB);
    }

    return intensity;
  }

  List<double> extractPitch(List<int> samples,
      {int frameSize = 2048, int sampleRate = 44100}) {
    List<double> pitchList = [];

    for (int i = 0; i < samples.length; i += frameSize) {
      int end =
          (i + frameSize < samples.length) ? i + frameSize : samples.length;
      List<int> frame = samples.sublist(i, end);

      double pitch = estimatePitch(frame, sampleRate);
      pitchList.add(pitch);
    }

    return pitchList;
  }

  double estimatePitch(List<int> frame, int sampleRate) {
    int maxShift = sampleRate ~/ 100; // Detect from 100Hz upwards
    double bestCorrelation = 0;
    int bestLag = 0;

    for (int lag = 20; lag < maxShift; lag++) {
      double correlation = 0;
      for (int i = 0; i < frame.length - lag; i++) {
        correlation += frame[i] * frame[i + lag];
      }
      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestLag = lag;
      }
    }

    if (bestLag == 0) return 0;
    return sampleRate / bestLag;
  }

  Future<void> _captureAndShowChart(GlobalKey key, String title) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture chart image')),
        );
        return;
      }
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to convert chart to image')),
        );
        return;
      }
      
      final bytes = byteData.buffer.asUint8List();
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(8),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        title,
                        style: const TextStyle(
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
        SnackBar(content: Text('Error capturing chart: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    playerController = PlayerController();
    setupAudioPlayer();
    processAudioFile();
  }
  
  Future<void> setupAudioPlayer() async {
    try {
      playerController.updateFrequency = UpdateFrequency.low;
      await playerController.preparePlayer(
        path: widget.filePath,
        noOfSamples: 100,
        shouldExtractWaveform: true,
      );
      final maxDurationMillis = await playerController.getDuration(DurationType.max);
      setState(() {
        maxDuration = Duration(milliseconds: maxDurationMillis);
      });
      
      _playerStateSub = playerController.onCurrentDurationChanged.listen((milliseconds) {
        _currentDuration.value = Duration(milliseconds: milliseconds);
      });
      
      _completionSub = playerController.onCompletion.listen((_) {
        setState(() => isPlaying = false);
      });
      
      playerController.setFinishMode(finishMode: FinishMode.pause);
    } catch (e) {
      print('Error setting up audio player: $e');
    }
  }

  void togglePlayPause() {
    if (isPlaying) {
      playerController.pausePlayer();
    } else {
      playerController.startPlayer();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void seekForward() {
    final newPosition = _currentDuration.value.inMilliseconds + 5000;
    if (newPosition < maxDuration.inMilliseconds) {
      playerController.seekTo(newPosition);
    } else {
      playerController.seekTo(maxDuration.inMilliseconds);
    }
  }

  void seekBackward() {
    final newPosition = _currentDuration.value.inMilliseconds - 5000;
    if (newPosition > 0) {
      playerController.seekTo(newPosition);
    } else {
      playerController.seekTo(0);
    }
  }

  void onSliderChanged(double value) {
    playerController.seekTo(value.toInt());
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _completionSub?.cancel();
    _currentDuration.dispose();
    playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Feature Extractor'),
        elevation: 4,
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
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                  ),
                  SizedBox(height: 20),
                  Text('Processing audio file...',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey.shade100],
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      if (intensity.isNotEmpty) ...[
                        _buildSectionHeader('Intensity Analysis', Colors.blue),
                        const SizedBox(height: 12),
                        _buildRangeSelector(
                          'Intensity Range (dB)',
                          intensityRange,
                          const RangeValues(-60, 0),
                          Colors.blue,
                          (values) {
                            setState(() {
                              intensityRange = values;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatCard(
                                        'Max',
                                        '${intensity.reduce(max).toStringAsFixed(1)} dB',
                                        Colors.blue),
                                    _buildStatCard(
                                        'Min',
                                        '${intensity.reduce(min).toStringAsFixed(1)} dB',
                                        Colors.blue),
                                    _buildStatCard(
                                        'Avg',
                                        '${(intensity.isEmpty ? 0 : intensity.reduce((a, b) => a + b) / intensity.length).toStringAsFixed(1)} dB',
                                        Colors.blue),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildTimeBasedDataTable(
                                    timeToIntensityMap, true),
                                Column(
                                  children: [
                                    Container(
                                      height: 250,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.1),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      padding:
                                          const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                      child: buildLineChart(intensity, Colors.blue),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                                        child: IconButton(
                                          icon: const Icon(Icons.zoom_in),
                                          tooltip: 'Zoom Intensity Chart',
                                          color: Colors.blue,
                                          onPressed: () => _captureAndShowChart(_intensityChartKey, 'Intensity Chart'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (pitch.isNotEmpty) ...[
                        _buildSectionHeader('Pitch Analysis', Colors.green),
                        const SizedBox(height: 12),
                        _buildRangeSelector(
                          'Pitch Range (Hz)',
                          pitchRange,
                          RangeValues(
                              0,
                              pitch.isEmpty
                                  ? 500
                                  : (pitch.reduce(max) * 1.5)
                                      .clamp(100.0, 5000.0)),
                          Colors.green,
                          (values) {
                            setState(() {
                              pitchRange = values;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatCard(
                                        'Max',
                                        '${pitch.reduce(max).toStringAsFixed(0)} Hz',
                                        Colors.green),
                                    _buildStatCard(
                                        'Min',
                                        '${pitch.where((p) => p > 0).fold(double.infinity, min).toStringAsFixed(0)} Hz',
                                        Colors.green),
                                    _buildStatCard(
                                        'Avg',
                                        '${(pitch.where((p) => p > 0).isEmpty ? 0 : pitch.where((p) => p > 0).reduce((a, b) => a + b) / pitch.where((p) => p > 0).length).toStringAsFixed(0)} Hz',
                                        Colors.green),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildTimeBasedDataTable(timeToPitchMap, false),
                                Column(
                                  children: [
                                    Container(
                                      height: 250,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.1),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      padding:
                                          const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                      child: buildLineChart(pitch, Colors.green),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                                        child: IconButton(
                                          icon: const Icon(Icons.zoom_in),
                                          tooltip: 'Zoom Pitch Chart',
                                          color: Colors.green,
                                          onPressed: () => _captureAndShowChart(_pitchChartKey, 'Pitch Chart'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildSectionHeader('Audio Player', Colors.purple),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Container(
                              //   height: 100,
                              //   decoration: BoxDecoration(
                              //     borderRadius: BorderRadius.circular(12),
                              //     color: Colors.white,
                              //     boxShadow: [
                              //       BoxShadow(
                              //         color: Colors.purple.withOpacity(0.1),
                              //         spreadRadius: 2,
                              //         blurRadius: 5,
                              //       ),
                              //     ],
                              //   ),
                              //   padding: const EdgeInsets.all(8.0),
                              //   child: AudioFileWaveforms(
                              //     size: Size(MediaQuery.of(context).size.width - 80, 100),
                              //     playerController: playerController,
                              //     enableSeekGesture: true,
                              //     waveformType: WaveformType.fitWidth,
                              //     playerWaveStyle: PlayerWaveStyle(
                              //       fixedWaveColor: Colors.grey.shade300,
                              //       liveWaveColor: Colors.purple,
                              //       seekLineColor: Colors.purple,
                              //       showSeekLine: true,
                              //       scaleFactor: 450,
                              //       waveThickness: 2,
                              //       spacing: 2.5,
                              //     ),
                              //   ),
                              // ),
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  ValueListenableBuilder<Duration>(
                                    valueListenable: _currentDuration,
                                    builder: (context, currentDuration, _) {
                                      return Column(
                                        children: [
                                          Slider(
                                            value: currentDuration.inMilliseconds
                                                .clamp(0, maxDuration.inMilliseconds > 0 ? maxDuration.inMilliseconds : 1)
                                                .toDouble(),
                                            min: 0,
                                            max: maxDuration.inMilliseconds > 0
                                                ? maxDuration.inMilliseconds.toDouble()
                                                : 1.0,
                                            onChanged: onSliderChanged,
                                            activeColor: Colors.purple,
                                            inactiveColor: Colors.grey[300],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  formatDuration(currentDuration),
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                Text(
                                                  formatDuration(maxDuration),
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: seekBackward,
                                        icon: CircleAvatar(
                                          backgroundColor: Colors.grey[300],
                                          child: Icon(
                                            Icons.replay_5,
                                            color: Colors.purple,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: togglePlayPause,
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.purple,
                                          child: Icon(
                                            isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        onPressed: seekForward,
                                        icon: CircleAvatar(
                                          backgroundColor: Colors.grey[300],
                                          child: Icon(
                                            Icons.forward_5,
                                            color: Colors.purple,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLineChart(List<double> values, Color color) {
    // Create time-based spots for the chart
    List<FlSpot> spots = [];
    final duration = widget.endSecond - widget.startSecond;

    // Get the current range values based on chart type
    final currentRange = color == Colors.blue ? intensityRange : pitchRange;

    for (int i = 0; i < values.length; i++) {
      // Convert index to actual time in seconds
      final timeInSeconds = widget.startSecond + (i / values.length * duration);
      // Only add spots that are within the selected range
      if (values[i] >= currentRange.start && values[i] <= currentRange.end) {
        spots.add(FlSpot(timeInSeconds, values[i]));
      }
    }

    // Use the appropriate key based on chart type
    final chartKey = color == Colors.blue ? _intensityChartKey : _pitchChartKey;
    
    return GestureDetector(
      onTap: () => _captureAndShowChart(chartKey, color == Colors.blue ? 'Intensity Chart' : 'Pitch Chart'),
      child: RepaintBoundary(
        key: chartKey,
        child: Stack(
          children: [
            // Sonogram background image
            if (widget.sonogramBytes != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomPaint(
                    painter: SonogramPainter(
                      sonogramBytes: widget.sonogramBytes!,
                      opacity: 1,
                      chartBounds: Rect.fromLTRB(
                        70, // Left padding for y-axis
                        0, // Top padding for potential top title
                        0, // Right edge (will be calculated in the painter)
                        0, // Bottom edge (will be calculated in the painter)
                      ),
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            // Chart on top
            LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 30,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 1,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.2),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Time (seconds)',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        // Show time values directly on x-axis
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      interval: duration / 10, // Show approximately 10 time markers
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      color == Colors.blue ? 'Intensity (dB)' : 'Pitch (Hz)',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    axisNameSize: 30,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        if (color == Colors.blue) {
                          text = '${value.toStringAsFixed(0)} dB';
                        } else {
                          text = value.toStringAsFixed(0);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                gridData: FlGridData(
                  show: false,
                  drawVerticalLine: true,
                  horizontalInterval: color == Colors.blue ? 10 : 100,
                  verticalInterval: duration / 5, // 5 vertical grid lines
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                      dashArray: [5, 5], // Dashed vertical lines
                    );
                  },
                ),
                minX: widget.startSecond,
                maxX: widget.endSecond,
                minY:
                    color == Colors.blue ? intensityRange.start : pitchRange.start,
                maxY: color == Colors.blue ? intensityRange.end : pitchRange.end,
                clipData: FlClipData
                    .all(), // Add this to prevent chart elements from going below the graph
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBasedDataTable(
      Map<double, double> timeValueMap, bool isIntensity) {
    final times = timeValueMap.keys.toList()..sort();

    List<double> selectedTimes = [];
    if (times.length <= 10) {
      selectedTimes = times;
    } else {
      final step = times.length ~/ 10;
      for (int i = 0; i < times.length; i += step) {
        if (selectedTimes.length < 10) {
          selectedTimes.add(times[i]);
        }
      }
      if (!selectedTimes.contains(times.last)) {
        selectedTimes.add(times.last);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isIntensity ? 'Intensity by Time' : 'Pitch by Time',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isIntensity ? Colors.blue : Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time row (header)
                Row(
                  children: [
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isIntensity
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Metric',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ...selectedTimes.map((time) {
                      return Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: isIntensity
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${time.toStringAsFixed(2)}s',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                // Value row
                Row(
                  children: [
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isIntensity ? 'dB' : 'Hz',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isIntensity ? Colors.blue : Colors.green,
                        ),
                      ),
                    ),
                    ...selectedTimes.map((time) {
                      final value = timeValueMap[time] ?? 0.0;
                      final displayValue = isIntensity
                          ? value.toStringAsFixed(1)
                          : value.toStringAsFixed(0);

                      return Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          displayValue,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isIntensity ? Colors.blue : Colors.green,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSelector(
    String title,
    RangeValues currentRange,
    RangeValues maxRange,
    Color color,
    Function(RangeValues) onChanged,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  currentRange.start.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Expanded(
                  child: RangeSlider(
                    values: currentRange,
                    min: maxRange.start,
                    max: maxRange.end,
                    divisions: 100,
                    activeColor: color,
                    inactiveColor: color.withOpacity(0.2),
                    labels: RangeLabels(
                      currentRange.start.toStringAsFixed(0),
                      currentRange.end.toStringAsFixed(0),
                    ),
                    onChanged: onChanged,
                  ),
                ),
                Text(
                  currentRange.end.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SonogramPainter extends CustomPainter {
  final Uint8List sonogramBytes;
  final double opacity;
  final Rect chartBounds;
  ui.Image? _image;

  SonogramPainter({
    required this.sonogramBytes,
    this.opacity = 0.3,
    required this.chartBounds,
  });

  Future<ui.Image> _loadImage() async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(sonogramBytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  @override
  void paint(Canvas canvas, Size size) async {
    if (_image == null) {
      _loadImage().then((image) {
        _image = image;
      });
      return;
    }

    // Calculate the actual chart area (excluding axes and titles)
    final double right = size.width; // Right padding
    final double bottom = size.height - 60; // Bottom padding for x-axis

    final Rect actualChartArea = Rect.fromLTRB(
      chartBounds.left,
      chartBounds.top,
      right,
      bottom,
    );

    // Draw only in the chart area
    canvas.save();
    canvas.clipRect(actualChartArea);

    // Draw the sonogram with opacity
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      _image!,
      Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble()),
      actualChartArea,
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(SonogramPainter oldDelegate) =>
      oldDelegate.sonogramBytes != sonogramBytes ||
      oldDelegate.opacity != opacity;
}
