import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'Video_player_screen.dart';

class GroupedListScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> videos;

  const GroupedListScreen({Key? key, required this.title, required this.videos})
      : super(key: key);

  @override
  _GroupedListScreenState createState() => _GroupedListScreenState();
}

class _GroupedListScreenState extends State<GroupedListScreen> {
  bool isLoading = true;
  bool isSearching = false;
  bool isAscendingName = true;
  bool isAscendingDuration = true;
  bool isAscendingResolution = true;
  bool isBackgroundLoading = false;
  bool isListView = true; // For display view change
  String currentMenu = 'main'; // Tracks which menu to show
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> filteredVideos = [];

  @override
  void initState() {
    super.initState();
    fetchVideos();
    searchController
        .addListener(filterVideos); // Listen to changes in the search field
  }

  Future<void> fetchVideos() async {
    setState(() {
      isLoading = true;
      isBackgroundLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        videos = widget.videos;
        filteredVideos = videos;
        isLoading = false;
        isBackgroundLoading = false; // Set to false after loading is complete
      });
    });
  }

  @override
  void dispose() {
    searchController.removeListener(filterVideos);
    searchController.dispose();
    super.dispose();
  }

  void filterVideos() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredVideos = videos.where((video) {
        final videoName = video['file'].path.split('/').last.toLowerCase();
        return videoName.contains(query);
      }).toList();
    });
  }

  void toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        searchController.clear(); // Clear the search field
        filteredVideos = videos; // Reset filtered videos to original list
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

  void toggleDisplayView() {
    setState(() {
      isListView = !isListView;
    });
  }

  // Handle menu item selection
  void _handleMenuItem(String value) {
    setState(() {
      if (value == 'sort_by') {
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
              fontWeight: FontWeight.bold,
              color: Colors.grey,
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
    return WillPopScope(
      onWillPop: () async {
        if (isSearching) {
          toggleSearch();
          return false;
        }
        return true;
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
                  onChanged: (_) =>
                      filterVideos(), // Call filterVideos on each text change
                )
              : const Text('Videos'),
          leading: isSearching
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: toggleSearch,
                )
              : null,
          actions: [
            if (!isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: toggleSearch,
              ),
            if (!isSearching)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: fetchVideos,
              ),
            if (!isSearching)
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
            isListView
                ? ListView.builder(
                    itemCount: filteredVideos.length, // Use filteredVideos here
                    itemBuilder: (context, index) {
                      final video = filteredVideos[index];
                      final videoName = video['file'].path.split('/').last;
                      final thumbnail = video['thumbnail'];
                      final duration = video['duration'];
                      final resolution = video['resolution'];

                      return ListTile(
                        leading: thumbnail != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.memory(
                                  thumbnail,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 80,
                                ),
                              )
                            : const Icon(Icons.videocam, color: Colors.grey),
                        title: Text(
                          videoName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        subtitle: Text('$duration • $resolution'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                videoPaths: filteredVideos
                                    .map(
                                        (video) => video['file'].path as String)
                                    .toList(),
                                initialIndex: index,
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
                                        filteredVideos[index]['thumbnail']!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : const Icon(Icons.videocam, color: Colors.grey),
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
      ),
    );
  }
}
