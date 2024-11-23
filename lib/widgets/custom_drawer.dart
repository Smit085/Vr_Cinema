import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.speed),
            title: Text('Playback Speed'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Perform actions for playback speed
            },
          ),
          ListTile(
            leading: Icon(Icons.subtitles),
            title: Text('Subtitles'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Perform actions for subtitles
            },
          ),
        ],
      ),
    );
  }
}
