import 'package:flutter/foundation.dart';
import '../services/log_service.dart';

class DebugHelper {
  static final LogService _log = LogService();

  /// 统一日志输出：消息
  static void log(String message, [String? prefix]) {
    if (!kDebugMode) return;
    final displayMessage = prefix != null ? '[\$prefix] \$message' : message;
    _log.debug(displayMessage);
  }

  /// 统一日志输出：错误
  static void logError(String message, [String? prefix, Object? error, StackTrace? stack]) {
    if (!kDebugMode) return;
    final displayMessage = prefix != null ? '[\$prefix] ❌ \$message' : '❌ \$message';
    _log.debug(displayMessage);
    if (error != null && stack != null) {
      _log.error(message, error, stack);
    }
  }

  /// 统一日志输出：成功
  static void logSuccess(String message, [String? prefix]) {
    if (!kDebugMode) return;
    final displayMessage = prefix != null ? '[\$prefix] ✅ \$message' : '✅ \$message';
    _log.debug(displayMessage);
  }

  /// 统一日志输出：Health Check
  static void logHealthCheck(String path, {int? statusCode, Object? error}) {
    if (!kDebugMode) return;
    if (statusCode != null) {
      log('\$path -> HTTP \$statusCode', 'HealthCheck');
    } else if (error != null) {
      logError('\$path -> \$error', 'HealthCheck');
    }
  }
}
