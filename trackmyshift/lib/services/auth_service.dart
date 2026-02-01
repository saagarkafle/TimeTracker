import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // The serverClientId is the OAuth 2.0 Web client ID from Firebase Console
  // This is needed for proper token exchange between GoogleSignIn and Firebase
  static const String _serverClientId =
      '766525947356-n37upib9c1inafcfpmg31dtjtrhv3oqq.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _serverClientId,
  );

  User? user;

  AuthService() {
    _auth.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
    });
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred;
  }

  Future<UserCredential> createUserWithEmail(
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;

      if (auth.idToken == null) {
        throw Exception(
          'Unable to obtain ID token from Google Sign-In. '
          'Ensure your SHA-1 fingerprint is registered in Firebase Console.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      return userCred;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<void> deleteAccount() async {
    try {
      // Delete Firestore data first
      if (user != null) {
        // Delete user's shifts collection
        final db = FirebaseFirestore.instance;
        final shiftsQuery = await db
            .collection('users')
            .doc(user!.uid)
            .collection('shifts')
            .get();
        for (final doc in shiftsQuery.docs) {
          await doc.reference.delete();
        }

        // Delete user's metadata
        final metaQuery = await db
            .collection('users')
            .doc(user!.uid)
            .collection('meta')
            .get();
        for (final doc in metaQuery.docs) {
          await doc.reference.delete();
        }

        // Delete user document
        await db.collection('users').doc(user!.uid).delete();
      }

      // Delete Firebase Auth user
      await user?.delete();
    } catch (e) {
      rethrow;
    }
  }
}
