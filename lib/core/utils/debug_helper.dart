import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';
import '../../features/settings/data/settings_repository.dart';
import '../services/log_service.dart';

class DebugHelper {
  static final LogService _log = LogService();

  /// 统一日志输出：消息
  static void log(String message, [String? prefix]) {
    if (!kDebugMode) return;
    final displayMessage = prefix != null ? '[$prefix] $message' : message;

  }

  /// 统一日志输出：错误
  static void logError(String message, [String? prefix, Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      final displayMessage = prefix != null ? '[$prefix] ❌ $message' : '❌ $message';


    }
    if (error != null && stack != null) {
      _log.error(message, error, stack);
    }
  }

  /// 统一日志输出：成功
  static void logSuccess(String message, [String? prefix]) {
    if (!kDebugMode) return;
    final displayMessage = prefix != null ? '[$prefix] ✅ $message' : '✅ $message';

  }

  /// 统一日志输出：Health Check
  static void logHealthCheck(String path, {int? statusCode, Object? error}) {
    if (!kDebugMode) return;
    if (statusCode != null) {
      log('$path -> HTTP $statusCode', 'HealthCheck');
    } else if (error != null) {
      logError('$path -> $error', 'HealthCheck');
    }
  }

  static Future<void> printApiConfigDebugInfo(
    StorageService storage,
    SettingsRepository settingsRepo,
  ) async {
    if (!kDebugMode) return;



    // 1. 检查所有存储的 keys
    final allKeys = await storage.getAllKeys();

    for (final key in allKeys) {

    }

    // 2. 检查所有 API 配置
    final allConfigs = await settingsRepo.getAllApiConfigs();

    for (final config in allConfigs) {






    }

    // 3. 检查活动配置
    final activeConfig = await settingsRepo.getActiveApiConfig();

    if (activeConfig != null) {






    } else {

    }


  }
}
