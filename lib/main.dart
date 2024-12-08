import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vr_cinema/screens/browse_screen.dart';
import 'package:vr_cinema/screens/setting_screen.dart';
import 'package:vr_cinema/screens/video_list_screen.dart';
import 'package:vr_cinema/utils/AppColors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestManageStoragePermission();
  await AppColors.loadPrimaryColor();
  runApp(const MyApp());
}

Future<void> requestManageStoragePermission() async {
  if (!await Permission.manageExternalStorage.isGranted) {
    await Permission.manageExternalStorage.request();
  }
}

class MyApp extends StatelessWidget {
  static final ValueNotifier<Color> themeColorNotifier =
      ValueNotifier<Color>(AppColors.primaryColor);
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({super.key});

  static void updateThemeColor(Color newColor) {
    themeColorNotifier.value = newColor;
    AppColors.savePrimaryColor(newColor);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
        valueListenable: themeColorNotifier,
        builder: (context, themeColor, child) {
          return MaterialApp(
            key: ValueKey(themeColor),
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              popupMenuTheme: PopupMenuThemeData(color: AppColors.primaryColor),
              scaffoldBackgroundColor: AppColors.primaryColor.withOpacity(0.15),
              appBarTheme: AppBarTheme(
                color: AppColors.primaryColor,
              ),
              dropdownMenuTheme: DropdownMenuThemeData(
                  menuStyle: MenuStyle(
                      backgroundColor:
                          WidgetStateProperty.all(AppColors.primaryColor))),
              checkboxTheme: CheckboxThemeData(
                fillColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return AppColors.primaryColor;

                  }
                  return Colors.transparent;
                }),
                checkColor: WidgetStateProperty.all(Colors.white),
                overlayColor:
                    WidgetStateProperty.all(Colors.blueAccent.withOpacity(0.5)),
                side: const BorderSide(color: Colors.black45, width: 2),
              ),
            ),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.system,
            home: const SplashScreen(), // Start with SplashScreen
          );
        });
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), _navigateToHome); // 3-second delay
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/logo_with_text.png',
          width: 350,
          height: 350,
        ),
      ),
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
    const VideoListScreen(),
    const BrowseScreen(),
    const SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        splashColor: AppColors.primaryColor.withOpacity(0.2),
        highlightColor: Colors.transparent,
        radius: 30.0,
        child: Container(
          color: AppColors.primaryColor.withOpacity(0.25),
          height: 55,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24.0,
                color: _selectedIndex == index
                    ? AppColors.primaryColor
                    : Colors.grey,
              ),
              Text(
                text,
                style: TextStyle(
                  color: _selectedIndex == index
                      ? AppColors.primaryColor
                      : Colors.grey,
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
