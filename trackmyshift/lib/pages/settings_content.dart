import 'package:flutter/material.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Theme toggle is available in the app bar.'),
          SizedBox(height: 16),
          Text('More settings will be added here.'),
        ],
      ),
    );
  }
}
