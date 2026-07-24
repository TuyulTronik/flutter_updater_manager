// lib/src/core/update_manager.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apk_updater/flutter_apk_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../changelog/changelog_parser.dart';
import '../changelog/changelog_service.dart';
import '../codepush/code_push_updater.dart';
import '../models/changelog.dart';
import '../models/patch_info.dart';
import '../models/update_config.dart';
import '../models/update_progress.dart';
import '../core/update_result.dart';
import '../models/update_type.dart';
import '../native/native_updater.dart';
import '../storage/update_state_storage.dart';
import '../ui/update_dialog_manager.dart';
import '../utils/logger.dart';
import 'update_manager_status.dart';

/// Main class untuk mengelola update (native + code push)
///
/// ## Example
/// ```dart
/// final manager = UpdateManager(
///   config: UpdateConfig(
///     githubOwner: 'TuyulTronik',
///     githubRepository: 'tulkit',
///     apkPattern: 'release',
///     shorebirdAppId: 'your_app_id',
///   ),
/// );
///
/// // Check update
/// final result = await manager.checkUpdates();
///
/// // Jika ada update
/// if (result.hasUpdate) {
///   await manager.runUpdate(result: result);
/// }
/// ```
class UpdateManager {
  // ============================================================
  // CONSTRUCTOR
  // ============================================================
  UpdateManager({
    required UpdateConfig config,
    this.onProgress,
    this.onStatusChange,
    this.dialogBuilder,
  })  : _storage = const UpdateStateStorage(),
        _nativeUpdater = NativeUpdater(config: config),
        _codePushUpdater = CodePushUpdater(
          config: config,
          isAutoUpdateEnabled: false, // Manual mode
        ),
        _changelogService = ChangelogService(
          githubOwner: config.githubOwner,
          githubRepository: config.githubRepository,
          githubToken: config.githubToken,
        ),
        _progressController = StreamController<UpdateProgress>.broadcast() {
    _status = UpdateManagerStatus.idle;
  }

  // ============================================================
  // DEPENDENCIES
  // ============================================================
  final UpdateStateStorage _storage;
  final NativeUpdater _nativeUpdater;
  final CodePushUpdater _codePushUpdater;
  final ChangelogService _changelogService;

  // ============================================================
  // PUBLIC PROPERTIES
  // ============================================================

  /// Status update saat ini
  UpdateManagerStatus get status => _status;
  UpdateManagerStatus _status = UpdateManagerStatus.idle;

  /// Progress stream untuk UI
  final StreamController<UpdateProgress> _progressController;
  Stream<UpdateProgress> get progressStream => _progressController.stream;

  /// Callback untuk progress (alternative to stream)
  final void Function(UpdateProgress progress)? onProgress;

  /// Callback untuk status change
  final void Function(UpdateManagerStatus status)? onStatusChange;

  /// Custom dialog builder (opsional)
  /// Jika tidak diset, akan menggunakan default dialog
  final Widget Function(
    BuildContext context,
    Changelog changelog,
    UpdateType type,
    VoidCallback onUpdate,
    VoidCallback onCancel,
  )? dialogBuilder;

  /// ✅ Tampilkan dialog update
  Future<bool> showUpdateDialog(
    BuildContext context,
    UpdateResult result,
  ) async {
    // ✅ Langsung panggil UpdateDialogManager
    return UpdateDialogManager.showUpdateDialog(
      context: context,
      manager: this,
      result: result,
      dialogBuilder: dialogBuilder,
    );
  }
  // ============================================================
  // CORE METHODS
  // ============================================================

