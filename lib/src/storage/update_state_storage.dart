import 'package:shared_preferences/shared_preferences.dart';

/// Storage untuk state update menggunakan SharedPreferences
class UpdateStateStorage {
  const UpdateStateStorage();

  // ============================================================
  // KEYS
  // ============================================================
  static const String _nativeVersionKey = 'updater_native_version';
  static const String _nativeApkPathKey = 'updater_native_apk_path';
  static const String _patchVersionKey = 'updater_patch_version';
  static const String _patchBaseVersionKey =
      'updater_patch_base_version'; // ✅ Baru
  static const String _patchTagKey = 'updater_patch_tag';
  static const String _patchReleaseNotesKey = 'updater_patch_release_notes';
  static const String _lastCheckedKey = 'updater_last_checked';

  // ============================================================
  // NATIVE UPDATE
  // ============================================================

  /// Simpan native update yang pending
  Future<void> saveNativeUpdate({
    required String version,
    required String apkPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nativeVersionKey, version);
    await prefs.setString(_nativeApkPathKey, apkPath);
  }

  /// Dapatkan native update yang pending
  Future<({String version, String apkPath})?> getPendingNative() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_nativeVersionKey);
    final apkPath = prefs.getString(_nativeApkPathKey);

    if (version != null && apkPath != null) {
      return (version: version, apkPath: apkPath);
    }
    return null;
  }

  /// Hapus pending native update
  Future<void> clearPendingNative() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nativeVersionKey);
    await prefs.remove(_nativeApkPathKey);
  }

  // ============================================================
// PATCH UPDATE
// ============================================================

  /// Simpan patch yang pending
  Future<void> savePendingPatch({
    required String version, // Base version: 1.0.1
    required String patchVersion, // Patch number: 1
    required String tagName,
    required String releaseNotes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patchBaseVersionKey, version);
    await prefs.setString(_patchVersionKey, patchVersion);
    await prefs.setString(_patchTagKey, tagName);
    await prefs.setString(_patchReleaseNotesKey, releaseNotes);
  }

  /// Dapatkan patch yang pending
  Future<
      ({
        String version,
        String patchVersion,
        String tagName,
        String releaseNotes,
      })?> getPendingPatch() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_patchBaseVersionKey); // ✅ Base version
    final patchVersion = prefs.getString(_patchVersionKey); // ✅ Patch number
    final tagName = prefs.getString(_patchTagKey);
    final releaseNotes = prefs.getString(_patchReleaseNotesKey);

    if (version != null &&
        patchVersion != null &&
        tagName != null &&
        releaseNotes != null) {
      return (
        version: version,
        patchVersion: patchVersion,
        tagName: tagName,
        releaseNotes: releaseNotes,
      );
    }
    return null;
  }

  /// Hapus pending patch
  Future<void> clearPendingPatch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_patchBaseVersionKey);
    await prefs.remove(_patchVersionKey);
    await prefs.remove(_patchTagKey);
    await prefs.remove(_patchReleaseNotesKey);
  }
  // ============================================================
  // LAST CHECKED
  // ============================================================

  /// Simpan waktu terakhir check update
  Future<void> saveLastChecked(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckedKey, time.toIso8601String());
  }

  /// Dapatkan waktu terakhir check update
  Future<DateTime?> getLastChecked() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_lastCheckedKey);
    if (data != null) {
      return DateTime.parse(data);
    }
    return null;
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  /// Hapus semua data storage
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nativeVersionKey);
    await prefs.remove(_nativeApkPathKey);
    await prefs.remove(_patchVersionKey);
    await prefs.remove(_patchTagKey);
    await prefs.remove(_patchReleaseNotesKey);
    await prefs.remove(_lastCheckedKey);
  }
}
