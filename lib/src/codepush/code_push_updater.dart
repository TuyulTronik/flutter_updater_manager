import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:terminate_restart/terminate_restart.dart';

import '../models/update_config.dart';
import '../utils/logger.dart';

/// Wrapper untuk Shorebird Code Push
///
/// Berdasarkan dokumentasi Shorebird API:
/// - `isAvailable`: Cek apakah Shorebird tersedia
/// - `checkForUpdate()`: Cek status update (upToDate/outdated/restartRequired/unavailable)
/// - `update()`: Download patch
/// - `readCurrentPatch()`: Dapatkan info patch saat ini
/// - `readNextPatch()`: Dapatkan info patch terbaru yang sudah didownload
///
/// ## Contoh Penggunaan
/// ```dart
/// final updater = CodePushUpdater(config: config);
///
/// // Cek update
/// final status = await updater.checkForUpdate();
/// if (status == UpdateStatus.outdated) {
///   // Download update
///   await updater.downloadUpdate();
///   // Restart app
///   await updater.restartApp();
/// }
/// ```
class CodePushUpdater {
  CodePushUpdater({
    required UpdateConfig config,
    this.isAutoUpdateEnabled = true,
  }) : _shorebird = ShorebirdUpdater();

  final ShorebirdUpdater _shorebird;

  /// Apakah auto_update diaktifkan di shorebird.yaml
  final bool isAutoUpdateEnabled;

  // ============================================================
  // PUBLIC GETTERS
  // ============================================================

  /// ✅ Cek apakah Shorebird tersedia di platform ini
  bool get isAvailable => _shorebird.isAvailable;

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  /// ✅ Cek status update saat ini
  ///
  /// Returns:
  /// - `UpdateStatus.upToDate` → Tidak ada update
  /// - `UpdateStatus.outdated` → Ada update tersedia
  /// - `UpdateStatus.restartRequired` → Update sudah didownload, perlu restart
  /// - `UpdateStatus.unavailable` → Shorebird tidak tersedia
  ///
  /// **Warning:** Method ini melakukan network call yang mungkin lama.
  /// Gunakan `.then()` agar tidak blocking startup:
  /// ```dart
  /// updater.checkForUpdate().then((status) {
  ///   // handle status
  /// });
  /// ```
  Future<UpdateStatus> checkForUpdate() async {
    try {
      if (!isAvailable) {
        UpdateLogger.warning('⚠️ Shorebird is not available');
        return UpdateStatus.unavailable;
      }
      return await _shorebird.checkForUpdate();
    } catch (e) {
      UpdateLogger.warning('❌ Error checking for update: $e');
      return UpdateStatus.unavailable;
    }
  }

  /// ✅ Cek apakah ada update tersedia (convenience method)
  ///
  /// Returns:
  /// - `true` jika ada update (outdated atau restartRequired)
  /// - `false` jika tidak ada update atau terjadi error
  Future<bool> check() async {
    final status = await checkForUpdate();
    return status == UpdateStatus.outdated ||
        status == UpdateStatus.restartRequired;
  }

  // ============================================================
  // DOWNLOAD UPDATE
  // ============================================================

  /// ✅ Download patch (jika tersedia)
  ///
  /// **Warning:** Method ini melakukan network call untuk download update
  /// yang mungkin memakan waktu lama.
  ///
  /// Returns:
  /// - `true` jika download berhasil
  /// - `false` jika tidak ada update atau gagal
  ///
  /// Throws:
  /// - `UpdateException` jika update gagal dengan alasan tertentu
  Future<bool> downloadUpdate() async {
    try {
      if (!isAvailable) {
        UpdateLogger.warning('⚠️ Shorebird is not available');

        return false;
      }

      // Cek status update
      final status = await _shorebird.checkForUpdate();

      switch (status) {
        case UpdateStatus.upToDate:
          UpdateLogger.warning('ℹ️ No update available');

          return false;

        case UpdateStatus.outdated:
          // ✅ Ada update, download
          await _shorebird.update();
          UpdateLogger.warning('✅ Patch downloaded successfully');
          return true;

        case UpdateStatus.restartRequired:
          // ✅ Update sudah didownload, tinggal restart
          UpdateLogger.warning(
            'ℹ️ Update already downloaded, restart required',
          );
          return true;

        case UpdateStatus.unavailable:
          UpdateLogger.warning('⚠️ Update status unavailable');
          return false;
      }
    } catch (e) {
      UpdateLogger.warning('❌ Error downloading patch: $e');
      return false;
    }
  }

  // ============================================================
  // UPDATE METHODS (Full Flow)
  // ============================================================

  /// ✅ Download update dan restart app
  ///
  /// Full flow untuk manual update:
  /// 1. Cek status update
  /// 2. Download patch (jika outdated)
  /// 3. Restart app (cold restart)
  ///
  /// Shorebird membutuhkan cold restart agar patch terlihat.
  Future<bool> applyAndRestart() async {
    try {
      // 1. Download patch
      final downloaded = await downloadUpdate();

      if (!downloaded) {
        UpdateLogger.warning('ℹ️ No patch to apply');
        return false;
      }

      // 2. ✅ Cold restart menggunakan terminate_restart
      UpdateLogger.warning('🔄 Restarting app to apply patch...');

      await TerminateRestart.instance.restartApp(
        options: const TerminateRestartOptions(
          terminate: true, // Full process restart!
          clearData: false,
        ),
      );

      return true;
    } catch (e) {
      UpdateLogger.warning('❌ Error applying patch: $e');
      return false;
    }
  }

  /// ✅ Cek apakah perlu restart (patch sudah didownload)
  Future<bool> needsRestart() async {
    final status = await checkForUpdate();
    return status == UpdateStatus.restartRequired;
  }

  // ============================================================
  // PATCH TRACKING
  // ============================================================

  /// ✅ Dapatkan informasi patch saat ini
  ///
  /// Returns:
  /// - `Patch` jika ada patch terinstall
  /// - `null` jika tidak ada patch atau updater tidak tersedia
  ///
  /// Throws:
  /// - `ReadPatchException` jika read gagal
  Future<Patch?> readCurrentPatch() async {
    try {
      if (!isAvailable) return null;
      return await _shorebird.readCurrentPatch();
    } catch (e) {
      UpdateLogger.warning('❌ Error reading current patch: $e');
      return null;
    }
  }

  /// ✅ Dapatkan nomor patch saat ini (convenience method)
  ///
  /// Returns: patch number (int), atau null jika tidak ada patch
  Future<int?> getCurrentPatchNumber() async {
    final patch = await readCurrentPatch();
    return patch?.number;
  }

  /// ✅ Dapatkan informasi patch terbaru yang sudah didownload
  ///
  /// Returns patch yang sama dengan readCurrentPatch jika belum ada patch baru.
  /// Returns `null` jika updater tidak tersedia.
  ///
  /// Throws:
  /// - `ReadPatchException` jika read gagal
  Future<Patch?> readNextPatch() async {
    try {
      if (!isAvailable) return null;
      return await _shorebird.readNextPatch();
    } catch (e) {
      UpdateLogger.warning('❌ Error reading next patch: $e');
      return null;
    }
  }

  // ============================================================
  // UTILITY
  // ============================================================

  /// ✅ Dapatkan shorebird instance (untuk advanced usage)
  ShorebirdUpdater get shorebird => _shorebird;
}
