import 'dart:io';

import 'package:flutter/material.dart';

/// Utility to help debug Firebase configuration issues
class FirebaseDebug {
  /// Get SHA-1 fingerprint from the Android keystore for Firebase Console registration
  static Future<String> getAndroidSHA1() async {
    try {
      // This runs keytool to get the SHA-1 fingerprint from the debug keystore
      final homeDir = Platform.environment['HOME'] ?? '';
      final keystorePath = '$homeDir/.android/debug.keystore';

      final result = await Process.run('keytool', [
        '-list',
        '-v',
        '-alias',
        'androiddebugkey',
        '-keystore',
        keystorePath,
        '-storepass',
        'android',
        '-keypass',
        'android',
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'SHA1: ([A-F0-9:]+)').firstMatch(output);
        if (match != null) {
          return match.group(1) ?? 'Unable to parse SHA-1';
        }
      }
      return 'Unable to get SHA-1: ${result.stderr}';
    } catch (e) {
      return 'Error getting SHA-1: $e';
    }
  }

  /// Display Firebase setup instructions dialog
  static void showSetupInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Firebase Google Sign-In Setup'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To enable Google Sign-In on Android, follow these steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('1. Get your SHA-1 fingerprint:'),
              const SizedBox(height: 4),
              Text(
                'keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  backgroundColor: Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '2. Copy the SHA1 value (format: XX:XX:XX:XX...)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '3. Go to Firebase Console → Project Settings → Your App (Android)',
              ),
              const SizedBox(height: 12),
              const Text(
                '4. Add a Fingerprint section and paste your SHA-1 fingerprint',
              ),
              const SizedBox(height: 12),
              const Text(
                '5. Download the updated google-services.json and replace the one in android/app/',
              ),
              const SizedBox(height: 12),
              const Text('6. Run: flutter clean && flutter pub get'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
