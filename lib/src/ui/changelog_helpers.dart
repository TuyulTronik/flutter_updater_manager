import 'package:flutter/material.dart';
import '../models/changelog.dart';
import '../models/update_type.dart';

/// Helper untuk membuat custom UI changelog
/// 
/// ## Contoh Penggunaan:
/// ```dart
/// final icon = ChangelogHelpers.getIcon(result.type);
/// final title = ChangelogHelpers.getTitle(result.type);
/// final primaryText = ChangelogHelpers.getPrimaryButtonText(result.type);
/// ```
class ChangelogHelpers {
  const ChangelogHelpers();

  /// Dapatkan icon berdasarkan tipe update
  static IconData getIcon(UpdateType type) {
    switch (type) {
      case UpdateType.native:
        return Icons.system_update;
      case UpdateType.codepush:
        return Icons.build;
      default:
        return Icons.update;
    }
  }

  /// Dapatkan warna icon berdasarkan tipe update
  static Color getIconColor(UpdateType type) {
    switch (type) {
      case UpdateType.native:
        return Colors.orange;
      case UpdateType.codepush:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Dapatkan judul dialog berdasarkan tipe update
  static String getTitle(UpdateType type) {
    switch (type) {
      case UpdateType.native:
        return 'Update Tersedia';
      case UpdateType.codepush:
        return 'Patch Tersedia';
      default:
        return 'Update Tersedia';
    }
  }

  /// Dapatkan tombol primary text berdasarkan tipe update
  static String getPrimaryButtonText(UpdateType type) {
    switch (type) {
      case UpdateType.native:
        return 'Install Sekarang';
      case UpdateType.codepush:
        return 'Restart Sekarang';
      default:
        return 'Update';
    }
  }

  /// Dapatkan tombol secondary text (konsisten)
  static String getSecondaryButtonText() {
    return 'Nanti';
  }

  /// Dapatkan pesan info tambahan (untuk patch)
  static String? getInfoMessage(UpdateType type) {
    if (type == UpdateType.codepush) {
      return 'Aplikasi akan di-restart untuk menerapkan patch.';
    }
    return null;
  }

  /// Format changelog menjadi string (untuk custom UI)
  static String formatChangelog(Changelog changelog) {
    final buffer = StringBuffer();
    buffer.writeln(changelog.displayTitle);
    buffer.writeln('Dirilis: ${_formatDate(changelog.publishedAt)}');
    buffer.writeln();

    if (changelog.changes.isNotEmpty) {
      buffer.writeln('Apa yang baru:');
      for (final change in changelog.changes) {
        buffer.writeln('• $change');
      }
    } else {
      buffer.writeln(changelog.content);
    }

    return buffer.toString();
  }

  static String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}