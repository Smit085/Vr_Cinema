import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vr_cinema/screens/browse_screen.dart';
import 'package:vr_cinema/screens/setting_screen.dart';
import 'package:vr_cinema/screens/video_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestManageStoragePermission();
  runApp(const MyApp());
}

Future<void> requestManageStoragePermission() async {
  if (!await Permission.manageExternalStorage.isGranted) {
    await Permission.manageExternalStorage.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(), // Light theme
      darkTheme: ThemeData.dark(), // Dark theme
      themeMode: ThemeMode.system, // Use system theme mode
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    VideoListScreen(),
    const BrowseScreen(),
    const SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(icon: Icons.movie, text: 'Video', index: 0),
          _buildNavItem(icon: Icons.folder, text: 'Browse', index: 1),
          _buildNavItem(icon: Icons.settings, text: 'Settings', index: 2),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String text,
    required int index,
  }) {
    return Expanded(
      child: InkResponse(
        onTap: () => _onItemTapped(index),
        splashColor: Colors.blue.withOpacity(0.3),
        highlightColor: Colors.transparent,
        radius: 30.0, // Control ripple size
        child: Container(
          height: 55,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24.0,
                color: _selectedIndex == index ? Colors.blue : Colors.grey,
              ),
              Text(
                text,
                style: TextStyle(
                  color: _selectedIndex == index ? Colors.blue : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
