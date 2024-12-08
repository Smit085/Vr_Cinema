import 'dart:math';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vr_cinema/screens/grouped_list_screen.dart';
import 'package:vr_cinema/utils/AppColors.dart';
import '../services/video_manager.dart';
import '../utils/PreferencesManager.dart';
import 'Video_player_screen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> filteredVideos = [];
  List<Map<String, dynamic>> singleVideos = [];
  bool isLoading = true;
  bool isBackgroundLoading = false;
  bool isSearching = false;
  bool isAscendingName = true;
  bool isAscendingDuration = true;
  bool isAscendingResolution = true;
  bool isListView = true;
  bool isGroupedView = false;
  TextEditingController searchController = TextEditingController();
  String currentMenu = 'main'; // Tracks which menu to show

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    fetchVideos();
  }

  void _loadPreferences() async {
    var savedViewType = await PreferencesManager.getViewType();

    setState(() {
      isListView = savedViewType;
    });
  }

  Future<void> fetchVideos() async {
    setState(() {
      isLoading = true;
      isBackgroundLoading = true;
    });

    await VideoManager.loadCachedVideos((video) {
      if (!videos.any((v) => v['file'].path == video['file'].path)) {
        if (mounted) {
          setState(() {
            videos.add(video);
            filteredVideos = videos;
          });
        }
      }
    });

    setState(() {
      isLoading = false;
      isBackgroundLoading = false;
    });
    await searchForNewVideosInBackground();
  }

  Future<void> searchForNewVideosInBackground() async {
    await VideoManager.searchForNewVideos((video) {
      if (!videos.any((v) => v['file'].path == video['file'].path)) {
        setState(() {
          videos.add(video);
          filteredVideos = videos;
        });
      }
    });
  }

  void filterVideos(String query) {
    setState(() {
      filteredVideos = videos.where((video) {
        final title = video['file'].path.split('/').last.toLowerCase();
        final searchTerm = query.toLowerCase();
        return title.contains(searchTerm);
      }).toList();
    });
  }

  void toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        searchController.clear();
        filteredVideos = videos;
      }
    });
  }

  // Sorting functions
  void sortByName() {
    setState(() {
      filteredVideos.sort((a, b) {
        return isAscendingName
            ? a['file']
                .path
                .split('/')
                .last
                .toLowerCase()
                .compareTo(b['file'].path.split('/').last.toLowerCase())
            : b['file']
                .path
                .split('/')
                .last
                .toLowerCase()
                .compareTo(a['file'].path.split('/').last.toLowerCase());
      });
      isAscendingName = !isAscendingName; // Toggle the sorting order
    });
  }

  void sortByDuration() {
    setState(() {
      filteredVideos.sort((a, b) {
        final durationA = _convertDurationToSeconds(a['duration']);
        final durationB = _convertDurationToSeconds(b['duration']);
        return isAscendingDuration
            ? durationA.compareTo(durationB)
            : durationB.compareTo(durationA);
      });
      isAscendingDuration = !isAscendingDuration; // Toggle the sorting order
    });
  }

  int _convertDurationToSeconds(String duration) {
    if (duration.isEmpty) return 0;
    final parts = duration.split(':').map(int.parse).toList();
    if (parts.length == 3) {
      // hh:mm:ss
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.length == 2) {
      // mm:ss
      return parts[0] * 60 + parts[1];
    } else {
      // If the duration is in seconds only
      return parts[0];
    }
  }

  void sortByResolution() {
    setState(() {
      filteredVideos.sort((a, b) {
        final resolutionA = resolutionToNumericValue(a['resolution']);
        final resolutionB = resolutionToNumericValue(b['resolution']);
        return isAscendingResolution
            ? resolutionA.compareTo(resolutionB)
            : resolutionB.compareTo(resolutionA);
      });
      isAscendingResolution =
          !isAscendingResolution; // Toggle the sorting order
    });
  }

  int resolutionToNumericValue(String resolution) {
    // Map the resolution to a numeric value for comparison
    switch (resolution) {
      case '4K':
        return 5;
      case '2K':
        return 4;
      case '1080p':
        return 3;
      case '720p':
        return 2;
      case '480p':
        return 1;
      case '360p':
        return 0;
      default:
        return -1; // Handle unknown resolutions
    }
  }

  // Grouping functions
  void groupByNone() {
    setState(() {
      isGroupedView = false; // Disable grouping
      filteredVideos = List.from(videos);
    });
  }

  void groupByFolder() {
    setState(() {
      isGroupedView = true;
      final Map<String, List<Map<String, dynamic>>> groupedVideos = {};
      for (var video in videos) {
        final folder =
            video['file'].parent.path.split('/').last; // Get folder name
        if (!groupedVideos.containsKey(folder)) {
          groupedVideos[folder] = [];
        }
        groupedVideos[folder]!.add(video);
      }
      filteredVideos = groupedVideos.entries.map((entry) {
        return {
          'folder': entry.key,
          'videos': entry.value,
        };
      }).toList();
    });
  }

  void groupByName() {
    setState(() {
      isGroupedView = true;

      final Map<String, List<Map<String, dynamic>>> groupedVideos = {};

      for (var video in videos) {
        final videoName = video['file'].path.split('/').last;
        final videoWords = _extractWords(videoName);

        String bestMatchingGroup = '';
        bool isGrouped = false;

        for (var groupName in groupedVideos.keys) {
          final groupWords = _extractWords(groupName);

          if (videoWords.any((word) => groupWords.contains(word))) {
            bestMatchingGroup = groupName;
            isGrouped = true;
            break;
          }
        }

        if (!isGrouped) {
          bestMatchingGroup = videoName;
        }

        groupedVideos.putIfAbsent(bestMatchingGroup, () => []).add(video);
      }

      final Map<String, List<Map<String, dynamic>>> updatedGroups = {};

      groupedVideos.forEach((groupName, videos) {
        if (videos.length > 1) {
          List videoNames = videos
              .map((video) => video['file'].path.split('/').last)
              .toList();

          String commonPrefix = videoNames
              .reduce((common, name) => _longestCommonPrefix(common, name));
          updatedGroups[commonPrefix] = videos;
        } else {
          updatedGroups[groupName] = videos;
        }
      });

      filteredVideos = [];
      singleVideos = [];

      updatedGroups.forEach((key, value) {
        if (value.length > 1) {
          filteredVideos.add({
            'folder': key,
            'videos': value,
          });
        } else {
          singleVideos.add(value.first);
        }
      });
    });
  }

  void toggleDisplayView() {
    setState(() {
      isListView = !isListView;
    });
    PreferencesManager.saveViewType(isListView);
  }

