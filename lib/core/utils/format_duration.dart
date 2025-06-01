String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String threeDigits(int n) => n.toString().padLeft(3, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  final milliseconds = threeDigits(duration.inMilliseconds.remainder(1000));
  return "$minutes:$seconds.$milliseconds";
}