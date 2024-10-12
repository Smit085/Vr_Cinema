import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:vr_cinema/screens/vr_cinema_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<String> videoPaths;
  final int initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.videoPaths,
    required this.initialIndex,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late VlcPlayerController _vlcPlayerController;

  Future<void> initializePlayer() async {}
  late Timer _timer;
  late Timer _controlsTimer;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isFullscreen = false;
  // final bool _subtitlesEnabled = true;
  bool _controlsVisible = true;
  int _volume = 50;
  int _currentIndex = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _aspectRatio = 16 / 9;
  double selectedSpeed = 1.0;
  late String currentVideoPath;


  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    currentVideoPath = widget.videoPaths[_currentIndex];
    _vlcPlayerController =
        VlcPlayerController.file(File(currentVideoPath));
    print(currentVideoPath);

    Future.delayed(const Duration(milliseconds: 300), () {
      _vlcPlayerController.play();
      _vlcPlayerController.setVolume(_volume);
      _isPlaying = true;
      print("Track ${_vlcPlayerController.getSpuTrack().toString()}");
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _position = _vlcPlayerController.value.position ?? Duration.zero;
        _duration = _vlcPlayerController.value.duration ?? Duration.zero;
      });
    });

    _vlcPlayerController.addListener(() {
      setState(() {
        _position = _vlcPlayerController.value.position ?? Duration.zero;
        _duration = _vlcPlayerController.value.duration ?? Duration.zero;
        _isPlaying = _vlcPlayerController.value.isPlaying;
      });
    });

    _startControlsTimer();
  }

  @override
  void dispose() {
    _vlcPlayerController.stop();
    _vlcPlayerController.dispose();
    _timer.cancel();
    _controlsTimer.cancel();
    super.dispose();
  }

  void _startControlsTimer() {
    _controlsTimer = Timer.periodic(const Duration(seconds: 3), (Timer t) {
      if (_controlsVisible) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      if (_controlsVisible) {
        _controlsTimer.cancel();
        _startControlsTimer();
      }
    });
  }

  void _playPauseVideo() {
    setState(() {
      if (_isPlaying) {
        _vlcPlayerController.pause();
        _animationController.forward();
      } else {
        _vlcPlayerController.play();
        _animationController.reverse();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _seekTo(Duration position) {
    _vlcPlayerController.seekTo(position);
  }

  void _changeVolume(double volume) {
    setState(() {
      _volume = volume.toInt();
      _vlcPlayerController.setVolume(_volume);
    });
  }

  void _previousVideo() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _vlcPlayerController.stop();
        _vlcPlayerController =
            VlcPlayerController.file(File(widget.videoPaths[_currentIndex]));
        _vlcPlayerController.play();
        _position = Duration.zero;
      }
    });
  }

  void _nextVideo() {
    setState(() {
      if (_currentIndex < widget.videoPaths.length - 1) {
        _currentIndex++;
        _vlcPlayerController.stop();
        _vlcPlayerController =
            VlcPlayerController.file(File(widget.videoPaths[_currentIndex]));
        _vlcPlayerController.play();
        _position = Duration.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _aspectRatio,
                child: VlcPlayer(
                  controller: _vlcPlayerController,
                  aspectRatio: _aspectRatio,
                  placeholder: const Center(
                      child: CircularProgressIndicator(
                    color: Colors.red,
                  )),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black.withOpacity(.5),
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7.0),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16.0),
                        activeTrackColor: Colors.redAccent,
                        inactiveTrackColor: Colors.grey,
                        thumbColor: Colors.red,
                        overlayColor: Colors.red.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _position.inSeconds.toDouble(),
                        min: 0,
                        max: _duration.inSeconds.toDouble(),
                        onChanged: (double value) {
                          _seekTo(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // First Row with Controls and Duration
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                icon: AnimatedIcon(
                                  icon: AnimatedIcons.pause_play,
                                  progress: _animationController,
                                  color: Colors.white,
                                ),
                                onPressed: _playPauseVideo,
                              ),
                              IconButton(
                                icon: Icon(
                                  _isMuted ? Icons.volume_off : Icons.volume_up,
                                  color: _isMuted ? Colors.red : Colors.white,
                                ),
                                onPressed: _toggleMute,
                              ),
                              // Use Flexible and SingleChildScrollView for duration texts
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min, // Keep this row size to a minimum
                                    children: [
                                      Text(_formatDuration(_position)),
                                      const Text(" / "),
                                      Text(_formatDuration(_duration)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Second Row with Settings and Subtitles
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: _toggleSettings,
                            ),
                            IconButton(
                              icon: const Icon(Icons.subtitles),
                              onPressed: _toggleSubtitles,
                            ),
                            IconButton(
                              icon: Icon(
                                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                color: _isFullscreen ? Colors.red : Colors.white,
                              ),
                              onPressed: _toggleFullscreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle Subtitles
  void _toggleSubtitles() async {
    // Fetch subtitle tracks and audio tracks
    final Map<int, String> subtitleTracks =
        await _vlcPlayerController.getSpuTracks();
    final Map<int, String> audioTracks =
        await _vlcPlayerController.getAudioTracks();
    int? activeAudioTrack = await _vlcPlayerController.getAudioTrack();
    int? activeSubtitleTrack = await _vlcPlayerController.getSpuTrack();

    if ((subtitleTracks.isNotEmpty ?? false) ||
        (audioTracks.isNotEmpty ?? false)) {
      showModalBottomSheet(
        shape: const BeveledRectangleBorder(),
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audio Tracks List on the left side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (audioTracks.isNotEmpty ?? false) ...[
                        Text(
                          "Audio Tracks",
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontSize: 16.0, // Adjust the font size
                                    fontWeight:
                                        FontWeight.bold, // Make the text bold
                                  ),
                        ),
                        const SizedBox(height: 8.0),
                        Expanded(
                          child: ListView(
                            children: [
                              ListTile(
                                title: const Text("Disable Audio",
                                    style: TextStyle(fontSize: 12)),
                                trailing: activeAudioTrack == -1
                                    ? const Icon(Icons.check)
                                    : null,
                                onTap: () {
                                  _vlcPlayerController.setAudioTrack(-1);
                                  Navigator.pop(context); // Close the modal
                                },
                              ),
                              ...audioTracks.entries.map((entry) {
                                final trackId = entry.key;
                                final trackName = entry.value;
                                return ListTile(
                                  title: Text(trackName,
                                      style: const TextStyle(fontSize: 12)),
                                  trailing: activeAudioTrack == trackId
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    _vlcPlayerController.setAudioTrack(trackId);
                                    Navigator.pop(context); // Close the modal
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Vertical divider between Audio and Subtitle lists
                const VerticalDivider(),
                // Subtitle Tracks List on the right side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitleTracks.isNotEmpty ?? false) ...[
                        Text(
                          "Subtitle Tracks",
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontSize: 16.0, // Adjust the font size
                                    fontWeight:
                                        FontWeight.bold, // Make the text bold
                                  ),
                        ),
                        const SizedBox(height: 8.0),
                        Expanded(
                          child: ListView(
                            children: [
                              ListTile(
                                title: const Text("Disable Subtitle",
                                    style: TextStyle(fontSize: 12)),
                                trailing: activeSubtitleTrack == -1
                                    ? const Icon(Icons.check)
                                    : null,
                                onTap: () {
                                  _vlcPlayerController.setSpuTrack(-1);
                                  Navigator.pop(context); // Close the modal
                                },
                              ),
                              ...subtitleTracks.entries.map((entry) {
                                final trackId = entry.key;
                                final trackName = entry.value;
                                return ListTile(
                                  title: Text(trackName,
                                      style: const TextStyle(fontSize: 12)),
                                  trailing: activeSubtitleTrack == trackId
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    _vlcPlayerController.setSpuTrack(trackId);
                                    Navigator.pop(context); // Close the modal
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      print("No audio or subtitle tracks available");
    }
  }

  void _toggleSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      builder: (BuildContext context) {
        bool showingSpeedOptions = false; // Reset every time the modal is opened

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            print("Bottom sheet opened");

            return Container(
              padding: const EdgeInsets.all(8.0),
              constraints: const BoxConstraints(
                maxWidth: 300,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!showingSpeedOptions) ...[
                      ListTile(
                        title: const Text('Playback Speed'),
                        trailing: const Icon(Icons.speed),
                        onTap: () {
                          print("Playback Speed tapped");
                          setState(() {
                            showingSpeedOptions = true;
                          });
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Watch In VR_Room'),
                        trailing: const Icon(Icons.settings),
                        onTap: () {
                          _vlcPlayerController.pause();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VrCinemaScreen(videoPath: currentVideoPath, initialScene: 'VR_Room',),
                            ),
                          );
                          print("Watch In VR Tapped");
                        },
                      ),
                      ListTile(
                        title: const Text('Watch In VR_Livingroom'),
                        trailing: const Icon(Icons.settings),
                        onTap: () {
                          _vlcPlayerController.pause();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VrCinemaScreen(videoPath: currentVideoPath, initialScene: 'VR_Livingroom',),
                            ),
                          );
                          print("Watch In VR Tapped");
                        },
                      ),
                    ] else ...[
                      SizedBox(
                        height: 300, // Set the desired height for the speed options
                        child: SingleChildScrollView( // Allows scrolling if content exceeds height
                          child: Column(
                            children: [
                              ListTile(
                                title: const Text('0.25x'),
                                trailing: selectedSpeed == 0.25 ? const Icon(Icons.check) : null,
                                onTap: () {
                                  print("0.25x speed selected");
                                  setState(() {
                                    selectedSpeed = 0.25;
                                  });
                                  _vlcPlayerController.setPlaybackSpeed(0.25);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text('0.5x'),
                                trailing: selectedSpeed == 0.5 ? const Icon(Icons.check) : null,
                                onTap: () {
                                  print("0.5x speed selected");
                                  setState(() {
                                    selectedSpeed = 0.5;
                                  });
                                  _vlcPlayerController.setPlaybackSpeed(0.5);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text('0.75x'),
                                trailing: selectedSpeed == 0.75 ? const Icon(Icons.check) : null,
                                onTap: () {
                                  print("0.75x speed selected");
                                  setState(() {
                                    selectedSpeed = 0.75;
                                  });
                                  _vlcPlayerController.setPlaybackSpeed(0.75);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text('1.0x (Normal)'),
                                trailing: selectedSpeed == 1.0 ? const Icon(Icons.check) : null,
                                onTap: () {
                                  print("1.0x speed selected");
                                  setState(() {
                                    selectedSpeed = 1.0;
                                  });
                                  _vlcPlayerController.setPlaybackSpeed(1.0);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text('1.25x'),
                                trailing: selectedSpeed == 1.25 ? const Icon(Icons.check) : null,
                                onTap: () {
                                  print("1.25x speed selected");
                                  setState(() {
                                    selectedSpeed = 1.25;
                                  });
                                  _vlcPlayerController.setPlaybackSpeed(1.25);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text('1.5x'),
                                trailing: selectedSpeed == 1.5 ? const Icon(Icons.check) : null,
                                onTap: () {
                                  print("1.5x speed selected");
                                  setState(() {
                                    selectedSpeed = 1.5;
                                  });
                                  _vlcPlayerController.setPlaybackSpeed(1.5);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text('1.75x'),
                                trailing: selectedSpeed == 1.75 ? const Icon(Icons.check) : null,
                                onTap: () {
                                  print("1.75x speed selected");
                                  setState(() {
                                    selectedSpeed = 1.75;
                                  });
                                  _vlcPlayerController.setPlaybackSpeed(1.75);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text('2.0x'),
                                trailing: selectedSpeed == 2.0 ? const Icon(Icons.check) : null,
                                onTap: () {
                                  print("2.0x speed selected");
                                  setState(() {
                                    selectedSpeed = 2.0;
                                  });
                                  _vlcPlayerController.setPlaybackSpeed(2.0);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Toggle Mute
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _vlcPlayerController.setVolume(_isMuted ? 0 : _volume);
    });
  }

  // Toggle Fullscreen
  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final screenSize = MediaQuery.of(context).size;
          _aspectRatio = screenSize.width / screenSize.height;
          setState(() {});
        });
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        _aspectRatio = 16 / 9;
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
