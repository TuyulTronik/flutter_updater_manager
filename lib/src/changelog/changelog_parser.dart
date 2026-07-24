import '../models/changelog.dart';

/// Parser untuk changelog dari berbagai sumber
class ChangelogParser {
  const ChangelogParser();

  /// Parse release notes menjadi list perubahan
  static List<String> parseChanges(String releaseNotes) {
    if (releaseNotes.isEmpty) return [];

    final lines = releaseNotes.split('\n');
    final changes = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Deteksi bullet points: -, *, •, atau angka
      if (trimmed.startsWith('-') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('•') ||
          RegExp(r'^\d+\.').hasMatch(trimmed)) {
        // Hapus prefix bullet
        var change = trimmed;
        if (trimmed.startsWith('-')) {
          change = trimmed.substring(1).trim();
        } else if (trimmed.startsWith('*')) {
          change = trimmed.substring(1).trim();
        } else if (trimmed.startsWith('•')) {
          change = trimmed.substring(1).trim();
        } else if (RegExp(r'^\d+\.').hasMatch(trimmed)) {
          change = trimmed.substring(trimmed.indexOf('.') + 1).trim();
        }

        if (change.isNotEmpty) {
          changes.add(change);
        }
      }
    }

    return changes;
  }

  /// Parse release notes menjadi Changelog object
  static Changelog parseToChangelog({
    required String version,
    required String releaseNotes,
    required DateTime publishedAt,
    ChangelogType type = ChangelogType.native,
    String? patchVersion,
  }) {
    final changes = parseChanges(releaseNotes);

    return Changelog(
      version: version,
      content: releaseNotes,
      publishedAt: publishedAt,
      changes: changes,
      type: type,
      patchVersion: patchVersion,
    );
  }

  /// Gabungkan dua changelog (misal: native + patch)
  static Changelog mergeChangelogs({
    required Changelog base,
    required Changelog patch,
  }) {
    // Gabungkan perubahan
    final mergedChanges = [
      ...base.changes,
      ...patch.changes.where((c) => !base.changes.contains(c)),
    ];

    return Changelog(
      version: base.version,
      content: '${base.content}\n\n${patch.content}',
      publishedAt: patch.publishedAt,
      changes: mergedChanges,
      type: ChangelogType.native, // Tetap native type
      patchVersion: patch.patchVersion,
    );
  }
}
