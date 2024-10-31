import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class VrCinemaScreen extends StatefulWidget {
  final String videoPath;
  final String initialScene;

  const VrCinemaScreen(
      {super.key, required this.videoPath, required this.initialScene});

  @override
  _VrCinemaScreenState createState() => _VrCinemaScreenState();
}

class _VrCinemaScreenState extends State<VrCinemaScreen> {
  UnityWidgetController? _unityWidgetController;
  bool isScreenReady = false;

  @override
  void initState() {
    super.initState();
  }

  // Function to load the scene based on user choice
  void _loadScene(String sceneName, String videoPath) {
    if (_unityWidgetController != null) {
      setState(() {
        isScreenReady = false;
      });
      String message = "$sceneName|$videoPath";
      _unityWidgetController?.postMessage(
          'Canvas', 'LoadUserSceneAndVideo', message);
    } else {
      print('Unity controller is not available.');
    }
  }

  void _playVideo() {
    if (_unityWidgetController != null && isScreenReady) {
      _unityWidgetController!
          .postMessage('Screen', 'SetVideoPath', widget.videoPath);
    } else {
      print('Unity controller or screen is not ready yet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          await _destroyUnityWidget();
          return true;
        },
        child: Scaffold(
          body: Stack(
            children: [
              UnityWidget(
                onUnityCreated: (controller) {
                  _unityWidgetController = controller;
                },
                onUnityMessage: (message) {
                  print("Received message from Unity: $message");
                  if (message == "SceneReady") {
                    _loadScene(widget.initialScene, widget.videoPath);
                  }
                  if (message == "ScreenReady") {
                    setState(() {
                      isScreenReady = true;
                    });
                    _playVideo();
                  }
                },
                onUnitySceneLoaded: (sceneName) {
                  print('Loaded scene: $sceneName');
                },
                onUnityUnloaded: () {
                  print('Unity unloaded');
                  setState(() {
                    isScreenReady = false;
                  });
                },
                unloadOnDispose: true,
                fullscreen: true,
              ),
            ],
          ),
        ));
  }

  Future<void> _destroyUnityWidget() async {
    if (_unityWidgetController != null) {
      await _unityWidgetController!.unload();
      _unityWidgetController = null;
    }
  }

  @override
  void dispose() {
    _destroyUnityWidget();
    super.dispose();
  }
}