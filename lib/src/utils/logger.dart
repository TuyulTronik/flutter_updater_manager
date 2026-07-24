/// Simple logger untuk debugging
class UpdateLogger {
  UpdateLogger._();

  static bool isDebugMode = false;

  static void log(String message, {String? tag}) {
    if (!isDebugMode) return;
    final prefix = tag != null ? '[$tag]' : '[UpdaterManager]';
    UpdateLogger.warning('$prefix $message');
  }

  static void info(String message) {
    log(message, tag: 'INFO');
  }

  static void warning(String message) {
    log('⚠️ $message', tag: 'WARN');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    log('❌ $message', tag: 'ERROR');
    if (error != null) {
      UpdateLogger.warning('   Error: $error');
    }
    if (stackTrace != null) {
      UpdateLogger.warning('   StackTrace: $stackTrace');
    }
  }

  static void debug(String message) {
    if (isDebugMode) {
      log('🔍 $message', tag: 'DEBUG');
    }
  }
}