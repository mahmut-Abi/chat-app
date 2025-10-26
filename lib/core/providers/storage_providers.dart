import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../services/log_service.dart';
import '../../features/settings/data/settings_repository.dart';

/// 简债悠演 Providers
/// 存储、设置、日志相关

// ============ 基础服务 ============

/// 存储服务 Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// 日志服务 Provider
final logServiceProvider = Provider<LogService>((ref) {
  return LogService();
});

// ============ 设置仓一一一 ============

/// 设置仓一一一 Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(storageServiceProvider));
});
