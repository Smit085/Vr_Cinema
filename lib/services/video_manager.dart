import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../utils/video_utils.dart';

class VideoManager {
  static final FlutterVideoInfo videoInfo = FlutterVideoInfo();

  static Future<void> loadCachedVideos(Function(Map<String, dynamic>) onVideoFound) async {
    try {
      final directories = await _getVideoDirectories();
      for (final directory in directories) {
        if (directory.existsSync()) {
          final files = directory.listSync(recursive: true);
          for (var item in files) {
            if (item is File && _isVideoFile(item.path)) {
              final thumbnailData = await _loadCachedThumbnail(item.path);
              if (thumbnailData != null) {
                final videoDetails = await _getVideoDetails(item.path);
                onVideoFound({
                  'file': item,
                  'thumbnail': thumbnailData,
                  'duration': videoDetails['duration'],
                  'resolution': videoDetails['resolution'],
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error loading cached videos: $e");
    }
  }

  static Future<void> searchForNewVideos(Function(Map<String, dynamic>) onVideoFound) async {
    try {
      final directories = await _getVideoDirectories();
      for (final directory in directories) {
        if (directory.existsSync()) {
          final files = directory.listSync(recursive: true);
          for (var item in files) {
            if (item is File && _isVideoFile(item.path)) {
              final thumbnailData = await loadOrGenerateThumbnail(item.path);
              final videoDetails = await _getVideoDetails(item.path);
              onVideoFound({
                'file': item,
                'thumbnail': thumbnailData,
                'duration': videoDetails['duration'],
                'resolution': videoDetails['resolution'],
              });
            }
          }
        }
      }
    } catch (e) {
      print("Error searching for new videos: $e");
    }
  }

  static Future<Map<String, String>> _getVideoDetails(String videoPath) async {
    try {
      var info = await videoInfo.getVideoInfo(videoPath);

      if (info == null) {
        return {'duration': 'Unknown', 'resolution': 'Unknown'};
      }

      int durationMillis = (info.duration as num).toInt();
      int? height = (info.height as num?)?.toInt();
      int? width = (info.width as num?)?.toInt();

      String duration = formatDuration(durationMillis);
      String resolution = formatResolution(height, width);

      return {'duration': duration, 'resolution': resolution};
    } catch (e) {
      print("Error getting video details: $e");
      return {'duration': 'Unknown', 'resolution': 'Unknown'};
    }
  }

  static Future<Uint8List?> _loadCachedThumbnail(String videoPath) async {
    final thumbnailDir = await getApplicationDocumentsDirectory();
    final thumbnailFile = File('${thumbnailDir.path}/${_getThumbnailFileName(videoPath)}');
    return thumbnailFile.existsSync() ? await thumbnailFile.readAsBytes() : null;
  }

  static Future<Uint8List?> loadOrGenerateThumbnail(String videoPath) async {
    final thumbnailDir = await getApplicationDocumentsDirectory();
    final thumbnailFile = File('${thumbnailDir.path}/${_getThumbnailFileName(videoPath)}');

    if (thumbnailFile.existsSync()) {
      return await thumbnailFile.readAsBytes();
    } else {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailDir.path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 500,
        quality: 100,
      );
      if (thumbnailPath != null) {
        final generatedThumbnail = await File(thumbnailPath).readAsBytes();
        await thumbnailFile.writeAsBytes(generatedThumbnail);
        return generatedThumbnail;
      }
    }
    return null;
  }

  static String _getThumbnailFileName(String videoPath) {
    return "${videoPath.split('/').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.png";
  }

  static Future<List<Directory>> _getVideoDirectories() async {
    List<Directory> directories = [];
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      directories.add(externalDir);
    }

    directories.addAll([
      Directory('/storage/emulated/0/Android/Media'),
      Directory('/storage/emulated/0/DCIM'),
      Directory('/storage/emulated/0/Movies'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Pictures'),
    ]);
    return directories;
  }

  static bool _isVideoFile(String path) {
    const videoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.flv'];
    return videoExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }
}