  /// ✅ Check semua jenis update (Native + Code Push)
  ///
  /// Returns:
  /// - `UpdateResult` dengan informasi update yang tersedia
  Future<UpdateResult> checkUpdates() async {
    try {
      _setStatus(UpdateManagerStatus.checking);
      _emitProgress(0.0, 'Memeriksa update...');

      // 1. Check Native Update
      final nativeResult = await _nativeUpdater.check();

      if (nativeResult is Success<UpdateInfo>) {
        final info = nativeResult.data;

        if (info.hasUpdate) {
          // ✅ Ada native update
          UpdateLogger.info(
            'Native update tersedia: ${info.currentVersion} → ${info.latestVersion}',
          );

          // Ambil changelog dari GitHub
          final changelog = await _changelogService.getNativeChangelog(info);

          if (changelog != null) {
            _emitProgress(0.5, 'Update tersedia!');
            return UpdateResult.native(info: info, changelog: changelog);
          }

          // Fallback: tanpa changelog
          return UpdateResult.native(
            info: info,
            changelog: Changelog(
              version: info.latestVersion,
              content: 'Update tersedia',
              publishedAt: DateTime.now(),
              changes: [],
              type: ChangelogType.native,
            ),
          );
        }
      }

      // 2. Check Code Push (hanya jika tidak ada native update)
      _emitProgress(0.3, 'Memeriksa patch...');

      final hasPatch = await _codePushUpdater.check();

      if (hasPatch) {
        // Dapatkan versi saat ini
        final currentVersion = await _getCurrentVersion();

        // Cari patch info dari Git Tags
        final patchInfo = await _changelogService.getLatestPatch(
          currentVersion ?? '0.0.0',
        );

        if (patchInfo != null) {
          final changelog = await _changelogService.getPatchChangelog(
            patchInfo,
          );

          if (changelog != null) {
            _emitProgress(0.5, 'Patch tersedia!');
            return UpdateResult.codepush(info: patchInfo, changelog: changelog);
          }
        }

        // Fallback: tanpa changelog
        return UpdateResult.codepush(
          info: PatchInfo(
            tagName: 'patch',
            version: currentVersion ?? '0.0.0',
            patchVersion: '1',
            releaseNotes: 'Patch tersedia',
            publishedAt: DateTime.now(),
          ),
          changelog: Changelog(
            version: currentVersion ?? '0.0.0',
            content: 'Patch tersedia',
            publishedAt: DateTime.now(),
            changes: [],
            type: ChangelogType.patch,
            patchVersion: '1',
          ),
        );
      }

      // 3. Tidak ada update
      _emitProgress(1.0, 'Aplikasi sudah terbaru');
      _setStatus(UpdateManagerStatus.idle);

      return UpdateResult.none();
    } catch (e, stackTrace) {
      UpdateLogger.error(
        'Error checking updates',
        error: e,
        stackTrace: stackTrace,
      );
      _setStatus(UpdateManagerStatus.error);
      _emitError('Gagal mengecek update: $e');
      return UpdateResult.none();
    }
  }

  /// ✅ Jalankan update (prioritas: Native > Code Push)
  ///
  /// Native update akan dijalankan terlebih dahulu.
  /// Jika native update berhasil, code push akan di-check ulang.
  Future<void> runUpdate({required UpdateResult result}) async {
    if (!result.hasUpdate) {
      UpdateLogger.warning('Tidak ada update untuk dijalankan');
      return;
    }

    try {
      // Native update
      if (result.type == UpdateType.native) {
        await _runNativeUpdate(result);
        return;
      }

      // Code push
      if (result.type == UpdateType.codepush) {
        await _runCodePush(result);
        return;
      }

      UpdateLogger.warning('Unknown update type: ${result.type}');
    } catch (e, stackTrace) {
      UpdateLogger.error(
        'Error running update',
        error: e,
        stackTrace: stackTrace,
      );
      _setStatus(UpdateManagerStatus.error);
      _emitError('Gagal menjalankan update: $e');
    }
  }

  // ============================================================
  // NATIVE UPDATE
  // ============================================================

