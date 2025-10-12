import 'dart:convert';
import '../storage/storage_service.dart';

class DataExportImport {
  final StorageService _storage;

  DataExportImport(this._storage);

  Future<String> exportAllData() async {
    final conversations = _storage.getAllConversations();
    final apiConfigs = await _storage.getAllApiConfigs();
    
    final data = {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'conversations': conversations,
      'apiConfigs': apiConfigs,
    };

    return jsonEncode(data);
  }

  Future<Map<String, dynamic>> importData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      
      int conversationsCount = 0;
      int apiConfigsCount = 0;

      if (data.containsKey('conversations')) {
        final conversations = data['conversations'] as List;
        for (final conv in conversations) {
          final convMap = conv as Map<String, dynamic>;
          await _storage.saveConversation(
            convMap['id'] as String,
            convMap,
          );
          conversationsCount++;
        }
      }

      if (data.containsKey('apiConfigs')) {
        final apiConfigs = data['apiConfigs'] as List;
        for (final config in apiConfigs) {
          final configMap = config as Map<String, dynamic>;
          await _storage.saveApiConfig(
            configMap['id'] as String,
            configMap,
          );
          apiConfigsCount++;
        }
      }

      return {
        'success': true,
        'conversationsCount': conversationsCount,
        'apiConfigsCount': apiConfigsCount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
