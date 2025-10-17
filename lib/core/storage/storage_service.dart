import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/log_service.dart';

class StorageService {
  final LogService _log = LogService();

  static const String _conversationsBox = 'conversations';
  static const String _settingsBox = 'settings';
  static const String _groupsBox = 'conversation_groups';
  static const String _promptsBox = 'prompt_templates';
  static const String _modelsBox = 'models';

  late Box _conversationsBoxInstance;
  late Box _settingsBoxInstance;
  late Box _groupsBoxInstance;
  late Box _promptsBoxInstance;
  late Box _modelsBoxInstance;

  Future<void> init() async {
    _log.info('开始初始化存储服务');
    try {
      await Hive.initFlutter();
      _conversationsBoxInstance = await Hive.openBox(_conversationsBox);
      _settingsBoxInstance = await Hive.openBox(_settingsBox);
      _groupsBoxInstance = await Hive.openBox(_groupsBox);
      _promptsBoxInstance = await Hive.openBox(_promptsBox);
      _modelsBoxInstance = await Hive.openBox(_modelsBox);

      _log.info('存储初始化成功', {
        'conversationsCount': _conversationsBoxInstance.length,
        'settingsCount': _settingsBoxInstance.length,
        'groupsCount': _groupsBoxInstance.length,
        'promptsCount': _promptsBoxInstance.length,
        'modelsCount': _modelsBoxInstance.length,
      });

      if (kDebugMode) {
        print('存储初始化成功');
        print('  对话数: \${_conversationsBoxInstance.length}');
        print('  设置数: \${_settingsBoxInstance.length}');
        print('  分组数: \${_groupsBoxInstance.length}');
        print('  提示词模板数: \${_promptsBoxInstance.length}');
        print('  模型数: \${_modelsBoxInstance.length}');
      }
    } catch (e, stack) {
      _log.error('存储初始化失败: \${e.toString()}', e, stack);
      rethrow;
    }
  }

  // Conversations
  Future<void> saveConversation(String id, Map<String, dynamic> data) async {
    _log.debug('保存对话', {'id': id, 'title': data['title']});
    if (kDebugMode) {
      print('saveConversation: id=\$id');
    }
    await _conversationsBoxInstance.put(id, jsonEncode(data));
  }

  Map<String, dynamic>? getConversation(String id) {
    _log.debug('读取对话', {'id': id});
    final data = _conversationsBoxInstance.get(id);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> getAllConversations() {
    _log.debug('读取所有对话');
    final conversations = _conversationsBoxInstance.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
    _log.debug('读取对话完成', {'count': conversations.length});
    return conversations;
  }

  Future<void> deleteConversation(String id) async {
    _log.debug('删除对话', {'id': id});
    await _conversationsBoxInstance.delete(id);
  }

  // Conversation Groups
  Future<void> saveGroup(String id, Map<String, dynamic> data) async {
    _log.debug('保存分组', {'id': id, 'name': data['name']});
    await _groupsBoxInstance.put(id, jsonEncode(data));
  }

  Map<String, dynamic>? getGroup(String id) {
    final data = _groupsBoxInstance.get(id);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> getAllGroups() {
    _log.debug('读取所有分组');
    return _groupsBoxInstance.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> deleteGroup(String id) async {
    _log.debug('删除分组', {'id': id});
    await _groupsBoxInstance.delete(id);
  }

  // Prompt Templates
  Future<void> savePromptTemplate(String id, Map<String, dynamic> data) async {
    _log.debug('保存提示词模板', {'id': id, 'title': data['title']});
    await _promptsBoxInstance.put(id, jsonEncode(data));
  }

  Map<String, dynamic>? getPromptTemplate(String id) {
    final data = _promptsBoxInstance.get(id);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> getAllPromptTemplates() {
    _log.debug('读取所有提示词模板');
    return _promptsBoxInstance.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> deletePromptTemplate(String id) async {
    _log.debug('删除提示词模板', {'id': id});
    await _promptsBoxInstance.delete(id);
  }

  // Settings
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBoxInstance.put(key, value);
  }

  dynamic getSetting(String key) {
    return _settingsBoxInstance.get(key);
  }

  Future<void> deleteSetting(String key) async {
    await _settingsBoxInstance.delete(key);
  }

  // API Configs
  Future<void> saveApiConfig(String id, Map<String, dynamic> data) async {
    await _settingsBoxInstance.put('api_config_$id', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getApiConfig(String id) async {
    final data = _settingsBoxInstance.get('api_config_$id');
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAllApiConfigs() async {
    if (kDebugMode) {
      print('StorageService.getAllApiConfigs: 检查所有 keys...');
      print('  总 key 数: ${_settingsBoxInstance.keys.length}');
    }
    final configs = <Map<String, dynamic>>[];
    for (final key in _settingsBoxInstance.keys) {
      if (kDebugMode) {
        print('  key: $key');
      }
      if (key.toString().startsWith('api_config_')) {
        if (kDebugMode) {
          print('    -> 找到 API 配置 key');
        }
        final data = _settingsBoxInstance.get(key);
        if (data != null) {
          if (kDebugMode) {
            print('    -> data: $data');
          }
          configs.add(jsonDecode(data as String) as Map<String, dynamic>);
        }
      }
    }
    if (kDebugMode) {
      print('StorageService.getAllApiConfigs: 找到 ${configs.length} 个配置');
    }
    return configs;
  }

  Future<void> deleteApiConfig(String id) async {
    await _settingsBoxInstance.delete('api_config_$id');
  }

  // App Settings (持久化到 Hive)
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    _log.debug('保存应用设置');
    await _settingsBoxInstance.put('app_settings', jsonEncode(settings));
  }

  Future<Map<String, dynamic>?> getAppSettings() async {
    final data = _settingsBoxInstance.get('app_settings');
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  // Models
  Future<void> saveModel(String id, Map<String, dynamic> data) async {
    _log.debug('保存模型', {'id': id, 'name': data['name']});
    await _modelsBoxInstance.put(id, jsonEncode(data));
  }

  Future<void> saveAllModels(List<Map<String, dynamic>> models) async {
    _log.info('保存所有模型', {'count': models.length});
    await _modelsBoxInstance.clear();
    for (final model in models) {
      await _modelsBoxInstance.put(model['id'], jsonEncode(model));
    }
  }

  Map<String, dynamic>? getModel(String id) {
    final data = _modelsBoxInstance.get(id);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> getAllModels() {
    return _modelsBoxInstance.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> deleteModel(String id) async {
    await _modelsBoxInstance.delete(id);
  }

  Future<void> clearAllModels() async {
    _log.info('清除所有模型');
    await _modelsBoxInstance.clear();
  }

  // Get all keys from settings box
  Future<List<String>> getAllKeys() async {
    return _settingsBoxInstance.keys.map((k) => k.toString()).toList();
  }

  // Clear all data
  Future<void> clearAll() async {
    try {
      // 只清除对话、分组和提示词模板数据，保留设置和 API 配置
      await _conversationsBoxInstance.clear();
      await _groupsBoxInstance.clear();
      await _promptsBoxInstance.clear();
    } catch (e) {
      if (kDebugMode) {
        print('clearAll 错误: \$e');
      }
      rethrow;
    }
  }
}