  Future<void> _runNativeUpdate(UpdateResult result) async {
    final info = result.nativeInfo!;

    try {
      _setStatus(UpdateManagerStatus.downloading);
      _emitProgress(0.2, 'Mengunduh APK...');

      // 1. Download APK
      final downloadResult = await _nativeUpdater.download(
        updateInfo: info,
        onProgress: (progress) {
          final mappedProgress = 0.2 + (progress.progress * 0.6);
          _emitProgress(
            mappedProgress,
            'Mengunduh ${(progress.progress * 100).toStringAsFixed(0)}%',
          );
        },
      );

      if (downloadResult is Error<DownloadInfo>) {
        UpdateLogger.error('Download gagal: ${downloadResult.failure.message}');
        _setStatus(UpdateManagerStatus.error);
        _emitError('Download gagal: ${downloadResult.failure.message}');
        return;
      }

      final downloadInfo = (downloadResult as Success<DownloadInfo>).data;
      _emitProgress(0.8, 'Download selesai');

      // 2. Simpan pending native update
      await _storage.saveNativeUpdate(
        version: info.latestVersion,
        apkPath: downloadInfo.localFilePath,
      );

      // 3. Install APK
      _setStatus(UpdateManagerStatus.installing);
      _emitProgress(0.9, 'Menginstal APK...');

      final installResult = await _nativeUpdater.install(
        apkPath: downloadInfo.localFilePath,
      );

      if (installResult is Error<void>) {
        UpdateLogger.error('Instalasi gagal: ${installResult.failure.message}');
        _setStatus(UpdateManagerStatus.error);
        _emitError('Instalasi gagal: ${installResult.failure.message}');
        return;
      }

      // 4. Native update sukses, app akan close
      _setStatus(UpdateManagerStatus.complete);
      _emitProgress(1.0, 'Instalasi berhasil');

      // Hapus pending
      await _storage.clearPendingNative();

      UpdateLogger.info('✅ Native update berhasil');

      // 5. Check patch setelah native update (jika app tidak close)
      // Catatan: Native update akan close app, jadi ini hanya fallback
      await _checkPatchAfterNativeUpdate();
    } catch (e, stackTrace) {
      UpdateLogger.error(
        'Error in native update',
        error: e,
        stackTrace: stackTrace,
      );
      _setStatus(UpdateManagerStatus.error);
      _emitError('Gagal: $e');
    }
  }

  Future<void> _checkPatchAfterNativeUpdate() async {
    try {
      final hasPatch = await _codePushUpdater.check();
      if (hasPatch) {
        UpdateLogger.info('Patch tersedia setelah native update');
        // Simpan state bahwa ada patch pending
        await _storage.savePendingPatch(
          version: await _getCurrentVersion() ?? '0.0.0',
          patchVersion: '1',
          tagName: 'patch-pending',
          releaseNotes: 'Patch tersedia setelah update',
        );
      }
    } catch (e) {
      UpdateLogger.warning('Gagal cek patch setelah native update: $e');
    }
  }

  // ============================================================
  // CODE PUSH
  // ============================================================

  /// ✅ Setelah download patch, berikan 2 opsi ke user:
  /// 1. "Restart Sekarang" → Langsung restart
  /// 2. "Nanti" → Patch akan aktif saat app di-restart (cold start)
  Future<void> _runCodePush(UpdateResult result) async {
    try {
      _setStatus(UpdateManagerStatus.patching);
      _emitProgress(0.3, 'Mengunduh patch...');

      // 1. Download patch
      final downloaded = await _codePushUpdater.downloadUpdate();

      if (!downloaded) {
        UpdateLogger.warning('Tidak ada patch untuk didownload');
        _setStatus(UpdateManagerStatus.idle);
        _emitProgress(1.0, 'Tidak ada update');
        return;
      }

      _emitProgress(0.8, 'Patch siap');

      // 2. Simpan pending patch
      final currentVersion = await _getCurrentVersion() ?? '0.0.0';
      await _storage.savePendingPatch(
        version: currentVersion,
        patchVersion: '1',
        tagName: 'patch-pending',
        releaseNotes: result.changelog?.content ?? 'Patch tersedia',
      );

      // 3. ✅ Simpan status "patch ready"
      _setStatus(UpdateManagerStatus.patchReady);
      _emitProgress(0.9, 'Patch siap, restart diperlukan');

      UpdateLogger.info('✅ Patch berhasil didownload');

      // 4. ✅ Tampilkan dialog ke user (di UI layer)
      //    - "Restart Sekarang" → panggil applyPendingPatch()
      //    - "Nanti" → patch akan aktif saat app di-restart (cold start)
    } catch (e, stackTrace) {
      UpdateLogger.error('Error in code push',
          error: e, stackTrace: stackTrace);
      _setStatus(UpdateManagerStatus.error);
      _emitError('Gagal: $e');
    }
  }

