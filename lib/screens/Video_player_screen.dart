import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
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
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _animationController;
  late VlcPlayerController _vlcPlayerController;

  // Future<void> initializePlayer() async {}
  final Duration seekDuration = const Duration(seconds: 10);
  late Timer _timer;
  late Timer _controlsTimer;
  Timer? _volumeTimer;
  Timer? _brightnessTimer;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isFullscreen = false;
  // final bool _subtitlesEnabled = true;
  bool _controlsVisible = true;
  double _volume = 0.5;
  int _currentIndex = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _aspectRatio = 16 / 9;
  double selectedSpeed = 1.0;
  double _brightness = 0.5;
  late String currentVideoPath;
  bool _showSeekFeedback = false;
  bool _isSeekingForward = false;
  bool _showVolumeFeedback = false;
  bool _showBrightnessFeedback = false;

  @override
  void initState() {
    super.initState();

    getSystemBrightness();
    VolumeController().listener((volume) {
      setState(() {
        _volume = volume;
        _isMuted = _volume <= 0.05; // Use threshold for muting
      });
    });
    VolumeController().showSystemUI = false;

    _currentIndex = widget.initialIndex;
    currentVideoPath = widget.videoPaths[_currentIndex];
    if (Uri.parse(currentVideoPath).isAbsolute) {
      _vlcPlayerController = VlcPlayerController.network(currentVideoPath);
    } else {
      _vlcPlayerController = VlcPlayerController.file(File(currentVideoPath));
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      _vlcPlayerController.play();
      _vlcPlayerController.setVolume((_volume * 100).toInt());
      _isPlaying = true;
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
        if (_isPlaying && _isLoading) {
          _isLoading = false;
        }
      });
    });

    _startControlsTimer();
  }

  Future<void> getSystemBrightness() async {
    try {
      double brightness = await ScreenBrightness.instance.system;
      await ScreenBrightness.instance.setApplicationScreenBrightness(brightness);
    } catch (e) {
      // print('Failed to set system brightness: $e');
    }
  }

  Future<void> setApplicationBrightness(double brightness) async {
    try {
      await ScreenBrightness.instance
          .setApplicationScreenBrightness(brightness);
    } catch (e) {
      // debugPrint(e.toString());
      // throw 'Failed to set application brightness';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _volumeTimer?.cancel();
    _brightnessTimer?.cancel();
    _vlcPlayerController.stop();
    _vlcPlayerController.dispose();
    _timer.cancel();
    _controlsTimer.cancel();
    VolumeController().removeListener();
    ScreenBrightness.instance.resetScreenBrightness();
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

  void _seekForward() {
    final newPosition = _position + seekDuration;
    if (newPosition < _duration) {
      _vlcPlayerController.seekTo(newPosition);
    } else {
      _vlcPlayerController.seekTo(_duration);
    }
    _showSeekFeedbackAnimation(true);
  }

  void _seekBackward() {
    final newPosition = _position - seekDuration;
    if (newPosition > Duration.zero) {
      _vlcPlayerController.seekTo(newPosition);
    } else {
      _vlcPlayerController.seekTo(Duration.zero);
    }
    _showSeekFeedbackAnimation(false);
  }

  void _showSeekFeedbackAnimation(bool isForward) {
    setState(() {
      _isSeekingForward = isForward;
      _showSeekFeedback = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _showSeekFeedback = false;
      });
    });
  }

  void _adjustVolume(double change) {
    setState(() {
      _volume = (_volume + change).clamp(0.0, 1.0);
      VolumeController().setVolume(_volume);
      _showVolumeFeedback = true;

      // Cancel the previous timer if it's running
      _volumeTimer?.cancel();
      // Set a new timer to hide the volume feedback after a delay
      _volumeTimer = Timer(Duration(seconds: 1), () {
        setState(() {
          _showVolumeFeedback = false;
        });
      });
    });
  }

  void _adjustBrightness(double change) {
    setState(() {
      _brightness = (_brightness + change).clamp(0.0, 1.0);
      ScreenBrightness.instance.setApplicationScreenBrightness(_brightness);
      _showBrightnessFeedback = true;

      // Cancel the previous timer if it's running
      _brightnessTimer?.cancel();
      // Set a new timer to hide the brightness feedback after a delay
      _brightnessTimer = Timer(Duration(seconds: 1), () {
        setState(() {
          _showBrightnessFeedback = false;
        });
      });
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
      onDoubleTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final doubleTapPosition = details.globalPosition.dx;

        if (doubleTapPosition < screenWidth * 0.3) {
          // Left side double tap - Seek backward
          _seekBackward();
        } else if (doubleTapPosition > screenWidth * 0.7) {
          // Right side double tap - Seek forward
          _seekForward();
        } else {
          // Center double tap - Play/Pause
          _playPauseVideo();
        }
      },
      onVerticalDragUpdate: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < screenWidth * 0.5) {
          // Left side - adjust brightness
          _adjustBrightness(-details.primaryDelta! / 200);
        } else {
          // Right side - adjust volume
          _adjustVolume(-details.primaryDelta! / 200);
        }
      },
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
            if (_showVolumeFeedback)
              Positioned(
                left: MediaQuery.of(context).size.width * 0.1,
                top: MediaQuery.of(context).size.height * 0.2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_volume * 100).toInt()}%', // Volume percentage
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 1.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.grey,
                        thumbColor: Colors.white,
                      ),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (double value) {
                            setState(() {
                              _volume = value;
                              VolumeController().setVolume(_volume);
                              _isMuted = _volume == 0;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up, // Toggle icon based on mute state
                      color: Colors.white,
                      size: 24,
                    ),
                    const Text(
                      'Volume',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            if (_showBrightnessFeedback)
              Positioned(
                right: MediaQuery.of(context).size.width * 0.1,
                top: MediaQuery.of(context).size.height * 0.2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_brightness * 100).toInt()}%', // Brightness percentage
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 1.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.grey,
                        thumbColor: Colors.white,
                      ),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _brightness,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              _brightness = value;
                            });
                            setApplicationBrightness(value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.brightness_6, color: Colors.white, size: 24),
                    const Text(
                      'Brightness',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            if (_showSeekFeedback)
              Positioned(
                left: _isSeekingForward ? null : 40, // Left for rewind
                right: _isSeekingForward ? 40 : null, // Right for forward
                top: MediaQuery.of(context).size.height * 0.4,
                child: AnimatedOpacity(
                  opacity: _showSeekFeedback ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isSeekingForward
                        ? Icons.fast_forward_rounded
                        : Icons.fast_rewind_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.red,
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
                                    mainAxisSize: MainAxisSize
                                        .min, // Keep this row size to a minimum
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
                                _isFullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                color:
                                    _isFullscreen ? Colors.red : Colors.white,
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
        bool showingSpeedOptions =
            false; // Reset every time the modal is opened

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
                              builder: (context) => VrCinemaScreen(
                                videoPath: currentVideoPath,
                                initialScene: 'VR_Room',
                              ),
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
                              builder: (context) => VrCinemaScreen(
                                videoPath: currentVideoPath,
                                initialScene: 'VR_Livingroom',
                              ),
                            ),
                          );
                          print("Watch In VR Tapped");
                        },
                      ),
                    ] else ...[
                      SizedBox(
                        height:
                            300, // Set the desired height for the speed options
                        child: SingleChildScrollView(
                          // Allows scrolling if content exceeds height
                          child: Column(
                            children: [
                              ListTile(
                                title: const Text('0.25x'),
                                trailing: selectedSpeed == 0.25
                                    ? const Icon(Icons.check)
                                    : null,
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
                                trailing: selectedSpeed == 0.5
                                    ? const Icon(Icons.check)
                                    : null,
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
                                trailing: selectedSpeed == 0.75
                                    ? const Icon(Icons.check)
                                    : null,
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
                                trailing: selectedSpeed == 1.0
                                    ? const Icon(Icons.check)
                                    : null,
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
                                trailing: selectedSpeed == 1.25
                                    ? const Icon(Icons.check)
                                    : null,
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
                                trailing: selectedSpeed == 1.5
                                    ? const Icon(Icons.check)
                                    : null,
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
                                trailing: selectedSpeed == 1.75
                                    ? const Icon(Icons.check)
                                    : null,
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
                                trailing: selectedSpeed == 2.0
                                    ? const Icon(Icons.check)
                                    : null,
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
      if (_isMuted) {
        _volume = 0; // Set _volume to 0 to reflect muted state
      } else {
        _volume = 0.5; // Set default volume when unmuting if no saved value
      }
      // _vlcPlayerController.setVolume((_isMuted ? 0 : _volume * 100).toInt()); // Apply volume to controller
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
