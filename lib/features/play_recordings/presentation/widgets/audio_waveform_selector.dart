import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/services.dart';

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
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
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
                      color: Colors.grey[100],
                    ),
                    continuousWaveform: true,
                    enableSeekGesture: false,
                    waveformType: WaveformType.fitWidth,
                    playerWaveStyle: PlayerWaveStyle(
                      fixedWaveColor: Colors.grey,
                      liveWaveColor: Theme.of(context).primaryColor,
                      showSeekLine: true,
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
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.5),
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
                              color: Theme.of(context).primaryColor,
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
                              color: Theme.of(context).primaryColor,
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
                        // Draggable icon above the handle
                        GestureDetector(
                          onPanUpdate: (details) {
                            const double speedMultiplier = 2.0;
                            final newStartPx = (widget.selectionStartPx ?? 0) +
                                details.delta.dx * speedMultiplier;
                            // Prevent overlap with end handle
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
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color: Theme.of(context).primaryColor,
                              size: 18,
                            ),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: Container(
                            width: 3,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
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
                        // Draggable icon above the handle
                        GestureDetector(
                          onPanUpdate: (details) {
                            const double speedMultiplier = 2.0;
                            final newEndPx = (widget.selectionEndPx ?? 0) +
                                details.delta.dx * speedMultiplier;
                            // Prevent overlap with start handle
                            final adjustedEndPx = widget.selectionStartPx !=
                                        null &&
                                    newEndPx <
                                        widget.selectionStartPx! +
                                            minHandleDistance
                                ? widget.selectionStartPx! + minHandleDistance
                                : newEndPx;

                            // Get the waveform width
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
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).primaryColor,
                              size: 18,
                            ),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: Container(
                            width: 3,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
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
              GestureDetector(
                onTap: () => widget.editTimeLine(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "Start: ${widget.startSec.toStringAsFixed(2)}s",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.editTimeLine,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "End: ${widget.endSec.toStringAsFixed(2)}s",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
