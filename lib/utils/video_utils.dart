String formatDuration(int durationMillis) {
  final durationSeconds = (durationMillis / 1000).round();
  final hours = durationSeconds ~/ 3600;
  final minutes = (durationSeconds % 3600) ~/ 60;
  final seconds = durationSeconds % 60;

  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
      : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String formatResolution(int? height, int? width) {
  if (height == null || width == null) return 'Unknown';
  if (height >= 4320) return '8K';
  if (height >= 2160) return '4K';
  if (height >= 1440) return '2K';
  if (height >= 1080) return '1080p';
  if (height >= 720) return '720p';
  if (height >= 480) return '480p';
  return '320p';
}
