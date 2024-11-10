import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  Color _themeColor = Colors.blue;
  bool isListView = true;
  bool autoScanVideos = true;
  String dayNightMode = 'system';
  bool marqueeTitle = false;
  bool showThumbnails = true;
  bool savePlaybackSpeed = false;
  double playbackSpeed = 1.0;
  double volumeLevel = 0.5;
  bool saveVolumeLevel = false;
  bool alwaysEnableSubtitle = false;
  int subtitleDelay = 0;
  int audioDelay = 0;
  bool pauseOnMinimize = true;
  int playerControlHideDelay = 3;
  bool doubleTapPlayPause = true;
  bool doubleTapSeek = true;
  int seekAmount = 5;
  bool brightnessGesture = true;
  bool volumeGesture = true;
  String afterVideoFinish = 'exit';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String themeColorString = prefs.getString('themeColor') ?? 'blue';
      _themeColor = _getColorFromString(themeColorString);
      isListView = prefs.getBool('isListView') ?? true;
      autoScanVideos = prefs.getBool('autoScanVideos') ?? true;
      dayNightMode = prefs.getString('dayNightMode') ?? 'system';
      marqueeTitle = prefs.getBool('marqueeTitle') ?? false;
      showThumbnails = prefs.getBool('showThumbnails') ?? true;
      playbackSpeed = prefs.getDouble('playbackSpeed') ?? 1.0;
      savePlaybackSpeed = prefs.getBool('savePlaybackSpeed') ?? false;
      volumeLevel = prefs.getDouble('volumeLevel') ?? 0.5;
      saveVolumeLevel = prefs.getBool('saveVolumeLevel') ?? false;
      alwaysEnableSubtitle = prefs.getBool('alwaysEnableSubtitle') ?? false;
      subtitleDelay = prefs.getInt('subtitleDelay') ?? 0;
      audioDelay = prefs.getInt('audioDelay') ?? 0;
      pauseOnMinimize = prefs.getBool('pauseOnMinimize') ?? true;
      playerControlHideDelay = prefs.getInt('playerControlHideDelay') ?? 3;
      doubleTapPlayPause = prefs.getBool('doubleTapPlayPause') ?? true;
      doubleTapSeek = prefs.getBool('doubleTapSeek') ?? true;
      seekAmount = prefs.getInt('seekDelay') ?? 5;
      brightnessGesture = prefs.getBool('brightnessGesture') ?? true;
      volumeGesture = prefs.getBool('volumeGesture') ?? true;
      afterVideoFinish = prefs.getString('afterVideoFinish') ?? 'exit';
    });
  }

  Color _getColorFromString(String colorString) {
    switch (colorString) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _setThemeColor(Color color) async {
    setState(() {
      _themeColor = color;
    });
    _saveSetting('themeColor', color.value);
  }

  Future<void> _saveSetting<T>(String key, T value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VR Cinema Settings'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildSettingCategory(
              "Display Settings",
              [
                _buildColorSelector(),
                _buildDropdownTile(
                  title: "View Type",
                  value: isListView ? "List View" : "Grid View",
                  onChanged: (value) {
                    setState(() {
                      isListView = value == "List View";
                    });
                    _saveSetting('isListView', isListView);
                  },
                  icon: isListView ? Icons.grid_off : Icons.grid_on,
                  options: ['List View', 'Grid View'],
                ),
                _buildDropdownTile(
                  icon: Icons.brightness_4,
                  title: "Day/Night Mode",
                  value: dayNightMode,
                  options: ['system', 'light', 'dark'],
                  onChanged: (value) {
                    setState(() => dayNightMode = value);
                    _saveSetting('dayNightMode', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.photo,
                  title: "Show Thumbnails",
                  value: showThumbnails,
                  onChanged: (value) {
                    setState(() => showThumbnails = value!);
                    _saveSetting('showThumbnails', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.photo,
                  title: "Marquee Title",
                  value: marqueeTitle,
                  onChanged: (value) {
                    setState(() => marqueeTitle = value!);
                    _saveSetting('marqueeTitle', value);
                  },
                ),
              ],
            ),
            _buildSettingCategory(
              "Player Settings",
              [
                _buildCheckboxTile(
                  icon: Icons.speed,
                  title: "Save Playback Speed",
                  value: savePlaybackSpeed,
                  onChanged: (value) {
                    setState(() => savePlaybackSpeed = value!);
                    _saveSetting('savePlaybackSpeed', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.network_cell,
                  title: "Save Volume Level",
                  value: saveVolumeLevel,
                  onChanged: (value) {
                    setState(() => saveVolumeLevel = value!);
                    _saveSetting('saveVolumeLevel', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.subtitles,
                  title: "Always Enable Subtitles",
                  value: alwaysEnableSubtitle,
                  onChanged: (value) {
                    setState(() => alwaysEnableSubtitle = value!);
                    _saveSetting('alwaysEnableSubtitle', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.play_arrow,
                  title: "Double Tap to Play/Pause",
                  value: doubleTapPlayPause,
                  onChanged: (value) {
                    setState(() => doubleTapPlayPause = value!);
                    _saveSetting('doubleTapPlayPause', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.fast_forward,
                  title: "Double Tap to Seek",
                  value: doubleTapSeek,
                  onChanged: (value) {
                    setState(() => doubleTapSeek = value!);
                    _saveSetting('doubleTapSeek', value);
                  },
                ),
                _buildPlaybackSpeedSlider(
                  icon: Icons.speed,
                  title: "Playback Speed",
                  value: playbackSpeed,
                  values: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
                  onChanged: (value) {
                    setState(() => playbackSpeed = value);
                    _saveSetting('playbackSpeed', value);
                  },
                ),
                _buildSliderTile(
                  icon: Icons.volume_up,
                  title: "Volume Level",
                  value: volumeLevel,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (value) {
                    setState(() => volumeLevel = value);
                    _saveSetting('volumeLevel', value);
                  },
                ),
              ],
            ),
            _buildSettingCategory(
              "Control Settings",
              [
                _buildDelaySetting(
                  title: "Subtitle Delay (ms)",
                  delayValue: subtitleDelay,
                  onIncrease: () {
                    setState(() => subtitleDelay += 50);
                    _saveSetting('subtitleDelay', subtitleDelay);
                  },
                  onDecrease: () {
                    setState(() => subtitleDelay -= 50);
                    _saveSetting('subtitleDelay', subtitleDelay);
                  },
                  onReset: () {
                    setState(() => subtitleDelay = 0);
                    _saveSetting('subtitleDelay', 0);
                  },
                ),
                _buildDelaySetting(
                  title: "Audio Delay (ms)",
                  delayValue: audioDelay,
                  onIncrease: () {
                    setState(() => audioDelay += 50);
                    _saveSetting('audioDelay', audioDelay);
                  },
                  onDecrease: () {
                    setState(() => audioDelay -= 50);
                    _saveSetting('audioDelay', audioDelay);
                  },
                  onReset: () {
                    setState(() => audioDelay = 0);
                    _saveSetting('audioDelay', 0);
                  },
                ),
                _buildDelaySetting(
                  title: "Seek Amount (sec)",
                  delayValue: seekAmount,
                  onIncrease: () {
                    setState(() => seekAmount += 5);
                    _saveSetting('seekAmount', seekAmount);
                  },
                  onDecrease: () {
                    setState(() => seekAmount -= 5);
                    _saveSetting('seekAmount', seekAmount);
                  },
                  onReset: () {
                    setState(() => seekAmount = 0);
                    _saveSetting('seekAmount', 0);
                  },
                ),
                _buildSliderTile(
                  icon: Icons.timer,
                  title: "Player Control Hide Delay",
                  value: playerControlHideDelay.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() => playerControlHideDelay = value.toInt());
                    _saveSetting('playerControlHideDelay', value.toInt());
                  },
                ),
              ],
            ),
            _buildSettingCategory(
              "Advance Settings",
              [
                _buildDropdownTile(
                  icon: Icons.exit_to_app,
                  title: "After Video Finish",
                  value: afterVideoFinish,
                  options: ['exit', 'replay'],
                  onChanged: (value) {
                    setState(() => afterVideoFinish = value);
                    _saveSetting('afterVideoFinish', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.pause,
                  title: "Pause on Minimize",
                  value: pauseOnMinimize,
                  onChanged: (value) {
                    setState(() => pauseOnMinimize = value!);
                    _saveSetting('pauseOnMinimize', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.refresh,
                  title: "Auto Scan Videos",
                  value: autoScanVideos,
                  onChanged: (value) {
                    setState(() => autoScanVideos = value!);
                    _saveSetting('pauseOnMinimize', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.light_mode,
                  title: "Control Brightness By Gesture",
                  value: brightnessGesture,
                  onChanged: (value) {
                    setState(() => brightnessGesture = value!);
                    _saveSetting('pauseOnMinimize', value);
                  },
                ),
                _buildCheckboxTile(
                  icon: Icons.volume_up,
                  title: "Control Volume By Gesture",
                  value: volumeGesture,
                  onChanged: (value) {
                    setState(() => volumeGesture = value!);
                    _saveSetting('pauseOnMinimize', value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCategory(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: children,
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return CheckboxListTile(
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildPlaybackSpeedSlider({
    required IconData icon,
    required String title,
    required double value,
    required List<double> values,
    required Function(double) onChanged,
  }) {
    // Find the nearest index for the current speed value
    int currentIndex = values.indexWhere((speed) => speed == value);
    if (currentIndex == -1)
      currentIndex = 1; // Default to 1.0x if value not found

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 1.5,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          activeTrackColor: Colors.redAccent,
          inactiveTrackColor: Colors.grey,
          thumbColor: Colors.red,
          valueIndicatorColor: Colors.blue, // Background color of the label
          valueIndicatorTextStyle: const TextStyle(color: Colors.white),
        ),
        child: Slider(
          value: currentIndex.toDouble(),
          min: 0,
          max: (values.length - 1).toDouble(),
          divisions: values.length - 1,
          label: "${values[currentIndex]}x",
          onChanged: (double newIndex) {
            int index = newIndex.round();
            onChanged(values[index]); // Pass the selected speed value
          },
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required Function(double) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 1.5,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          activeTrackColor: Colors.redAccent,
          inactiveTrackColor: Colors.grey,
          thumbColor: Colors.red,
          valueIndicatorColor: Colors.blue, // Background color of the label
          valueIndicatorTextStyle: const TextStyle(color: Colors.white),
        ),
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.round()}',
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: (val) {
          if (val != null) {
            onChanged(val);
          }
        },
        items: options.map((opt) {
          return DropdownMenuItem<String>(
            value: opt,
            child: Text(opt.capitalize()),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDelaySetting({
    required String title,
    required int delayValue,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
    required VoidCallback onReset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: onDecrease,
              ),
              Text('$delayValue ms', style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onIncrease,
              ),
              TextButton(
                onPressed: onReset,
                child:
                    const Text("Reset", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple
    ];
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            const Text(
              "Select Theme Color",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () => _setThemeColor(color),
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: _themeColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null, // Show checkmark for selected color
                  ),
                );
              }).toList(),
            ),
          ],
        ));
  }
}

extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}
