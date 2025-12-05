# Google Sign-In Setup Guide

If you're getting "DEVELOPER_ERROR" or "Sign-in failed" when trying to use Google Sign-In, follow these steps:

## Step 1: Get Your Debug SHA-1 Fingerprint

Run this command in your terminal:

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android | grep SHA1
```

You should see output like:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**Copy the SHA1 value (without "SHA1: " prefix)**

## Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Project Settings** (gear icon)
4. Click on the **Apps** tab
5. Find your Android app in the list
6. Under "SHA certificate fingerprints", click **Add fingerprint**
7. Paste your SHA-1 value (the XX:XX:XX... part)
8. Click **Save**

## Step 3: Download Updated google-services.json

1. Still in Firebase Console, next to your Android app, click the menu (⋮)
2. Click **Download google-services.json**
3. Replace the file at `android/app/google-services.json` with the downloaded file

## Step 4: Clean and Rebuild

```bash
cd /Users/sagarkafle/projects/flutter/timetable/trackmyshift
flutter clean
flutter pub get
flutter run
```

## Step 5: Test Google Sign-In

1. Tap on **Settings** tab in the app
2. Click **Sign in with Google**
3. Select your Google account
4. You should now be signed in!

---

## Common Issues

### "DEVELOPER_ERROR"
- SHA-1 fingerprint not registered in Firebase Console
- Using wrong keystore (check you're using debug.keystore in ~/.android/)

### "Unable to get GoogleSignIn configuration"
- google-services.json not properly placed at `android/app/google-services.json`
- Missing Google Services Gradle plugin (should be applied in android/app/build.gradle.kts)

### "ID token is null"
- Same as DEVELOPER_ERROR above - SHA-1 mismatch

---

## Release Build

When building for release, you'll need to:
1. Generate a signed APK/AAB with your release keystore
2. Extract the SHA-1 from your release keystore
3. Add that SHA-1 to Firebase Console as well
4. Download a new google-services.json that includes both debug and release SHA-1s
