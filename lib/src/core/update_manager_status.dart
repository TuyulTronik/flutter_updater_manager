/// Status update yang sedang berjalan
enum UpdateManagerStatus {
  /// Tidak ada proses update
  idle,

  /// Sedang mengecek update
  checking,

  /// Sedang mendownload (native)
  downloading,

  /// Sedang menginstal (native)
  installing,

  /// Sedang mem-patch (code push)
  patching,

  /// Patch siap, menunggu restart
  patchReady,

  /// Sedang merestart app
  restarting,

  /// Update selesai
  complete,

  /// Terjadi error
  error,
}