// Helper function to extract words from the file name
  List<String> _extractWords(String fileName) {
    final nameWithoutExtension = fileName.split('.').first;
    return nameWithoutExtension
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

// Helper function to find the longest common prefix between two strings
  String _longestCommonPrefix(String s1, String s2) {
    int minLength = s1.length < s2.length ? s1.length : s2.length;
    int matchLength = 0;

    for (int i = 0; i < minLength; i++) {
      if (s1[i] == s2[i]) {
        matchLength++;
      } else {
        break;
      }
    }

    return s1.substring(0, matchLength);
  }

  // Handle menu item selection
  void _handleMenuItem(String value) {
    setState(() {
      if (value == 'sort_by' || value == 'group_by') {
        // Switch to the corresponding submenu
        currentMenu = value;
        _showCustomMenu(context); // Show the submenu
      } else {
        // Handle actual sorting or grouping
        switch (value) {
          case 'sort_by_name':
            sortByName();
            break;
          case 'sort_by_duration':
            sortByDuration();
            break;
          case 'sort_by_resolution':
            sortByResolution();
            break;
          case 'group_by_none':
            groupByNone();
            break;
          case 'group_by_name':
            groupByName();
            break;
          case 'group_by_folder':
            groupByFolder();
            break;
          case 'display_view':
            toggleDisplayView();
            break;
          case 'refresh':
            fetchVideos();
            break;
        }
        // Reset to main menu after handling action
        currentMenu = 'main';
      }
    });
  }

  // Build menu items dynamically based on current menu
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    if (currentMenu == 'main') {
      return [
        const PopupMenuItem(
          value: 'sort_by',
          child: ListTile(
            title: Text('Sort by...'),
            trailing: Icon(Icons.arrow_right),
          ),
        ),
        const PopupMenuItem(
          value: 'group_by',
          child: ListTile(
            title: Text('Group Videos'),
            trailing: Icon(Icons.arrow_right),
          ),
        ),
        PopupMenuItem(
          value: 'display_view',
          child: ListTile(
            title: Text(isListView ? 'Display in grid' : 'Display in list'),
          ),
        ),
        const PopupMenuItem(
          value: 'refresh',
          child: ListTile(
            title: Text('Refresh'),
          ),
        ),
      ];
    } else if (currentMenu == 'sort_by') {
      return [
        const PopupMenuItem(
          enabled: false,
          child: Text(
            'Sort by...',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'sort_by_name',
          child: ListTile(
            title: const Text('Name'),
            trailing: Icon(
                isAscendingName ? Icons.arrow_drop_up : Icons.arrow_drop_down),
          ),
        ),
        PopupMenuItem(
          value: 'sort_by_duration',
          child: ListTile(
            title: const Text('Duration'),
            trailing: Icon(isAscendingDuration
                ? Icons.arrow_drop_up
                : Icons.arrow_drop_down),
          ),
        ),
        PopupMenuItem(
          value: 'sort_by_resolution',
          child: ListTile(
            title: const Text('Resolution'),
            trailing: Icon(isAscendingResolution
                ? Icons.arrow_drop_up
                : Icons.arrow_drop_down),
          ),
        ),
      ];
    } else if (currentMenu == 'group_by') {
      return [
        const PopupMenuItem(
          enabled: false,
          child: Text(
            'Group videos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'group_by_none',
          child: Text('None'),
        ),
        const PopupMenuItem(
          value: 'group_by_name',
          child: Text('Name'),
        ),
        const PopupMenuItem(
          value: 'group_by_folder',
          child: Text('Folder'),
        ),
      ];
    }
    return [];
  }

  void _showCustomMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    const double menuWidth =
        200; // Adjust this if needed to fit your menu items
    const double menuHeight =
        200; // Adjust this if needed to fit your menu items

    // Calculate position for top right
    final RelativeRect position = RelativeRect.fromLTRB(
      overlay.size.width - menuWidth, // X position (right)
      0, // Y position (top)
      overlay.size.width, // Right edge
      menuHeight, // Bottom edge (can set as per menu height)
    );

    showMenu<String>(
      context: context,
      position: position,
      items: _buildMenuItems(context),
    ).then((value) {
      // Reset to main menu if menu is closed without selection
      if (value == null) {
        setState(() {
          currentMenu = 'main';
        });
      } else {
        _handleMenuItem(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return WillPopScope(
        onWillPop: () async {
          if (isSearching) {
            toggleSearch();
            return false; // Prevents the app from closing
          }
          return true; // Allows the app to close
        },
        child: Scaffold(
          appBar: AppBar(
            title: isSearching
                ? TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search videos...',
                      border: InputBorder.none,
                    ),
                    onChanged: filterVideos,
                  )
                : const Text('Videos'),
            leading: isSearching
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: toggleSearch,
                  )
                : null,
            actions: [
              if (!isSearching && !isLoading)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: toggleSearch,
                ),
              if (!isSearching && !isLoading)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: fetchVideos,
                ),
              if (!isSearching && !isLoading)
                GestureDetector(
                  onTap: () => _showCustomMenu(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.more_vert),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              isGroupedView
                  ? ListView.builder(
                      itemCount: singleVideos.length + filteredVideos.length,
                      itemBuilder: (context, index) {
                        if (index < singleVideos.length) {
                          // Render single videos first
                          final video = singleVideos[index];
                          String videoTitle =
                              video['file'].path.split('/').last;
                          return ListTile(
                            leading: video['thumbnail'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: Image.memory(
                                      video['thumbnail']!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 80,
                                    ),
                                  )
                                : const Icon(Icons.videocam,
                                    color: Colors.grey),
                            title: Text(
                              video['file'].path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            subtitle: Text(
                                '${video['duration']} • ${video['resolution']}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(
                                    videoPaths: singleVideos
                                        .map((v) => v['file'].path as String)
                                        .toList(),
                                    initialIndex: index,
                                    title: videoTitle,
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          // Render grouped folders at the end
                          final folder =
                              filteredVideos[index - singleVideos.length];
                          return FolderListTile(folder: folder);
                        }
                      },
                    )
                  : isListView
                      ? ListView.builder(
                          itemCount: filteredVideos.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: filteredVideos[index]['thumbnail'] !=
                                      null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: Image.memory(
                                        filteredVideos[index]['thumbnail']!,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 80,
                                      ),
                                    )
                                  : const Icon(Icons.videocam,
                                      color: Colors.grey),
                              title: Text(
                                filteredVideos[index]['file']
                                    .path
                                    .split('/')
                                    .last,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              subtitle: Text(
                                  '${filteredVideos[index]['duration']} • ${filteredVideos[index]['resolution']}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPlayerScreen(
                                      videoPaths: filteredVideos
                                          .map((video) =>
                                              video['file'].path as String)
                                          .toList(),
                                      initialIndex: index,
                                      title: filteredVideos[index]['file']
                                          .path
                                          .split('/')
                                          .last,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(
                              4.0), // Add padding around the grid
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Number of columns in the grid
                            crossAxisSpacing: 2.0,
                            mainAxisSpacing: 2.0,
                            childAspectRatio:
                                3 / 2, // Adjust the aspect ratio as needed
                          ),
                          itemCount: filteredVideos.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(
                                  4.0), // Padding around each grid item
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to VideoDetailScreen and pass the videoPaths
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerScreen(
                                        videoPaths: filteredVideos
                                            .map((video) =>
                                                video['file'].path as String)
                                            .toList(),
                                        initialIndex: index,
                                        title: filteredVideos[index]['file']
                                            .path
                                            .split('/')
                                            .last,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Stack(
                                    children: [
                                      filteredVideos[index]['thumbnail'] != null
                                          ? Image.memory(
                                              filteredVideos[index]
                                                  ['thumbnail']!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          : const Icon(Icons.videocam,
                                              color: Colors.grey),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          color: Colors.black54,
                                          padding: const EdgeInsets.all(4.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                filteredVideos[index]['file']
                                                    .path
                                                    .split('/')
                                                    .last,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              Text(
                                                '${filteredVideos[index]['duration']} • ${filteredVideos[index]['resolution']}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  alignment: Alignment.center,
                  duration: const Duration(milliseconds: 450),
                  height: isBackgroundLoading ? 30 : 0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    color: Colors.black12,
                  ),
                  margin: const EdgeInsets.all(0),
                  padding: const EdgeInsets.all(2),
                  child: isBackgroundLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Searching for videos",
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 10),
                            LoadingAnimationWidget.staggeredDotsWave(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              size: 25,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class FolderListTile extends StatelessWidget {
  final Map<String, dynamic> folder;

  const FolderListTile({required this.folder});

  @override
  Widget build(BuildContext context) {
    final videos = folder['videos'] as List<Map<String, dynamic>>;
    final folderName =
        folder.containsKey('folder') ? folder['folder'] : folder['prefix'];
    final videoCount = videos.length;

    return ListTile(
      leading: videos.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(
                  5), // Apply radius to the outer card only
              child: Container(
                width: 100, // Width of the card
                height: 80, // Height of the card
                child: videos.length < 4
                    ? GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Two images per row
                          childAspectRatio: 1, // Square aspect ratio
                          mainAxisSpacing: 0, // No spacing between rows
                          crossAxisSpacing: 0, // No spacing between columns
                        ),
                        itemCount: videos.length, // Show all available images
                        itemBuilder: (context, index) {
                          return Container(
                            child: videos[index]['thumbnail'] != null
                                ? Image.memory(
                                    videos[index]['thumbnail'],
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.videocam,
                                    color: Colors.grey),
                          );
                        },
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    child: videos[0]['thumbnail'] != null
                                        ? Image.memory(
                                            videos[0]['thumbnail'],
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.videocam,
                                            color: Colors.grey),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    child: videos[1]['thumbnail'] != null
                                        ? Image.memory(
                                            videos[1]['thumbnail'],
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.videocam,
                                            color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    child: videos.length > 2 &&
                                            videos[2]['thumbnail'] != null
                                        ? Image.memory(
                                            videos[2]['thumbnail'],
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.videocam,
                                            color: Colors.grey),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    child: videos.length > 3 &&
                                            videos[3]['thumbnail'] != null
                                        ? Image.memory(
                                            videos[3]['thumbnail'],
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.videocam,
                                            color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            )
          : const Icon(Icons.folder, size: 50),
      title: Text(
        folderName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('$videoCount ${videoCount == 1 ? "video" : "videos"}'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupedListScreen(
              title: folderName,
              videos: folder['videos'], // Pass the group of videos
            ),
          ),
        );
      },
    );
  }
}
