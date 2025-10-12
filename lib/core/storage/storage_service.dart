import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static const String _conversationsBox = 'conversations';
  static const String _settingsBox = 'settings';
  static const String _groupsBox = 'conversation_groups';
  // Used for API config method naming
  // ignore: unused_field
  static const String _apiConfigsBox = 'api_configs';

  late Box _conversationsBoxInstance;
  late Box _settingsBoxInstance;
  late Box _groupsBoxInstance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    await Hive.initFlutter();
    _conversationsBoxInstance = await Hive.openBox(_conversationsBox);
    _settingsBoxInstance = await Hive.openBox(_settingsBox);
    _groupsBoxInstance = await Hive.openBox(_groupsBox);
  }

  // Conversations
  Future<void> saveConversation(String id, Map<String, dynamic> data) async {
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

  // Settings
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBoxInstance.put(key, value);
  }

  T? getSetting<T>(String key) {
    return _settingsBoxInstance.get(key) as T?;
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
    await _conversationsBoxInstance.clear();
    await _settingsBoxInstance.clear();
    await _groupsBoxInstance.clear();
    await _secureStorage.deleteAll();
  }
}
