import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vr Cinema'),
        backgroundColor: Colors.green,
      ),
      body: const Center(child: Text("Setting Screen")),
    );
  }
}
