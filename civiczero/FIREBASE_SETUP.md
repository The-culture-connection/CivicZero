# Firebase Setup Instructions

## Important: Download Actual Configuration Files

The `google-services.json` and `GoogleService-Info.plist` files in this project are templates. You MUST replace them with the actual files from Firebase Console.

### Steps to Get Firebase Configuration Files:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **civiczero-c5bb8**
3. Click on Project Settings (gear icon)

#### For Android:
4. In the "Your apps" section, click "Add app" and select Android
5. Enter package name: `com.d9tingontheyard.CivicZeroApp`
6. Download the `google-services.json` file
7. Replace the file at: `android/app/google-services.json`

#### For iOS:
8. In the "Your apps" section, click "Add app" and select iOS
9. Enter bundle ID: `com.d9tingontheyard.CivicZeroApp`
10. Download the `GoogleService-Info.plist` file
11. Replace the file at: `ios/Runner/GoogleService-Info.plist`

## Enable Authentication Methods

In Firebase Console:
1. Go to Authentication → Sign-in method
2. Enable the following providers:
   - **Email/Password**: Enable both email/password and email link (passwordless)
   - **Google**: Enable and configure
   - **Apple**: Enable and configure (you'll need an Apple Developer account)

## Additional Configuration for Google Sign-In

### Android:
The SHA-1 certificate fingerprint needs to be added to Firebase:
```bash
cd android
./gradlew signingReport
```
Copy the SHA-1 and SHA-256 from the debug variant and add them to Firebase Console.

### iOS:
1. In Firebase Console, under your iOS app, find the `REVERSED_CLIENT_ID`
2. Add it to your `Info.plist` URL Schemes

## After Setup:
Run `flutter pub get` to install all Firebase dependencies.
