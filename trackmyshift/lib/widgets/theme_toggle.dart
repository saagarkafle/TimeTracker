import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return IconButton(
      tooltip: isDark ? 'Switch to light' : 'Switch to dark',
      icon: Icon(isDark ? Icons.nights_stay : Icons.wb_sunny),
      onPressed: () => context.read<ThemeProvider>().setDark(!isDark),
    );
  }
}
