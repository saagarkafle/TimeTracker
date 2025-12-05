import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/earnings_content.dart';
import 'pages/history_content.dart';
import 'pages/home_content.dart';
import 'pages/settings_content.dart';
import 'pages/signin_page.dart';
import 'providers/shifts_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';
import 'utils/notifications.dart';
import 'widgets/theme_toggle.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (required for any Firebase services)
  await Firebase.initializeApp();

  // Initialize local notification helper
  await Notifications.init();
  // Initialize push service (FCM)
  await PushService.init();
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
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Consumer2<ThemeProvider, AuthService>(
        builder: (context, theme, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Track My Shift',
            theme: theme.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: auth.user == null
                ? const SignInPage()
                : AuthConnector(child: const MyHomePage()),
          );
        },
      ),
    );
  }
}

/// Widget that connects auth state to providers that need the signed-in uid.
class AuthConnector extends StatefulWidget {
  final Widget child;
  const AuthConnector({required this.child, super.key});

  @override
  State<AuthConnector> createState() => _AuthConnectorState();
}

class _AuthConnectorState extends State<AuthConnector> {
  String? _lastUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthService>(context);
    final shifts = Provider.of<ShiftsProvider>(context, listen: false);
    final uid = auth.user?.uid;
    if (_lastUid != uid) {
      _lastUid = uid;
      shifts.attachUser(uid);
      // Upload FCM token to Firestore for push notifications
      if (uid != null) {
        PushService.uploadTokenForUser(uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
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

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isSelected
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Icon(
        icon,
        size: isSelected ? 24 : 22,
        color: isSelected ? Colors.white : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: const [ThemeToggle()],
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF1a1a2e),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF667eea),
          unselectedItemColor: Theme.of(context).brightness == Brightness.light
              ? Colors.grey.shade500
              : Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home, 0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.history, 1),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.payments, 2),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.settings, 3),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
