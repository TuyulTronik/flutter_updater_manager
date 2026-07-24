/// Info patch dari Git Tag
class PatchInfo {
  const PatchInfo({
    required this.tagName,
    required this.version,
    required this.patchVersion,
    required this.releaseNotes,
    required this.publishedAt,
  });

  /// Nama tag (contoh: v1.0.1-patch1)
  final String tagName;

  /// Versi base (contoh: 1.0.1)
  final String version;

  /// Nomor patch (contoh: 1)
  final String patchVersion;

  /// Release notes dari tag
  final String releaseNotes;

  /// Tanggal publish
  final DateTime publishedAt;

  /// Display name (contoh: 1.0.1+1)
  String get displayName => '$version+$patchVersion';

  /// Apakah patch ini lebih baru dari yang lain
  bool isNewerThan(PatchInfo other) {
    final thisPatch = int.tryParse(patchVersion) ?? 0;
    final otherPatch = int.tryParse(other.patchVersion) ?? 0;
    return thisPatch > otherPatch;
  }
}