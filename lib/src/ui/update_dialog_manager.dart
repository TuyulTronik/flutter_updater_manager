import 'package:flutter/material.dart';
import '../core/update_manager.dart';
import '../core/update_result.dart';
import '../models/changelog.dart';
import '../models/update_type.dart';
import 'default_changelog_dialog.dart';

/// Manager untuk menampilkan dialog update
class UpdateDialogManager {
  const UpdateDialogManager._();

  /// Tampilkan dialog update
  ///
  /// Jika [dialogBuilder] diset, akan menggunakan custom dialog.
  /// Jika tidak, akan menggunakan default dialog.
  static Future<bool> showUpdateDialog({
    required BuildContext context,
    required UpdateManager manager,
    required UpdateResult result,
    Widget Function(
      BuildContext context,
      Changelog changelog,
      UpdateType type,
      VoidCallback onUpdate,
      VoidCallback onCancel,
    )? dialogBuilder,
  }) async {
    if (!result.hasUpdate) return false;

    final changelog = await manager.getChangelog(result);
    
    // ✅ Cek apakah context masih valid setelah async
    if (!context.mounted) {
      return false;
    }
    
    if (changelog == null) return false;

    // ✅ Gunakan custom builder jika ada
    if (dialogBuilder != null) {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => dialogBuilder(
          context,
          changelog,
          result.type,
          () => Navigator.pop(context, true),
          () => Navigator.pop(context, false),
        ),
      ) ?? false;
    }

    // ✅ Default dialog
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DefaultChangelogDialog(
        changelog: changelog,
        updateType: result.type,
        onUpdate: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    ) ?? false;
  }
}