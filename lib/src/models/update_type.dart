/// Tipe update
enum UpdateType {
  /// Native update (APK dari GitHub Release)
  native,

  /// Code push (Patch dari Shorebird)
  codepush,

  /// Tidak ada update
  none,
}