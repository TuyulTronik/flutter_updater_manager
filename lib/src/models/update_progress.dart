import '../core/update_manager_status.dart';
import 'update_type.dart';

/// Progress update untuk UI
class UpdateProgress {
  const UpdateProgress({
    required this.type,
    required this.progress,
    required this.message,
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
    this.status,
  });

  /// Tipe update (native / codepush)
  final UpdateType type;

  /// Progress 0.0 - 1.0
  final double progress;

  /// Pesan status
  final String message;

  /// Apakah sudah selesai
  final bool isComplete;

  /// Apakah terjadi error
  final bool hasError;

  /// Pesan error (jika ada)
  final String? errorMessage;

  final UpdateManagerStatus? status;

  /// Copy dengan perubahan
  UpdateProgress copyWith({
    UpdateType? type,
    double? progress,
    String? message,
    bool? isComplete,
    bool? hasError,
    String? errorMessage,
    UpdateManagerStatus? status,
  }) {
    return UpdateProgress(
      type: type ?? this.type,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      isComplete: isComplete ?? this.isComplete,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
    );
  }
}
