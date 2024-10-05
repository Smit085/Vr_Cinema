import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class VrCinemaScreen extends StatefulWidget {
  final String videoPath;

  const VrCinemaScreen({super.key, required this.videoPath});

  @override
  _VrCinemaScreenState createState() => _VrCinemaScreenState();
}

class _VrCinemaScreenState extends State<VrCinemaScreen> {
  late UnityWidgetController _unityWidgetController;
  bool _isSceneInitialized = false;
  bool _isError = false;
  bool _unityWidgetVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_unityWidgetVisible)
            UnityWidget(
              fullscreen: true,
              unloadOnDispose: true,
              onUnityCreated: onUnityCreated,
              onUnityMessage: onUnityMessage,
            ),
          if (!_isSceneInitialized && !_isError)
            const Center(child: CircularProgressIndicator()),
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
    );
  }

  void onUnityCreated(controller) {
    _unityWidgetController = controller;
  }

  void onUnityMessage(message) {
    print('Received message from Unity: ${message.toString()}');
    if (message == "SceneInitialized") {
      setState(() {
        _isSceneInitialized = true;
        _isError = false;
      });
      // Once the scene is initialized, start playing the video
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
    if (_isSceneInitialized) {
      print('Sending video path to Unity: $videoPath');
      _unityWidgetController.postMessage("Screen", "PlayVideo", videoPath);
    } else {
      print("Scene not yet initialized, cannot play video.");
    }
  }

  void reloadUnityScene() {
    print("Reloading Unity scene...");
    _unityWidgetController.postMessage("Screen", "ReloadScene", "");
    setState(() {
      _isSceneInitialized = false;
      _isError = false;
      _unityWidgetVisible = true;
    });
  }
}