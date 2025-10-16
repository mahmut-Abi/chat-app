import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/log_service.dart';

class StorageService {
  final LogService _log = LogService();

  static const String _conversationsBox = 'conversations';
  static const String _settingsBox = 'settings';
  static const String _groupsBox = 'conversation_groups';
  static const String _promptsBox = 'prompt_templates';
  static const String _modelsBox = 'models';
  // Used for API config method naming
  // ignore: unused_field
  static const String _apiConfigsBox = 'api_configs';

  late Box _conversationsBoxInstance;
  late Box _settingsBoxInstance;
  late Box _groupsBoxInstance;
  late Box _promptsBoxInstance;
  late Box _modelsBoxInstance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // 缓存 app_settings（同步访问）
  Map<String, dynamic>? _cachedAppSettings;

  Future<void> init() async {
    _log.info('开始初始化存储服务');
    try {
      await Hive.initFlutter();
      _conversationsBoxInstance = await Hive.openBox(_conversationsBox);
      _settingsBoxInstance = await Hive.openBox(_settingsBox);
      _groupsBoxInstance = await Hive.openBox(_groupsBox);
      _promptsBoxInstance = await Hive.openBox(_promptsBox);
      _modelsBoxInstance = await Hive.openBox(_modelsBox);

      // 迁移 Hive 中的 app_settings 到 SecureStorage（如果存在）
      await _migrateAppSettings();

      // 加载 app_settings 到缓存
      await _loadAppSettingsCache();

      _log.info('存储初始化成功', {
        'conversationsCount': _conversationsBoxInstance.length,
        'settingsCount': _settingsBoxInstance.length,
        'groupsCount': _groupsBoxInstance.length,
        'promptsCount': _promptsBoxInstance.length,
        'modelsCount': _modelsBoxInstance.length,
      });

      if (kDebugMode) {
        print('存储初始化成功');
        print('  对话数: ${_conversationsBoxInstance.length}');
        print('  设置数: ${_settingsBoxInstance.length}');
        print('  分组数: ${_groupsBoxInstance.length}');
        print('  提示词模板数: ${_promptsBoxInstance.length}');
        print('  模型数: ${_modelsBoxInstance.length}');
      }
    } catch (e, stack) {
      _log.error('存储初始化失败: ${e.toString()}', e, stack);
      if (kDebugMode) {
        print('存储初始化失败: $e');
        print('堆栈: $stack');
      }
      rethrow;
    }
  }

  // 加载 app_settings 到缓存
  Future<void> _loadAppSettingsCache() async {
    try {
      final settingsJson = await _secureStorage.read(key: 'app_settings');
      if (settingsJson != null) {
        _cachedAppSettings = jsonDecode(settingsJson) as Map<String, dynamic>;
        _log.debug('app_settings 已加载到缓存');
      }
    } catch (e) {
      _log.warning('app_settings 加载失败', {'error': e});
    }
  }

  // 迁移 app_settings 从 Hive 到 SecureStorage
  Future<void> _migrateAppSettings() async {
    try {
      // 检查 SecureStorage 中是否已经有设置
      final secureSettings = await _secureStorage.read(key: 'app_settings');
      if (secureSettings != null) {
        _log.debug('SecureStorage 中已有设置，跳过迁移');
        return;
      }

      // 从 Hive 读取设置
      final hiveSettings = _settingsBoxInstance.get('app_settings');
      if (hiveSettings != null) {
        _log.info('检测到 Hive 中的设置，开始迁移到 SecureStorage');
        // 将设置转换为 JSON 字符串
        final settingsJson = hiveSettings is String
            ? hiveSettings
            : jsonEncode(hiveSettings);

        // 保存到 SecureStorage
        await _secureStorage.write(key: 'app_settings', value: settingsJson);
        _log.info('设置迁移完成');
      }
    } catch (e) {
      _log.warning('设置迁移失败', {'error': e});
    }
  }

  // Conversations
  Future<void> saveConversation(String id, Map<String, dynamic> data) async {
    _log.debug('保存对话', {'id': id, 'title': data['title']});
    if (kDebugMode) {
      print('saveConversation: id=$id');
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
    final count = _conversationsBoxInstance.length;
    _log.debug('读取所有对话', {'count': count});
    return _conversationsBoxInstance.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> deleteConversation(String id) async {
    _log.info('删除对话', {'id': id});
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

      // 如果是 Map 类型，需要转换为 Map<String, dynamic>
      if (value is Map && T.toString().contains('Map')) {
        return Map<String, dynamic>.from(value) as T;
      }

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
    try {
      await _secureStorage.write(
        key: 'api_config_\$id',
        value: jsonEncode(config),
      );
    } on PlatformException catch (e) {
      // iOS Keychain 错误 -25299: 项目已存在
      // 先删除再重新写入
      if (e.code == 'Unexpected security result code' &&
          e.message?.contains('-25299') == true) {
        _log.debug('Keychain 项目已存在，先删除再保存', {'id': id});
        await _secureStorage.delete(key: 'api_config_\$id');
        await _secureStorage.write(
          key: 'api_config_\$id',
          value: jsonEncode(config),
        );
      } else {
        rethrow;
      }
    }
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

  // App Settings (Secure - 持久化到 Keychain)
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      await _secureStorage.write(
        key: 'app_settings',
        value: jsonEncode(settings),
      );
      _cachedAppSettings = settings; // 更新缓存
    } on PlatformException catch (e) {
      // iOS Keychain 错误 -25299: 项目已存在
      if (e.code == 'Unexpected security result code' &&
          e.message?.contains('-25299') == true) {
        _log.debug('Keychain 项目已存在，先删除再保存');
        await _secureStorage.delete(key: 'app_settings');
        await _secureStorage.write(
          key: 'app_settings',
          value: jsonEncode(settings),
        );
        _cachedAppSettings = settings;
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>?> getAppSettings() async {
    final data = await _secureStorage.read(key: 'app_settings');
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // 同步获取缓存的 app_settings
  Map<String, dynamic>? getCachedAppSettings() {
    return _cachedAppSettings;
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

  // Clear all data
  Future<void> clearAll() async {
    try {
      if (kDebugMode) {
        print('clearAll: 开始清除对话数据');
        print('  对话数: ${_conversationsBoxInstance.length}');
        print('  分组数: ${_groupsBoxInstance.length}');
        print('  提示词模板数: ${_promptsBoxInstance.length}');
      }

      // 只清除对话、分组和提示词模板数据，保留设置和 API 配置
      await _conversationsBoxInstance.clear();
      await _groupsBoxInstance.clear();
      await _promptsBoxInstance.clear();

      if (kDebugMode) {
        print('clearAll: 对话数据清除完成');
        print('  对话数: ${_conversationsBoxInstance.length}');
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
