library;

// Core
export 'src/core/update_manager.dart';
export 'src/core/update_result.dart';
export 'src/core/update_manager_status.dart';

// Models
export 'src/models/update_config.dart';
export 'src/models/update_progress.dart';
export 'src/models/update_type.dart';
export 'src/models/changelog.dart';
export 'src/models/patch_info.dart';

// UI (opsional)
export 'src/ui/changelog_helpers.dart';
export 'src/ui/default_changelog_dialog.dart';
export 'src/ui/update_dialog_manager.dart';

// Wrappers (opsional, untuk advanced usage)
export 'src/native/native_updater.dart';
export 'src/codepush/code_push_updater.dart';

// Storage (opsional)
export 'src/storage/update_state_storage.dart';