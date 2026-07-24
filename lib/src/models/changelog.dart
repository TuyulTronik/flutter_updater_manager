/// Model changelog untuk ditampilkan ke user
class Changelog {
  const Changelog({
    required this.version,
    required this.content,
    required this.publishedAt,
    required this.changes,
    this.type = ChangelogType.native,
    this.patchVersion,
  });

  /// Versi aplikasi
  final String version;

  /// Konten lengkap (raw)
  final String content;

  /// Tanggal rilis
  final DateTime publishedAt;

  /// Daftar perubahan (list of bullet points)
  final List<String> changes;

  /// Tipe changelog
  final ChangelogType type;

  /// Versi patch (jika type = patch)
  final String? patchVersion;

  /// Format untuk ditampilkan
  String get displayTitle {
    if (type == ChangelogType.patch && patchVersion != null) {
      return 'Update $version+$patchVersion';
    }
    return 'Update $version';
  }

  /// Factory dari release notes GitHub
  factory Changelog.fromReleaseNotes({
    required String version,
    required String releaseNotes,
    required DateTime publishedAt,
    ChangelogType type = ChangelogType.native,
    String? patchVersion,
  }) {
    final changes = _parseChanges(releaseNotes);
    return Changelog(
      version: version,
      content: releaseNotes,
      publishedAt: publishedAt,
      changes: changes,
      type: type,
      patchVersion: patchVersion,
    );
  }

  /// Parse bullet points dari release notes
  static List<String> _parseChanges(String releaseNotes) {
    return releaseNotes
        .split('\n')
        .where((line) => line.trim().startsWith('-') || 
                         line.trim().startsWith('*') ||
                         line.trim().startsWith('•'))
        .map((line) => line.trim().substring(1).trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

/// Tipe changelog
enum ChangelogType {
  /// Dari GitHub Release (native)
  native,

  /// Dari Git Tag (patch)
  patch,
}