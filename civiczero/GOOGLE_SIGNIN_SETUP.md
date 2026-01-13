# Google Sign-In Setup Fix

## The Issue
Google Sign-In is failing because the SHA-1 certificate fingerprint is not configured in Firebase Console.

## Solution Steps

### Step 1: Get Your SHA-1 Fingerprint

**For Debug Build (Development):**

Open a terminal in your project root and run:

```bash
cd android
./gradlew signingReport
```

Or on Windows:
```bash
cd android
gradlew.bat signingReport
```

Look for the output under `Variant: debug` and copy both:
- **SHA-1**: (something like `AA:BB:CC:DD:...`)
- **SHA-256**: (longer hash)

**Example output:**
```
Variant: debug
Config: debug
Store: /Users/username/.android/debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: DA:39:A3:EE:5E:6B:4B:0D:32:55:BF:EF:95:60:18:90:AF:D8:07:09
SHA-256: E3:B0:C4:42:98:FC:1C:14:9A:FB:F4:C8:99:6F:B9:24:27:AE:41:E4:64:9B:93:4C:A4:95:99:1B:78:52:B8:55
Valid until: ...
```

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **civiczero-c5bb8**
3. Click on Project Settings (gear icon)
4. Scroll down to "Your apps" section
5. Find your Android app: **com.d9tingontheyard.CivicZeroApp**
6. Click "Add fingerprint"
7. Paste your **SHA-1** fingerprint
8. Click "Add fingerprint" again and paste your **SHA-256** fingerprint
9. Click "Save"

### Step 3: Download Updated google-services.json

After adding the SHA-1:
1. In Firebase Console, click the download button next to your Android app
2. Download the new `google-services.json` file
3. Replace the file at: `android/app/google-services.json`

### Step 4: Verify Google Sign-In is Enabled

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Make sure **Google** is **Enabled**
3. Verify the Web SDK configuration section shows your OAuth client ID

### Step 5: Clean and Rebuild

```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run
```

## For Release Build (Production)

When you're ready to release:
1. Create a release keystore
2. Get the SHA-1 from your release keystore
3. Add that SHA-1 to Firebase Console as well
4. Download new google-services.json
5. Rebuild in release mode

## iOS Configuration (If needed)

Your iOS app also needs the REVERSED_CLIENT_ID in Info.plist:

1. Open `ios/Runner/Info.plist`
2. Add this before the closing `</dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.48233867824-b9ftthjpgd3ite55hls49e82nu6j3crj</string>
        </array>
    </dict>
</array>
```

## Troubleshooting

If Google Sign-In still doesn't work:

1. **Check logs for specific error messages**
2. **Verify package name matches**: `com.d9tingontheyard.CivicZeroApp`
3. **Make sure you downloaded the updated google-services.json** after adding SHA-1
4. **Try `flutter clean` and rebuild**
5. **Check Firebase Console** that Google Sign-In is enabled
6. **Verify your Google Cloud Console** OAuth consent screen is configured

## Common Errors

- **"API_KEY_INVALID"**: SHA-1 not added to Firebase
- **"DEVELOPER_ERROR"**: Wrong SHA-1 or missing configuration
- **Sign-in screen closes immediately**: SHA-1 mismatch
- **"Error 10"**: Google Play Services issue on emulator/device

## Testing

After setup, test with:
1. Real Android device (recommended)
2. Android emulator with Google Play Services
3. iOS simulator or device

**Note**: Google Sign-In requires Google Play Services on Android devices/emulators.
