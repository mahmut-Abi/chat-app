import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class StorageService {
  static const String _conversationsBox = 'conversations';
  static const String _settingsBox = 'settings';
  static const String _groupsBox = 'conversation_groups';
  static const String _promptsBox = 'prompt_templates';
  // Used for API config method naming
  // ignore: unused_field
  static const String _apiConfigsBox = 'api_configs';

  late Box _conversationsBoxInstance;
  late Box _settingsBoxInstance;
  late Box _groupsBoxInstance;
  late Box _promptsBoxInstance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _conversationsBoxInstance = await Hive.openBox(_conversationsBox);
      _settingsBoxInstance = await Hive.openBox(_settingsBox);
      _groupsBoxInstance = await Hive.openBox(_groupsBox);
      _promptsBoxInstance = await Hive.openBox(_promptsBox);
      if (kDebugMode) {
        print('存储初始化成功');
        print('  对话数: ${_conversationsBoxInstance.length}');
        print('  设置数: ${_settingsBoxInstance.length}');
        print('  分组数: ${_groupsBoxInstance.length}');
        print('  提示词模板数: ${_promptsBoxInstance.length}');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('存储初始化失败: $e');
        print('堆栈: $stack');
      }
      rethrow;
    }
  }

  // Conversations
  Future<void> saveConversation(String id, Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('saveConversation: id=$id');
    }
    await _conversationsBoxInstance.put(id, jsonEncode(data));
  }

  Map<String, dynamic>? getConversation(String id) {
    final data = _conversationsBoxInstance.get(id);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> getAllConversations() {
    return _conversationsBoxInstance.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> deleteConversation(String id) async {
    await _conversationsBoxInstance.delete(id);
  }

  // Conversation Groups
  Future<void> saveGroup(String id, Map<String, dynamic> data) async {
    await _groupsBoxInstance.put(id, jsonEncode(data));
  }

  Map<String, dynamic>? getGroup(String id) {
    final data = _groupsBoxInstance.get(id);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> getAllGroups() {
    return _groupsBoxInstance.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> deleteGroup(String id) async {
    await _groupsBoxInstance.delete(id);
  }

  // Prompt Templates
  Future<void> savePromptTemplate(String id, Map<String, dynamic> data) async {
    await _promptsBoxInstance.put(id, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getPromptTemplate(String id) async {
    final data = _promptsBoxInstance.get(id);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAllPromptTemplates() async {
    return _promptsBoxInstance.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> deletePromptTemplate(String id) async {
    await _promptsBoxInstance.delete(id);
  }

  // Settings
  Future<void> saveSetting(String key, dynamic value) async {
    if (kDebugMode) {
      print('saveSetting: key=$key, value=$value');
    }
    await _settingsBoxInstance.put(key, value);
  }

  T? getSetting<T>(String key) {
    try {
      final value = _settingsBoxInstance.get(key);
      if (kDebugMode) {
        print(
          'getSetting: key=$key, rawValue=$value, type=${value.runtimeType}',
        );
      }
      if (value == null) return null;
      return value as T;
    } catch (e) {
      if (kDebugMode) {
        print('读取设置失败: $key, 错误: $e');
      }
      return null;
    }
  }

  // Get all setting keys
  Future<List<String>> getAllKeys() async {
    return _settingsBoxInstance.keys.cast<String>().toList();
  }

  // Delete setting
  Future<void> deleteSetting(String key) async {
    await _settingsBoxInstance.delete(key);
  }

  // API Configs (Secure)
  Future<void> saveApiConfig(String id, Map<String, dynamic> config) async {
    await _secureStorage.write(
      key: 'api_config_\$id',
      value: jsonEncode(config),
    );
  }

  Future<Map<String, dynamic>?> getApiConfig(String id) async {
    final data = await _secureStorage.read(key: 'api_config_\$id');
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAllApiConfigs() async {
    final allData = await _secureStorage.readAll();
    return allData.entries
        .where((e) => e.key.startsWith('api_config_'))
        .map((e) => jsonDecode(e.value) as Map<String, dynamic>)
        .toList();
  }

  Future<void> deleteApiConfig(String id) async {
    await _secureStorage.delete(key: 'api_config_\$id');
  }

  // Clear all data
  Future<void> clearAll() async {
    try {
      if (kDebugMode) {
        print('clearAll: 开始清除所有数据');
        print('  对话数: ${_conversationsBoxInstance.length}');
        print('  设置数: ${_settingsBoxInstance.length}');
        print('  分组数: ${_groupsBoxInstance.length}');
        print('  提示词模板数: ${_promptsBoxInstance.length}');
      }

      await _conversationsBoxInstance.clear();
      await _settingsBoxInstance.clear();
      await _groupsBoxInstance.clear();
      await _promptsBoxInstance.clear();
      await _secureStorage.deleteAll();

      if (kDebugMode) {
        print('clearAll: 数据清除完成');
        print('  对话数: ${_conversationsBoxInstance.length}');
        print('  设置数: ${_settingsBoxInstance.length}');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('clearAll 错误: $e');
        print('Stack: $stack');
      }
      rethrow;
    }
  }
}
