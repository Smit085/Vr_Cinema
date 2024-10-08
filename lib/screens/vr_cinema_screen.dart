import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class VrCinemaScreen extends StatefulWidget {
  final String videoPath;

  const VrCinemaScreen({super.key, required this.videoPath});

  @override
  _VrCinemaScreenState createState() => _VrCinemaScreenState();
}

class _VrCinemaScreenState extends State<VrCinemaScreen> {
  UnityWidgetController? _unityWidgetController;
  bool _isSceneInitialized = false;
  bool _isError = false;
  bool _unityWidgetVisible = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _fakeProgress();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _unloadUnityScene();
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            if (!_isSceneInitialized && !_isError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Your VR environment is getting ready....',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16), // Add some space between the text and the progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5), // Corner radius
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500), // Animate the progress bar
                          height: 3,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            value: _progress,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Space between progress bar and text
                      const Text(
                        'Please be ready with the VR headset',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16), // Space before the percentage display
                      Text(
                        '${(_progress * 100).toInt()}%', // Show percentage progress
                        style: const TextStyle(fontSize: 16.0),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (_unityWidgetVisible)
              UnityWidget(
                fullscreen: true,
                unloadOnDispose: true,
                onUnityCreated: onUnityCreated,
                onUnityMessage: onUnityMessage,
              ),
            if (_isError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Failed to load the scene. Try again."),
                    ElevatedButton(
                      onPressed: reloadUnityScene,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _fakeProgress() async {
    // Fake loading animation for a smooth effect
    for (var i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        _progress = i / 100; // Update progress smoothly from 0 to 1
      });
    }
    setState(() {
      _unityWidgetVisible = true; // Show Unity widget after progress completes
    });
  }

  Future<void> _unloadUnityScene() async {
    if (_unityWidgetController != null) {
      print("Sending stop command to Unity...");
      await _unityWidgetController!.postMessage("Screen", "StopVideo", "");
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _unityWidgetVisible = false;
      });

      print("Unity widget removed from the tree.");
    }
  }

  @override
  void dispose() {
    _unloadUnityScene();
    super.dispose();
  }

  void onUnityCreated(UnityWidgetController controller) {
    _unityWidgetController = controller;
  }

  void onUnityMessage(dynamic message) {
    print('Received message from Unity: ${message.toString()}');
    if (message == "SceneInitialized") {
      setState(() {
        _isSceneInitialized = true;
        _isError = false;
      });
      Future.delayed(const Duration(seconds: 1), () {
        playVideo(widget.videoPath);
      });
    } else if (message == "SceneInitializationFailed") {
      setState(() {
        _isError = true;
        _isSceneInitialized = false;
      });
    }
  }

  void playVideo(String videoPath) {
    if (_isSceneInitialized && _unityWidgetController != null) {
      print('Sending video path to Unity: $videoPath');
      _unityWidgetController!.postMessage("Screen", "PlayVideo", videoPath);
    } else {
      print("Scene not yet initialized, cannot play video.");
    }
  }

  void reloadUnityScene() {
    print("Reloading Unity scene...");
    if (_unityWidgetController != null) {
      _unityWidgetController!.postMessage("Screen", "ReloadScene", "");
    }
    setState(() {
      _isSceneInitialized = false;
      _isError = false;
      _unityWidgetVisible = true;
    });
  }
}
