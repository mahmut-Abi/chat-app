import 'dart:convert';
import '../storage/storage_service.dart';

class DataExportImport {
  final StorageService _storage;

  DataExportImport(this._storage);

  Future<String> exportAllData() async {
    final conversations = _storage.getAllConversations();
    final apiConfigs = await _storage.getAllApiConfigs();
    final appSettings = await _storage.getAppSettings();

    final data = {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'conversations': conversations,
      'apiConfigs': apiConfigs,
      'appSettings': appSettings, // 添加应用设置导出
    };

    return jsonEncode(data);
  }

  Future<Map<String, dynamic>> importData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      int conversationsCount = 0;
      int apiConfigsCount = 0;
      bool appSettingsImported = false;

      // 导入应用设置（包括背景图片）
      if (data.containsKey('appSettings') && data['appSettings'] != null) {
        final appSettings = data['appSettings'] as Map<String, dynamic>;
        await _storage.saveAppSettings(appSettings);
        appSettingsImported = true;
      }

      // 导入对话
      if (data.containsKey('conversations')) {
        final conversations = data['conversations'] as List;
        for (final conv in conversations) {
          final convMap = conv as Map<String, dynamic>;
          await _storage.saveConversation(convMap['id'] as String, convMap);
          conversationsCount++;
        }
      }

      // 导入 API 配置
      if (data.containsKey('apiConfigs')) {
        final apiConfigs = data['apiConfigs'] as List;
        for (final config in apiConfigs) {
          final configMap = config as Map<String, dynamic>;
          await _storage.saveApiConfig(configMap['id'] as String, configMap);
          apiConfigsCount++;
        }
      }

      return {
        'success': true,
        'conversationsCount': conversationsCount,
        'apiConfigsCount': apiConfigsCount,
        'appSettingsImported': appSettingsImported,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
