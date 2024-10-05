import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/video_manager.dart';
import 'Video_player_screen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> filteredVideos = [];
  bool isLoading = true;
  bool isBackgroundLoading = false;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    setState(() {
      isLoading = true;
      isBackgroundLoading = true;
    });

    await VideoManager.loadCachedVideos((video) {
      if (!videos.any((v) => v['file'].path == video['file'].path)) {
        setState(() {
          videos.add(video);
          filteredVideos = videos; // Initialize filtered list
        });
      }
    });

    setState(() => isLoading = false);

    await searchForNewVideosInBackground();
    setState(() => isBackgroundLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          if (!isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: toggleSearch,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchVideos,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: filteredVideos.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: filteredVideos[index]['thumbnail'] != null
                    ? ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.memory(
                      filteredVideos[index]['thumbnail']!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 80,
                    ))
                    : const Icon(Icons.videocam),
                title: Text(
                  filteredVideos[index]['file'].path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                subtitle: Text(
                    '${filteredVideos[index]['duration']} • ${filteredVideos[index]['resolution']}'),
                onTap: () {
                  // Navigate to VideoDetailScreen and pass the videoPaths
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        videoPaths: filteredVideos.map((video) => video['file'].path as String).toList(),
                        initialIndex: index,
                      ),
                    ),
                  );
                },
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
                    color: Theme.of(context).brightness == Brightness.dark
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
    );
  }
}
