import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/services.dart';
import 'package:test_audio_analysis_app/core/theme/app_colors.dart';

class AudioWaveformSelector extends StatefulWidget {
  final PlayerController playerController;
  final GlobalKey waveformKey;
  final double screenWidth;
  final double? selectionStartPx;
  final double? selectionEndPx;
  final double startSec;
  final double endSec;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final void Function() editTimeLine;
  final Function(double?)? onSelectionStartChanged;
  final Function(double?)? onSelectionEndChanged;

  const AudioWaveformSelector({
    super.key,
    required this.playerController,
    required this.waveformKey,
    required this.screenWidth,
    required this.selectionStartPx,
    required this.selectionEndPx,
    required this.startSec,
    required this.endSec,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.onSelectionStartChanged,
    this.onSelectionEndChanged,
    required this.editTimeLine,
  });

  @override
  State<AudioWaveformSelector> createState() => _AudioWaveformSelectorState();
}

class _AudioWaveformSelectorState extends State<AudioWaveformSelector> {
  @override
  Widget build(BuildContext context) {
    const double minHandleDistance = 24;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: widget.onPanStart,
            onPanUpdate: widget.onPanUpdate,
            onPanEnd: widget.onPanEnd,
            child: Stack(
              children: [
                RepaintBoundary(
                  key: widget.waveformKey,
                  child: AudioFileWaveforms(
                    animationCurve: Curves.decelerate,
                    animationDuration: const Duration(milliseconds: 500),
                    size: Size(widget.screenWidth, 150),
                    playerController: widget.playerController,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.bgDark,
                    ),
                    continuousWaveform: true,
                    enableSeekGesture: false,
                    waveformType: WaveformType.fitWidth,
                    playerWaveStyle: const PlayerWaveStyle(
                      fixedWaveColor: AppColors.bgSurface,
                      liveWaveColor: AppColors.primaryColor,
                      showSeekLine: true,
                      seekLineColor: AppColors.primaryLight,
                      scaleFactor: 300,
                      waveThickness: 2,
                      spacing: 2.5,
                    ),
                  ),
                ),
                if (widget.selectionStartPx != null &&
                    widget.selectionEndPx != null)
                  Positioned(
                    left: (widget.selectionStartPx! < widget.selectionEndPx!)
                        ? widget.selectionStartPx!
                        : widget.selectionEndPx!,
                    width: (widget.selectionEndPx! - widget.selectionStartPx!)
                        .abs(),
                    top: 0,
                    bottom: 0,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${widget.startSec.toStringAsFixed(2)}s",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${widget.endSec.toStringAsFixed(2)}s",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Start handle
                if (widget.selectionStartPx != null)
                  Positioned(
                    left: widget.selectionStartPx! - 8,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onPanUpdate: (details) {
                            const double speedMultiplier = 2.0;
                            final newStartPx = (widget.selectionStartPx ?? 0) +
                                details.delta.dx * speedMultiplier;
                            final adjustedStartPx =
                                widget.selectionEndPx != null &&
                                        newStartPx >
                                            widget.selectionEndPx! -
                                                minHandleDistance
                                    ? widget.selectionEndPx! - minHandleDistance
                                    : newStartPx;
                            if (adjustedStartPx < 0) {
                              widget.onSelectionStartChanged?.call(0);
                            } else {
                              widget.onSelectionStartChanged
                                  ?.call(adjustedStartPx);
                            }
                          },
                          child: Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryColor, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.chevron_left,
                                color: AppColors.primaryColor, size: 18),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: Container(
                            width: 3,
                            height: 35,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // End handle
                if (widget.selectionEndPx != null)
                  Positioned(
                    left: widget.selectionEndPx! - 8,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onPanUpdate: (details) {
                            const double speedMultiplier = 2.0;
                            final newEndPx = (widget.selectionEndPx ?? 0) +
                                details.delta.dx * speedMultiplier;
                            final adjustedEndPx =
                                widget.selectionStartPx != null &&
                                        newEndPx <
                                            widget.selectionStartPx! +
                                                minHandleDistance
                                    ? widget.selectionStartPx! +
                                        minHandleDistance
                                    : newEndPx;
                            final waveformWidth = (widget
                                        .waveformKey.currentContext
                                        ?.findRenderObject() as RenderBox?)
                                    ?.size
                                    .width ??
                                double.infinity;
                            if (adjustedEndPx > waveformWidth) {
                              widget.onSelectionEndChanged?.call(waveformWidth);
                            } else {
                              widget.onSelectionEndChanged?.call(adjustedEndPx);
                            }
                          },
                          child: Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryColor, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.chevron_right,
                                color: AppColors.primaryColor, size: 18),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: Container(
                            width: 3,
                            height: 35,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _timeChip(
                "Start: ${widget.startSec.toStringAsFixed(2)}s",
                onTap: widget.editTimeLine,
              ),
              _timeChip(
                "End: ${widget.endSec.toStringAsFixed(2)}s",
                onTap: widget.editTimeLine,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeChip(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
