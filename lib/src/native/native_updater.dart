import 'package:flutter_apk_updater/flutter_apk_updater.dart';

import '../models/update_config.dart';

/// Wrapper untuk flutter_apk_updater
class NativeUpdater {
  NativeUpdater({
    required UpdateConfig config,
  }) : _updater = ApkUpdater(
          config: ApkUpdaterConfig(
            owner: config.githubOwner,
            repository: config.githubRepository,
            apkPattern: config.apkPattern,
            githubToken: config.githubToken,
            autoDeleteAfterInstall: config.autoDeleteAfterInstall,
            closeAppAfterInstall: config.closeAppAfterInstall,
          ),
          timeout: const Duration(seconds: 60),
        );

  final ApkUpdater _updater;

  /// Check native update
  Future<Result<UpdateInfo>> check() async {
    return _updater.check();
  }

  /// Download APK
  Future<Result<DownloadInfo>> download({
    required UpdateInfo updateInfo,
    DownloadProgressCallback? onProgress,
  }) async {
    return _updater.download(
      updateInfo: updateInfo,
      onProgress: onProgress,
    );
  }

  /// Install APK
  Future<Result<void>> install({
    required String apkPath,
  }) async {
    return _updater.install(apkPath: apkPath);
  }

  /// Cancel download
  void cancel() {
    _updater.cancelDownload();
  }

  /// Cek permission install
  Future<bool> canRequestPackageInstalls() async {
    return _updater.canRequestPackageInstalls();
  }

  /// Buka settings install
  Future<bool> openInstallSettings() async {
    return _updater.openInstallSettings();
  }

  /// Dapatkan updater instance (untuk advanced usage)
  ApkUpdater get updater => _updater;
}