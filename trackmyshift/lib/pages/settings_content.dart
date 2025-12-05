import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Theme toggle is available in the app bar.'),
          const SizedBox(height: 24),
          const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (user != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Signed in as',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? user.uid,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final scaffold = ScaffoldMessenger.of(context);
                  await auth.signOut();
                  if (!mounted) return;
                  scaffold.showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Track My Shift v1.0', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
            'Manage your shifts and earnings efficiently',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
