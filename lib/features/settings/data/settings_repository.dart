import '../domain/api_config.dart';
import '../../../core/storage/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/log_service.dart';

class SettingsRepository {
  final StorageService _storage;
  final _uuid = const Uuid();
  final _log = LogService();

  SettingsRepository(this._storage);

  // API Config Management
  Future<ApiConfig> createApiConfig({
    required String name,
    required String provider,
    required String baseUrl,
    required String apiKey,
    String? organization,
    String? proxyUrl,
    String? proxyUsername,
    String? proxyPassword,
    String? defaultModel,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
  }) async {
    _log.debug('开始创建 API 配置', {
      'name': name,
      'provider': provider,
      'baseUrl': baseUrl,
      'hasOrganization': organization != null,
      'hasProxy': proxyUrl != null,
      'defaultModel': defaultModel,
    });

    final config = ApiConfig(
      id: _uuid.v4(),
      name: name,
      provider: provider,
      baseUrl: baseUrl,
      apiKey: apiKey,
      organization: organization,
      proxyUrl: proxyUrl,
      proxyUsername: proxyUsername,
      proxyPassword: proxyPassword,
      isActive: true,
      defaultModel: defaultModel ?? 'gpt-3.5-turbo',
      temperature: temperature ?? 0.7,
      maxTokens: maxTokens ?? 2000,
      topP: topP ?? 1.0,
      frequencyPenalty: frequencyPenalty ?? 0.0,
      presencePenalty: presencePenalty ?? 0.0,
    );

    _log.info('API 配置创建成功', {'configId': config.id, 'name': name});
    await _storage.saveApiConfig(config.id, config.toJson());
    _log.debug('API 配置已保存到存储', {'configId': config.id});
    return config;
  }

  Future<void> saveApiConfig(ApiConfig config) async {
    _log.debug('保存 API 配置', {'configId': config.id, 'name': config.name});
    await _storage.saveApiConfig(config.id, config.toJson());
  }

  Future<ApiConfig?> getApiConfig(String id) async {
    _log.debug('获取 API 配置', {'configId': id});
    final data = await _storage.getApiConfig(id);
    if (data == null) {
      _log.debug('API 配置不存在', {'configId': id});
      return null;
    }
    _log.debug('API 配置已找到', {'configId': id});
    return ApiConfig.fromJson(data);
  }

  Future<List<ApiConfig>> getAllApiConfigs() async {
    _log.debug('获取所有 API 配置');
    final configs = await _storage.getAllApiConfigs();
    _log.info('获取到 API 配置列表', {'count': configs.length});
    return configs.map((data) => ApiConfig.fromJson(data)).toList();
  }

  Future<ApiConfig?> getActiveApiConfig() async {
    _log.debug('获取活动 API 配置');
    final configs = await getAllApiConfigs();
    final activeConfig = configs.where((c) => c.isActive).firstOrNull;
    if (activeConfig != null) {
      _log.info('找到活动 API 配置', {
        'configId': activeConfig.id,
        'name': activeConfig.name,
      });
    } else {
      _log.warning('未找到活动 API 配置');
    }
    return activeConfig;
  }

  Future<void> setActiveApiConfig(String id) async {
    _log.info('设置活动 API 配置', {'configId': id});
    final configs = await getAllApiConfigs();
    _log.debug('更新所有配置的活动状态', {'totalConfigs': configs.length});

    for (final config in configs) {
      final updated = config.copyWith(isActive: config.id == id);
      await saveApiConfig(updated);
    }
    _log.info('活动 API 配置已更新', {'configId': id});
  }

  Future<void> deleteApiConfig(String id) async {
    _log.info('删除 API 配置', {'configId': id});
    await _storage.deleteApiConfig(id);
    _log.debug('API 配置已删除', {'configId': id});
  }

  Future<void> updateApiConfig(
    String id, {
    required String name,
    required String provider,
    required String baseUrl,
    required String apiKey,
    String? organization,
    String? proxyUrl,
    String? proxyUsername,
    String? proxyPassword,
  }) async {
    _log.info('更新 API 配置', {
      'configId': id,
      'name': name,
      'provider': provider,
    });
    final config = await getApiConfig(id);
    if (config != null) {
      _log.debug('找到待更新的配置', {'configId': id});
      final updated = config.copyWith(
        name: name,
        provider: provider,
        baseUrl: baseUrl,
        apiKey: apiKey,
        organization: organization,
        proxyUrl: proxyUrl,
        proxyUsername: proxyUsername,
        proxyPassword: proxyPassword,
      );
      await saveApiConfig(updated);
      _log.info('API 配置更新成功', {'configId': id});
    } else {
      _log.warning('更新失败：配置不存在', {'configId': id});
    }
  }

  // App Settings
  Future<void> saveSettings(AppSettings settings) async {
    _log.info('保存应用设置', {
      'themeMode': settings.themeMode,
      'language': settings.language,
      'fontSize': settings.fontSize,
    });
    if (kDebugMode) {
      print('saveSettings: ${settings.toJson()}');
    }
    await _storage.saveSetting('app_settings', settings.toJson());
  }

  AppSettings getSettings() {
    _log.debug('读取应用设置');
    if (kDebugMode) {
      print('getSettings: 读取 app_settings');
    }
    try {
      final data = _storage.getSetting<Map<String, dynamic>>('app_settings');
      if (kDebugMode) {
        print('getSettings: data=$data');
      }
      if (data == null) {
        if (kDebugMode) {
          print('getSettings: 没有保存的设置，返回默认值');
        }
        return const AppSettings();
      }
      return AppSettings.fromJson(data);
    } catch (e, stack) {
      if (kDebugMode) {
        print('getSettings 错误: $e');
        print('Stack: $stack');
      }
      _log.error('读取应用设置失败', e, stack);
      return const AppSettings();
    }
  }
}
