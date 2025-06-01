import 'package:flutter/material.dart';
import 'package:test_audio_analysis_app/core/utils/format_duration.dart';
import 'package:test_audio_analysis_app/features/audio_analysis/presentation/pages/audio_analysis_page.dart';

class AudioPlayerControls extends StatelessWidget {
  final bool isPlaying;
  final Duration currentDuration;
  final Duration maxDuration;
  final double startSec;
  final double endSec;
  final String filePath;
  final Function() onPlayPause;
  final Function() onSeekForward;
  final Function() onSeekBackward;
  final Function(double) onSliderChanged;

  const AudioPlayerControls({
    super.key,
    required this.isPlaying,
    required this.currentDuration,
    required this.maxDuration,
    required this.startSec,
    required this.endSec,
    required this.filePath,
    required this.onPlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: currentDuration.inMilliseconds
              .clamp(0, maxDuration.inMilliseconds)
              .toDouble(),
          min: 0,
          max: maxDuration.inMilliseconds > 0
              ? maxDuration.inMilliseconds.toDouble()
              : 1.0,
          onChanged: onSliderChanged,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Colors.grey[300],
        ),
        Text(
          "${formatDuration(currentDuration)} / ${formatDuration(maxDuration)}",
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const SizedBox(width: 50),
            IconButton(
              onPressed: onSeekBackward,
              icon: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.replay_5,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onPlayPause,
              child: Icon(
                isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: onSeekForward,
              icon: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.forward_5,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AudioAnalysisPage(
                    filePath: filePath,
                    startSecond: startSec,
                    endSecond: endSec == 0.0
                        ? maxDuration.inSeconds.toDouble()
                        : endSec,
                  ),
                ));
              },
              icon: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child:
                    const Icon(Icons.assessment_rounded, color: Colors.white),
              ),
            )
          ],
        )
      ],
    );
  }
}
