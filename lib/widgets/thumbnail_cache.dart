import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailCache {
  static Future<Uint8List?> loadThumbnail(String videoPath) async {
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
}
