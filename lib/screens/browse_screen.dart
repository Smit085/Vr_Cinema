import 'package:flutter/material.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'dart:io';
import 'dart:typed_data';

import '../services/video_manager.dart';
import '../utils/video_utils.dart';
import 'video_player_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  Directory? currentDirectory;
  List<FileSystemEntity> filesAndFolders = [];
  List<FileSystemEntity> filteredFilesAndFolders = [];
  bool browsing = false;
  bool isLoading = false;
  bool isSearching = false;
  final searchController = TextEditingController();
  final Directory homeDirectory = Directory('/storage/emulated/0');
  final List<String> videoExtensions = [
    'mp4',
    'mkv',
    'flv',
    'avi',
    'mov',
    'wmv',
    'webm'
  ];
  final networkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterFilesAndFolders);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterFilesAndFolders);
    searchController.dispose();
    networkController.dispose();
    super.dispose();
  }

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

    try {
      await for (var entity in directory.list()) {
        if (FileSystemEntity.isDirectorySync(entity.path)) {
          directories.add(entity);
        } else if (isVideoFile(entity.path)) {
          videoFiles.add(entity);
        }
      }

      setState(() {
        filesAndFolders = [...directories, ...videoFiles];
        filteredFilesAndFolders = filesAndFolders;
      });
    } catch (e) {
      print("Error reading directory: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
    if (isSearching) {
      setState(() {
        isSearching = false;
        searchController.clear();
        filteredFilesAndFolders = filesAndFolders; // Reset search results
      });
    } else if (currentDirectory != null &&
        currentDirectory!.path != homeDirectory.path) {
      navigateToFolder(currentDirectory!.parent);
    } else {
      closeBrowsing(); // When at home directory, close browsing and search bar
    }
  }

  void closeBrowsing() {
    setState(() {
      browsing = false;
      currentDirectory = null;
      filesAndFolders.clear();
      isSearching = false; // Close search bar
      searchController.clear(); // Clear search input
      filteredFilesAndFolders = filesAndFolders; // Reset to full list
    });
  }

  String getFullPath() {
    if (currentDirectory == null || currentDirectory == homeDirectory) {
      return "Internal Storage";
    }
    String adjustedPath = currentDirectory!.path
        .replaceFirst(homeDirectory.path, "Internal Storage");
    return adjustedPath.startsWith("Internal Storage")
        ? adjustedPath
        : adjustedPath;
  }

  Future<Uint8List?> _getVideoThumbnail(String videoPath) async {
    return await VideoManager.loadOrGenerateThumbnail(videoPath);
  }

  Future<String> _getVideoDuration(String videoPath) async {
    final FlutterVideoInfo videoInfo = FlutterVideoInfo();
    try {
      var info = await videoInfo.getVideoInfo(videoPath);
      int durationMillis = (info?.duration as num).toInt();
      return formatDuration(durationMillis);
    } catch (e) {
      return "Unknown"; // or a default value
    }
  }

  void toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        searchController.clear();
        filteredFilesAndFolders = filesAndFolders;
      }
    });
  }

  void clearSearch() {
    searchController.clear();
    _filterFilesAndFolders();
  }

  void _filterFilesAndFolders() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredFilesAndFolders = filesAndFolders.where((entity) {
        String fileName = entity.path.split('/').last.toLowerCase();
        return fileName.contains(query);
      }).toList();
    });
  }

  void playNetworkStream() {
    String url = networkController.text.trim();
    if (Uri.tryParse(url)?.hasAbsolutePath == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoPaths: [url],
            initialIndex: 0,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid video URL")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool atHomeDirectory = currentDirectory?.path == homeDirectory.path;

    return Scaffold(
        appBar: AppBar(
          title: isSearching
              ? TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search videos...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: clearSearch,
                    ),
                  ),
                )
              : const Text('Internal Storage'),
          leading: browsing
              ? IconButton(
                  icon: Icon(atHomeDirectory ? Icons.close : Icons.arrow_back),
                  onPressed: atHomeDirectory
                      ? closeBrowsing
                      : goBack, // Close search on close button
                )
              : null, // Hide leading icon on home screen
          actions: [
            if (browsing &&
                !isSearching) // Show search and refresh only when browsing
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: toggleSearch,
              ),
            if (browsing &&
                !isSearching) // Show refresh icon only when browsing
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    listFilesAndFolders(currentDirectory ?? homeDirectory),
              ),
          ],
          bottom: browsing
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(30.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Text("Browser > ",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        Flexible(
                          child: Text(
                            getFullPath(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        body: WillPopScope(
          onWillPop: () async {
            goBack();
            return false; // Prevent default back action
          },
          child: browsing
              ? isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredFilesAndFolders.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off,
                                  size: 70, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                'No Media Found',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: filteredFilesAndFolders.length,
                          itemBuilder: (context, index) {
                            FileSystemEntity entity =
                                filteredFilesAndFolders[index];
                            bool isDirectory =
                                FileSystemEntity.isDirectorySync(entity.path);
                            String fileName = entity.path.split('/').last;
                            return FutureBuilder(
                              future: isDirectory
                                  ? null
                                  : Future.wait([
                                      _getVideoThumbnail(entity.path),
                                      _getVideoDuration(entity.path)
                                    ]),
                              builder: (context, snapshot) {
                                final data = snapshot.data as List<dynamic>?;
                                Uint8List? thumbnail = data?[0] as Uint8List?;
                                String duration = data?[1] as String? ?? '';
                                return ListTile(
                                  leading: isDirectory
                                      ? const Icon(Icons.folder,
                                          color: Colors.blue, size: 40)
                                      : thumbnail != null
                                          ? Image.memory(thumbnail,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover)
                                          : const Icon(Icons.videocam,
                                              color: Colors.grey),
                                  title: Text(fileName,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: isDirectory ? null : Text(duration),
                                  onTap: isDirectory
                                      ? () => navigateToFolder(
                                          Directory(entity.path))
                                      : () {
                                          final filteredVideos = filesAndFolders
                                              .where((file) =>
                                                  !FileSystemEntity
                                                      .isDirectorySync(
                                                          file.path) &&
                                                  isVideoFile(file.path))
                                              .toList();
                                          final initialIndex =
                                              filteredVideos.indexOf(entity);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VideoPlayerScreen(
                                                videoPaths: filteredVideos
                                                    .map((video) => video.path)
                                                    .toList(),
                                                initialIndex: initialIndex,
                                              ),
                                            ),
                                          );
                                        },
                                );
                              },
                            );
                          },
                        )
              : ListView(
                  padding: const EdgeInsets.all(10.0),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Storages",
                          style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sd_storage, color: Colors.blue),
                      title: const Text("Internal memory"),
                      onTap: loadInternalStorage,
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Network Stream",
                          style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.0),
                      child: TextField(
                        controller: networkController,
                        decoration: const InputDecoration(
                          hintText: "Enter video URL",
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: ElevatedButton.icon(
                          onPressed: playNetworkStream,
                          icon: Icon(
                            Icons.play_arrow,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          label: Text(
                            "Play",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            backgroundColor: Colors.blue,
                          ),
                        ))
                  ],
                ),
        ));
  }
}
