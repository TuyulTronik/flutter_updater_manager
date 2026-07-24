import 'package:flutter_updater_manager/flutter_updater_manager.dart';

/// Wrapper untuk UpdateManager (singleton pattern)
class UpdateManagerWrapper {
  static final UpdateManagerWrapper _instance = UpdateManagerWrapper._internal();

  factory UpdateManagerWrapper() => _instance;

  UpdateManagerWrapper._internal();

  UpdateManager? _manager;

  /// Initialize UpdateManager with callbacks
  UpdateManager getManager({
    required void Function(UpdateProgress progress) onProgress,
    required void Function(UpdateManagerStatus status) onStatusChange,
  }) {
    _manager ??= UpdateManager(
      config: UpdateConfig(
        githubOwner: 'TuyulTronik',
        githubRepository: 'tulkit',
        apkPattern: 'release',
        shorebirdAppId: 'your_app_id_here',
        autoDeleteAfterInstall: false,
        closeAppAfterInstall: true,
      ),
      onProgress: onProgress,
      onStatusChange: onStatusChange,
      dialogBuilder: (context, changelog, type, onUpdate, onCancel) {
        return DefaultChangelogDialog(
          changelog: changelog,
          updateType: type,
          onUpdate: onUpdate,
          onCancel: onCancel,
        );
      },
    );

    return _manager!;
  }

  /// Get existing manager (if initialized)
  UpdateManager? get manager => _manager;
}