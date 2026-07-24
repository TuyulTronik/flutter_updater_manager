import 'package:flutter/material.dart';
import 'package:flutter_updater_manager/flutter_updater_manager.dart';

/// Custom dialog with modern design
class CustomChangelogDialog extends StatelessWidget {
  const CustomChangelogDialog({
    super.key,
    required this.changelog,
    required this.type,
    required this.onUpdate,
    required this.onCancel,
  });

  final Changelog changelog;
  final UpdateType type;
  final VoidCallback onUpdate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isNative = type == UpdateType.native;
    final icon = isNative ? Icons.system_update : Icons.build;
    final iconColor = isNative ? Colors.orange : Colors.blue;
    final title = isNative ? 'Update Tersedia' : 'Patch Tersedia';
    final primaryText = isNative ? 'Install Sekarang' : 'Restart Sekarang';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dirilis: ${_formatDate(changelog.publishedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
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
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: iconColor)),
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
          ],
          if (!isNative) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: Colors.blue.shade700),
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
          onPressed: onCancel,
          child: Text(
            'Nanti',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onUpdate,
          icon: Icon(isNative ? Icons.download : Icons.restart_alt, size: 18),
          label: Text(primaryText),
          style: ElevatedButton.styleFrom(
            backgroundColor: iconColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
