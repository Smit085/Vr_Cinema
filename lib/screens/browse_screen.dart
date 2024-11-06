import 'package:flutter/material.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'dart:io';
import 'dart:typed_data';

import '../services/video_manager.dart';
import '../utils/video_utils.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  Directory? currentDirectory;
  List<FileSystemEntity> filesAndFolders = [];
  bool browsing = false;
  bool isLoading = false;
  final Directory homeDirectory = Directory('/storage/emulated/0');
  final List<String> videoExtensions = ['mp4', 'mkv', 'flv', 'avi', 'mov', 'wmv', 'webm'];

  Future<void> loadInternalStorage() async {
    setState(() {
      currentDirectory = homeDirectory;
      browsing = true;
    });
    await listFilesAndFolders(homeDirectory);
  }

  Future<void> listFilesAndFolders(Directory directory) async {
    setState(() {
      filesAndFolders.clear();
      isLoading = true;
    });

    List<FileSystemEntity> directories = [];
    List<FileSystemEntity> videoFiles = [];

    await for (var entity in directory.list()) {
      if (FileSystemEntity.isDirectorySync(entity.path)) {
        directories.add(entity);
      } else if (isVideoFile(entity.path)) {
        videoFiles.add(entity);
      }

      setState(() {
        filesAndFolders = [...directories, ...videoFiles];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  bool isVideoFile(String path) {
    String extension = path.split('.').last.toLowerCase();
    return videoExtensions.contains(extension);
  }

  void navigateToFolder(Directory directory) async {
    setState(() {
      currentDirectory = directory;
    });
    await listFilesAndFolders(directory);
  }

  void goBack() {
    if (currentDirectory != null && currentDirectory!.path != homeDirectory.path) {
      navigateToFolder(currentDirectory!.parent);
    }
  }

  void closeBrowsing() {
    setState(() {
      browsing = false;
      currentDirectory = null;
      filesAndFolders.clear();
    });
  }

  String getFullPath() {
    // Start from "Browser > Internal Storage" only if we're in the home directory
    if (currentDirectory == null || currentDirectory == homeDirectory) {
      return "Browser > Internal Storage";
    }

    // Replace the home directory part with "Internal Storage" and create path segments
    List<String> pathSegments = currentDirectory!.path
        .replaceFirst(homeDirectory.path, "Internal Storage")
        .split(Platform.pathSeparator);

    // Join the path segments with " > "
    return "Browser > ${pathSegments.join(" > ")}";
  }

  Future<Uint8List?> _getVideoThumbnail(String videoPath) async {
    return await VideoManager.loadOrGenerateThumbnail(videoPath);
  }

  Future<String> _getVideoDuration(String videoPath) async {
    final FlutterVideoInfo videoInfo = FlutterVideoInfo();
    var info = await videoInfo.getVideoInfo(videoPath);
    int durationMillis = (info?.duration as num).toInt();
    String duration = formatDuration(durationMillis);
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    bool atHomeDirectory = currentDirectory?.path == homeDirectory.path;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Internal Storage"),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () {
              // Toggle to grid view, implement as needed
            },
          ),
        ],
        bottom: browsing
            ? PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text(
                  "Browser > ",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      String fullPath = getFullPath();
                      String displayPath = fullPath;

                      while (_textWidth(displayPath, context) > constraints.maxWidth) {
                        int nextSeparatorIndex = displayPath.indexOf(" > ") + 3;
                        if (nextSeparatorIndex < displayPath.length) {
                          displayPath = "… " + displayPath.substring(nextSeparatorIndex);
                        } else {
                          break;
                        }
                      }

                      return Text(
                        displayPath,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        )
            : null,
        leading: browsing
            ? IconButton(
          icon: Icon(atHomeDirectory ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (atHomeDirectory) {
              closeBrowsing();
            } else {
              goBack();
            }
          },
        )
            : null,
      ),
      body: browsing
          ? filesAndFolders.isEmpty && isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: filesAndFolders.length,
        itemBuilder: (context, index) {
          FileSystemEntity entity = filesAndFolders[index];
          bool isDirectory = FileSystemEntity.isDirectorySync(entity.path);
          String fileName = entity.path.split('/').last;

          return FutureBuilder(
            future: isDirectory ? null : Future.wait([
              _getVideoThumbnail(entity.path),
              _getVideoDuration(entity.path),
            ]),
            builder: (context, snapshot) {
              final data = snapshot.data as List<dynamic>?; // Cast snapshot.data to List<dynamic>
              Uint8List? thumbnail = data?[0] as Uint8List?; // Cast the first item as Uint8List
              String duration = data?[1] as String? ?? ''; // Cast the second item as String

              return ListTile(
                leading: isDirectory
                    ? const Icon(Icons.folder, color: Colors.orange, size: 40,)
                    : thumbnail != null
                    ? Image.memory(thumbnail, width: 40, height: 40, fit: BoxFit.cover)
                    : const Icon(Icons.videocam, color: Colors.grey),
                title: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          fileName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: isDirectory
                    ? null
                    : Text(
                  duration,
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: isDirectory
                    ? () => navigateToFolder(Directory(entity.path))
                    : () {
                  // Handle file selection, such as opening the file or previewing
                },
              );
            },
          );
        },
      )
          : ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Storages",
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sd_storage, color: Colors.grey),
            title: const Text("Internal memory"),
            onTap: loadInternalStorage,
          ),
        ],
      ),
    );
  }

  double _textWidth(String text, BuildContext context) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 14)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }
}
