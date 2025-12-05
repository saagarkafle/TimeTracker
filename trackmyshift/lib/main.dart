import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/earnings_content.dart';
import 'pages/history_content.dart';
import 'pages/home_content.dart';
import 'pages/settings_content.dart';
import 'providers/shifts_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/notifications.dart';
import 'widgets/theme_toggle.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifications.init();
  runApp(const TrackMyShiftApp());
}

class TrackMyShiftApp extends StatelessWidget {
  const TrackMyShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ShiftsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Track My Shift',
            theme: theme.isDark ? ThemeData.dark() : ThemeData.light(),
            home: const MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<String> _titles = [
    'Home',
    'History',
    'Earnings',
    'Settings',
  ];

  static final List<Widget> _pages = [
    const HomeContent(),
    const HistoryContent(),
    const EarningsContent(),
    const SettingsContent(),
  ];

  void _onItemTapped(int idx) => setState(() => _selectedIndex = idx);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: const [ThemeToggle()],
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
