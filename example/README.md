# Flutter Updater Manager Example

Example app demonstrating `flutter_updater_manager` usage.

## Features

- ✅ Check native update (APK via GitHub Releases)
- ✅ Check code push (Shorebird)
- ✅ Custom dialog with changelog
- ✅ Progress tracking
- ✅ Status display
- ✅ Pending update handling

## Setup

1. Update `home_screen.dart` with your GitHub and Shorebird credentials:

```dart
config: UpdateConfig(
  githubOwner: 'YOUR_GITHUB_USERNAME',
  githubRepository: 'YOUR_REPO_NAME',
  apkPattern: 'release',
  shorebirdAppId: 'YOUR_SHOREBIRD_APP_ID',
),

```
2. Run the example:
```bash
flutter run
```

