import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';
import '../../features/settings/data/settings_repository.dart';

class DebugHelper {
  static Future<void> printApiConfigDebugInfo(
    StorageService storage,
    SettingsRepository settingsRepo,
  ) async {
    if (!kDebugMode) return;

    print('\n========== API 配置调试信息 ==========');

    // 1. 检查所有存储的 keys
    final allKeys = await storage.getAllKeys();
    print('\n1. 所有存储的 keys (${allKeys.length} 个):');
    for (final key in allKeys) {
      print('  - $key');
    }

    // 2. 检查所有 API 配置
    final allConfigs = await settingsRepo.getAllApiConfigs();
    print('\n2. 所有 API 配置 (${allConfigs.length} 个):');
    for (final config in allConfigs) {
      print('  - ${config.name}');
      print('    ID: ${config.id}');
      print('    Provider: ${config.provider}');
      print('    BaseUrl: ${config.baseUrl}');
      print('    IsActive: ${config.isActive}');
      print('    DefaultModel: ${config.defaultModel}');
    }

    // 3. 检查活动配置
    final activeConfig = await settingsRepo.getActiveApiConfig();
    print('\n3. 活动 API 配置:');
    if (activeConfig != null) {
      print('  ✅ 找到活动配置');
      print('  - 名称: ${activeConfig.name}');
      print('  - ID: ${activeConfig.id}');
      print('  - Provider: ${activeConfig.provider}');
      print('  - BaseUrl: ${activeConfig.baseUrl}');
      print('  - IsActive: ${activeConfig.isActive}');
    } else {
      print('  ❌ 未找到活动配置');
    }

    print('\n====================================\n');
  }
}
