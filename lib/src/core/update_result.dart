import '../models/patch_info.dart';
import '../models/update_type.dart';
import '../models/changelog.dart';
import 'package:flutter_apk_updater/flutter_apk_updater.dart';

/// Hasil pengecekan update
class UpdateResult {
  const UpdateResult({
    required this.hasUpdate,
    required this.type,
    this.nativeInfo,
    this.patchInfo,
    this.changelog,
  });

  /// Apakah ada update
  final bool hasUpdate;

  /// Tipe update
  final UpdateType type;

  /// Info native update (jika ada)
  final UpdateInfo? nativeInfo;

  /// Info patch (jika ada)
  final PatchInfo? patchInfo;

  /// Changelog untuk update
  final Changelog? changelog;

  /// Factory untuk hasil kosong (tidak ada update)
  factory UpdateResult.none() {
    return const UpdateResult(
      hasUpdate: false,
      type: UpdateType.none,
    );
  }

  /// Factory untuk native update
  factory UpdateResult.native({
    required UpdateInfo info,
    required Changelog changelog,
  }) {
    return UpdateResult(
      hasUpdate: true,
      type: UpdateType.native,
      nativeInfo: info,
      changelog: changelog,
    );
  }

  /// Factory untuk code push
  factory UpdateResult.codepush({
    required PatchInfo info,
    required Changelog changelog,
  }) {
    return UpdateResult(
      hasUpdate: true,
      type: UpdateType.codepush,
      patchInfo: info,
      changelog: changelog,
    );
  }
}