  /// ✅ Restart app untuk apply patch
  ///
  /// Dipanggil setelah user mengkonfirmasi restart.
  Future<bool> applyPendingPatch() async {
    try {
      final pending = await _storage.getPendingPatch();

      if (pending == null) {
        UpdateLogger.warning('Tidak ada pending patch');
        return false;
      }

      _setStatus(UpdateManagerStatus.restarting);
      _emitProgress(0.95, 'Merestart aplikasi...');

      // Clear pending sebelum restart
      await _storage.clearPendingPatch();

      // Restart app
      await _codePushUpdater.applyAndRestart();

      return true;
    } catch (e, stackTrace) {
      UpdateLogger.error(
        'Error applying pending patch',
        error: e,
        stackTrace: stackTrace,
      );
      _setStatus(UpdateManagerStatus.error);
      _emitError('Gagal restart: $e');
      return false;
    }
  }

  // ============================================================
  // PENDING INSTALL
  // ============================================================

  /// ✅ Cek apakah ada pending native update
  Future<({String version, String apkPath})?> getPendingNative() async {
    return _storage.getPendingNative();
  }

  /// ✅ Cek apakah ada pending patch
  Future<
      ({
        String version,
        String patchVersion,
        String tagName,
        String releaseNotes,
      })?> getPendingPatch() async {
    return _storage.getPendingPatch();
  }

  // ============================================================
  // CHANGELOG
  // ============================================================

  /// ✅ Dapatkan changelog untuk update
  Future<Changelog?> getChangelog(UpdateResult result) async {
    if (!result.hasUpdate) return null;

    if (result.type == UpdateType.native && result.nativeInfo != null) {
      return _changelogService.getNativeChangelog(result.nativeInfo!);
    }

    if (result.type == UpdateType.codepush && result.patchInfo != null) {
      return _changelogService.getPatchChangelog(result.patchInfo!);
    }

    return null;
  }

  /// ✅ Dapatkan changelog untuk pending patch
  Future<Changelog?> getPendingPatchChangelog() async {
    final pending = await _storage.getPendingPatch();
    if (pending == null) return null;
    final changes = ChangelogParser.parseChanges(pending.releaseNotes);
    return Changelog(
      version: pending.version,
      content: pending.releaseNotes,
      publishedAt: DateTime.now(),
      changes: changes,
      type: ChangelogType.patch,
      patchVersion: pending.patchVersion,
    );
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// ✅ Batalkan proses yang sedang berjalan
  void cancel() {
    _nativeUpdater.cancel();
    _setStatus(UpdateManagerStatus.idle);
    _emitProgress(0, 'Dibatalkan');
    UpdateLogger.info('Update cancelled');
  }

  /// ✅ Dapatkan versi aplikasi saat ini
  Future<String?> _getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      UpdateLogger.warning('Gagal mendapatkan versi: $e');
      return null;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _setStatus(UpdateManagerStatus status) {
    _status = status;
    onStatusChange?.call(_status);
  }

  void _emitProgress(double progress, String message) {
    final updateProgress = UpdateProgress(
      type: _status == UpdateManagerStatus.patching ||
              _status == UpdateManagerStatus.patchReady
          ? UpdateType.codepush
          : UpdateType.native,
      progress: progress,
      message: message,
      isComplete: progress >= 1.0,
      hasError: false,
    );

    _progressController.add(updateProgress);
    onProgress?.call(updateProgress);
  }

  void _emitError(String message) {
    final errorProgress = UpdateProgress(
      type: UpdateType.none,
      progress: 0,
      message: message,
      isComplete: true,
      hasError: true,
      errorMessage: message,
    );

    _progressController.add(errorProgress);
    onProgress?.call(errorProgress);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  /// ✅ Dispose resources
  void dispose() {
    _progressController.close();
    UpdateLogger.info('UpdateManager disposed');
  }
}
