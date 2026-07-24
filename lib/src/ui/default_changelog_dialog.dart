import 'package:flutter/material.dart';
import '../models/changelog.dart';
import '../models/update_type.dart';
import 'changelog_helpers.dart';

/// Default dialog yang disediakan plugin
/// 
/// ## Contoh Penggunaan:
/// ```dart
/// final shouldUpdate = await showDialog<bool>(
///   context: context,
///   barrierDismissible: false,
///   builder: (context) => DefaultChangelogDialog(
///     changelog: changelog,
///     updateType: result.type,
///     onUpdate: () => Navigator.pop(context, true),
///     onCancel: () => Navigator.pop(context, false),
///   ),
/// );
/// ```
class DefaultChangelogDialog extends StatelessWidget {
  const DefaultChangelogDialog({
    super.key,
    required this.changelog,
    required this.updateType,
    this.onUpdate,
    this.onCancel,
    this.title,
    this.primaryButtonText,
    this.secondaryButtonText,
  });

  final Changelog changelog;
  final UpdateType updateType;
  final VoidCallback? onUpdate;
  final VoidCallback? onCancel;
  final String? title;
  final String? primaryButtonText;
  final String? secondaryButtonText;

  @override
  Widget build(BuildContext context) {
    final isNative = updateType == UpdateType.native;
    final isPatch = updateType == UpdateType.codepush;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            ChangelogHelpers.getIcon(updateType),
            color: ChangelogHelpers.getIconColor(updateType),
          ),
          const SizedBox(width: 8),
          Text(
            title ?? ChangelogHelpers.getTitle(updateType),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            changelog.displayTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(changelog.publishedAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          // Changelog content
          if (changelog.changes.isNotEmpty) ...[
            const Text(
              'Apa yang baru:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...changelog.changes.map(
              (change) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        change,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              changelog.content,
              style: const TextStyle(fontSize: 14),
            ),
          ],

          // Info message untuk patch
          if (isPatch) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aplikasi akan di-restart untuk menerapkan patch.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.pop(context, false),
          child: Text(
            secondaryButtonText ??
                ChangelogHelpers.getSecondaryButtonText(),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onUpdate ?? () => Navigator.pop(context, true),
          icon: Icon(
            isNative ? Icons.download : Icons.restart_alt,
            size: 18,
          ),
          label: Text(
            primaryButtonText ??
                ChangelogHelpers.getPrimaryButtonText(updateType),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}