/// Konfigurasi untuk UpdateManager
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

  /// Owner GitHub (username atau organisasi)
  final String githubOwner;

  /// Nama repository GitHub
  final String githubRepository;

  /// Pattern untuk memilih asset APK
  final String apkPattern;

  /// Token GitHub untuk private repository (opsional)
  final String? githubToken;

  /// Shorebird App ID
  final String shorebirdAppId;

  /// Hapus APK setelah install (default: false)
  final bool autoDeleteAfterInstall;

  /// Tutup app setelah install (default: true)
  final bool closeAppAfterInstall;

  /// Copy dengan perubahan
  UpdateConfig copyWith({
    String? githubOwner,
    String? githubRepository,
    String? apkPattern,
    String? githubToken,
    String? shorebirdAppId,
    bool? autoDeleteAfterInstall,
    bool? closeAppAfterInstall,
  }) {
    return UpdateConfig(
      githubOwner: githubOwner ?? this.githubOwner,
      githubRepository: githubRepository ?? this.githubRepository,
      apkPattern: apkPattern ?? this.apkPattern,
      githubToken: githubToken ?? this.githubToken,
      shorebirdAppId: shorebirdAppId ?? this.shorebirdAppId,
      autoDeleteAfterInstall: autoDeleteAfterInstall ?? this.autoDeleteAfterInstall,
      closeAppAfterInstall: closeAppAfterInstall ?? this.closeAppAfterInstall,
    );
  }
}