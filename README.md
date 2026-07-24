# flutter_updater_manager

[![pub package](https://img.shields.io/pub/v/flutter_updater_manager.svg)](https://pub.dev/packages/flutter_updater_manager)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Flutter plugin untuk mengelola update aplikasi secara terpadu**, menggabungkan **Native Update (APK)** via GitHub Releases dan **Code Push** via Shorebird, dengan dukungan **changelog** dari GitHub Tags.

---

## 📋 Daftar Isi

- [Fitur](#-fitur)
- [Instalasi](#-instalasi)
- [Konfigurasi](#-konfigurasi)
- [Penggunaan Dasar](#-penggunaan-dasar)
- [Contoh Lengkap](#-contoh-lengkap)
- [API Reference](#-api-reference)
- [Custom Dialog](#-custom-dialog)
- [Roadmap](#-roadmap)
- [Lisensi](#-lisensi)

---

## ✨ Fitur

| Fitur | Deskripsi |
|-------|-----------|
| **Native Update** | Update APK via GitHub Releases (Android) |
| **Code Push** | Update patch via Shorebird (Android & iOS) |
| **Changelog** | Tampilkan daftar perubahan dari GitHub Releases & Tags |
| **Prioritas Update** | Native > Code Push (native lebih prioritas) |
| **Pending Install** | Simpan update yang ditunda user |
| **Custom Dialog** | Bisa custom UI dialog sesuai tema aplikasi |
| **Progress Stream** | Real-time progress untuk UI |
| **Status Tracking** | UpdateManagerStatus (idle, checking, downloading, dll.) |

---

## 📦 Instalasi

Tambahkan dependency ke `pubspec.yaml`:

```yaml
dependencies:
  flutter_updater_manager:
    git:
      url: https://github.com/TuyulTronik/flutter_updater_manager.git
      ref: main
```
Atau jika menggunakan path lokal:

```yaml
dependencies:
  flutter_updater_manager:
    path: ../flutter_updater_manager
```

Kemudian jalankan:
```bash
flutter pub get
```
---

## ⚙️ Konfigurasi

1. Shorebird Setup
Plugin ini membutuhkan Shorebird untuk Code Push. Ikuti langkah-langkah berikut:
```bash
# 1. Install shorebird_cli
dart pub global activate shorebird_cli

# 2. Init Shorebird di project
shorebird init

# 3. Buat file shorebird.yaml (auto-generated)
# auto_update: false  # Untuk manual mode
```
2. GitHub Release Setup
   - Buat Release di repository GitHub Anda
   - Upload file APK sebagai asset
   - Pastikan tag version mengikuti SemVer (contoh: v1.0.1)

3. Patch Changelog Setup
Untuk menampilkan changelog pada patch, buat Git Tag untuk setiap patch:
```bash
git tag v1.0.1-patch1
git push origin v1.0.1-patch1

# Buat release notes di GitHub (cukup tag, tidak perlu upload APK)
```
> **Catatan**: Tag patch harus memiliki format **{version}-patch{patchNumber}** (contoh: v1.0.1-patch1)

---

## 🚀 Penggunaan Dasar

### Inisialisasi

```dart
import 'package:flutter_updater_manager/flutter_updater_manager.dart';

final manager = UpdateManager(
  config: UpdateConfig(
    githubOwner: 'TuyulTronik',
    githubRepository: 'my_app',
    apkPattern: 'app-release',
    shorebirdAppId: 'your_app_id',
    autoDeleteAfterInstall: false,
    closeAppAfterInstall: true,
  ),
);
```

### Check & Update
```dart
// 1. Check update
final result = await manager.checkUpdates();

if (result.hasUpdate) {
  // 2. Tampilkan dialog (default)
  final shouldUpdate = await manager.showUpdateDialog(
    context,
    result,
  );

  if (shouldUpdate) {
    // 3. Jalankan update
    await manager.runUpdate(result: result);
  }
}
```

### Subscribe Progress
```dart
manager.progressStream.listen((progress) {
  print('Progress: ${progress.progress}');
  print('Message: ${progress.message}');
});

// Atau dengan callback
final manager = UpdateManager(
  config: config,
  onProgress: (progress) {
    // Update UI
  },
  onStatusChange: (status) {
    // Update status
  },
);
```
---

## 💡 Contoh Lengkap

### Dengan Stream & State Management

```dart
import 'package:flutter/material.dart';
import 'package:flutter_updater_manager/flutter_updater_manager.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final UpdateManager _manager;
  UpdateResult? _lastResult;
  UpdateProgress? _currentProgress;

  @override
  void initState() {
    super.initState();
    
    _manager = UpdateManager(
      config: UpdateConfig(
        githubOwner: 'TuyulTronik',
        githubRepository: 'my_app',
        apkPattern: 'app-release',
        shorebirdAppId: 'your_app_id',
      ),
      onProgress: (progress) {
        setState(() {
          _currentProgress = progress;
        });
      },
      onStatusChange: (status) {
        print('Status: $status');
      },
    );

    // Subscribe progress stream
    _manager.progressStream.listen((progress) {
      print('Progress: ${progress.progress}');
    });
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  Future<void> _checkUpdate() async {
    final result = await _manager.checkUpdates();
    setState(() {
      _lastResult = result;
    });

    if (result.hasUpdate) {
      final shouldUpdate = await _manager.showUpdateDialog(
        context,
        result,
      );

      if (shouldUpdate) {
        await _manager.runUpdate(result: result);
      }
    }
  }

  Future<void> _checkPendingPatch() async {
    final pending = await _manager.getPendingPatch();
    if (pending != null) {
      // Ada patch pending, apply restart
      await _manager.applyPendingPatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status
            if (_currentProgress != null) ...[
              Text('Progress: ${_currentProgress!.progress}'),
              Text('Message: ${_currentProgress!.message}'),
              SizedBox(height: 16),
            ],

            // Update Button
            ElevatedButton(
              onPressed: _checkUpdate,
              child: Text('Check Update'),
            ),

            SizedBox(height: 8),

            // Pending Patch Button
            ElevatedButton(
              onPressed: _checkPendingPatch,
              child: Text('Check Pending Patch'),
            ),
          ],
        ),
      ),
    );
  }
}
```
---

## 📖 API Reference

### UpdateManager
Class utama untuk mengelola update.

#### Constructor

```dart
UpdateManager({
  required UpdateConfig config,
  void Function(UpdateProgress progress)? onProgress,
  void Function(UpdateManagerStatus status)? onStatusChange,
  Widget Function(
    BuildContext context,
    Changelog changelog,
    UpdateType type,
    VoidCallback onUpdate,
    VoidCallback onCancel,
  )? dialogBuilder,
});
```
#### Methods
| Method | Return | Deskripsi |
|--------|--------|-----------|
| checkUpdates() | Future<UpdateResult> | Check native update + code push |
| runUpdate(UpdateResult) | Future<void> | Jalankan update sesuai priority |
| showUpdateDialog(BuildContext, UpdateResult) | Future<bool> | Tampilkan dialog update |
| applyPendingPatch() | Future<bool> | Apply pending patch & restart |
| getPendingNative() | Future<({String version, String apkPath})?> | Dapatkan pending native |
| getPendingPatch() | Future<({String version, String patchVersion, String tagName, String releaseNotes})?> | Dapatkan pending patch |
| getChangelog(UpdateResult) | Future<Changelog?> | Dapatkan changelog untuk update |
| getPendingPatchChangelog() | Future<Changelog?> | Dapatkan changelog untuk pending patch |
| cancel() | void |	Batalkan proses update |
| dispose() | void | Dispose resources |
#### Properties
| Property | Type | Deskripsi |
|--------|--------|-----------|
| status | UpdateManagerStatus | Status update saat ini |
| progressStream | Stream<UpdateProgress> | Stream progress update |

#### UpdateConfig
Konfigurasi untuk UpdateManager.

```dart
class UpdateConfig {
  const UpdateConfig({
    required this.githubOwner,
    required this.githubRepository,
    required this.apkPattern,
    this.githubToken,
    required this.shorebirdAppId,
    this.autoDeleteAfterInstall = false,
    this.closeAppAfterInstall = true,
  });

  final String githubOwner;           // Owner GitHub
  final String githubRepository;      // Repository GitHub
  final String apkPattern;            // Pattern APK (contoh: 'release')
  final String? githubToken;          // Token GitHub (opsional)
  final String shorebirdAppId;        // Shorebird App ID
  final bool autoDeleteAfterInstall;  // Hapus APK setelah install
  final bool closeAppAfterInstall;    // Close app setelah install
}
```
#### UpdateResult
Hasil pengecekan update.

```dart
class UpdateResult {
  final bool hasUpdate;
  final UpdateType type;            // native / codepush / none
  final UpdateInfo? nativeInfo;     // Info native update
  final PatchInfo? patchInfo;       // Info patch
  final Changelog? changelog;       // Changelog update
}
```
#### UpdateProgress
Progress update untuk UI.

```dart
class UpdateProgress {
  final UpdateType type;       // native / codepush
  final double progress;       // 0.0 - 1.0
  final String message;        // Status message
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;
}
```
#### UpdateManagerStatus
Status update yang sedang berjalan.

```dart
enum UpdateManagerStatus {
  idle,        // Tidak ada proses update
  checking,    // Sedang mengecek update
  downloading, // Sedang mendownload (native)
  installing,  // Sedang menginstal (native)
  patching,    // Sedang mem-patch (code push)
  patchReady,  // Patch siap, menunggu restart
  restarting,  // Sedang merestart app
  complete,    // Update selesai
  error,       // Terjadi error
}
```
---

## 🎨 Custom Dialog

Anda bisa mengganti default dialog dengan custom dialog sesuai tema aplikasi.

### Cara 1: Menggunakan dialogBuilder
```dart
final manager = UpdateManager(
  config: config,
  dialogBuilder: (context, changelog, type, onUpdate, onCancel) {
    return CustomChangelogDialog(
      changelog: changelog,
      type: type,
      onUpdate: onUpdate,
      onCancel: onCancel,
    );
  },
);
```

### Cara 2: Menggunakan UpdateDialogManager
```dart
final shouldUpdate = await UpdateDialogManager.showUpdateDialog(
  context: context,
  manager: manager,
  result: result,
  dialogBuilder: (context, changelog, type, onUpdate, onCancel) {
    return CustomChangelogDialog(...);
  },
);
```
### Cara 3: Custom Total dengan Helpers
```dart
import 'package:flutter_updater_manager/flutter_updater_manager.dart';

class CustomChangelogDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final icon = ChangelogHelpers.getIcon(updateType);
    final title = ChangelogHelpers.getTitle(updateType);
    final primaryText = ChangelogHelpers.getPrimaryButtonText(updateType);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: ChangelogHelpers.getIconColor(updateType)),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        children: changelog.changes.map(
          (change) => Text('• $change'),
        ).toList(),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(ChangelogHelpers.getSecondaryButtonText()),
        ),
        ElevatedButton(
          onPressed: onUpdate,
          child: Text(primaryText),
        ),
      ],
    );
  }
}
```
---

## 📄 Lisensi

Copyright © 2024 TuyulTronik
Dilisensikan di bawah MIT License.

---
