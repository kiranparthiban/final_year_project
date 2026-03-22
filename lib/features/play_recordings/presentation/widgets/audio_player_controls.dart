import 'package:flutter/material.dart';
import 'package:test_audio_analysis_app/core/theme/app_colors.dart';
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: currentDuration.inMilliseconds
                .clamp(0, maxDuration.inMilliseconds)
                .toDouble(),
            min: 0,
            max: maxDuration.inMilliseconds > 0
                ? maxDuration.inMilliseconds.toDouble()
                : 1.0,
            onChanged: onSliderChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(currentDuration),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                formatDuration(maxDuration),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const SizedBox(width: 40),
            _controlButton(
              icon: Icons.replay_5_rounded,
              onTap: onSeekBackward,
              size: 36,
            ),
            const SizedBox(width: 16),
            // Play/Pause
            GestureDetector(
              onTap: onPlayPause,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            _controlButton(
              icon: Icons.forward_5_rounded,
              onTap: onSeekForward,
              size: 36,
            ),
            const Spacer(),
            // Analysis button
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => AudioAnalysisPage(
                      filePath: filePath,
                      startSecond: startSec,
                      endSecond: endSec == 0.0
                          ? maxDuration.inSeconds.toDouble()
                          : endSec,
                    ),
                    transitionDuration: const Duration(milliseconds: 400),
                    transitionsBuilder: (_, anim, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
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
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.accentBlue.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assessment_rounded,
                        color: AppColors.accentBlue, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "Analyze",
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 40,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: size * 0.5),
      ),
    );
  }
}
