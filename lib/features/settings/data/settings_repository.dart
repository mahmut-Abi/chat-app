import '../domain/api_config.dart';
import '../../../core/storage/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class SettingsRepository {
  final StorageService _storage;
  final _uuid = const Uuid();

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

    await _storage.saveApiConfig(config.id, config.toJson());
    return config;
  }

  Future<void> saveApiConfig(ApiConfig config) async {
    await _storage.saveApiConfig(config.id, config.toJson());
  }

  Future<ApiConfig?> getApiConfig(String id) async {
    final data = await _storage.getApiConfig(id);
    if (data == null) return null;
    return ApiConfig.fromJson(data);
  }

  Future<List<ApiConfig>> getAllApiConfigs() async {
    final configs = await _storage.getAllApiConfigs();
    return configs.map((data) => ApiConfig.fromJson(data)).toList();
  }

  Future<ApiConfig?> getActiveApiConfig() async {
    final configs = await getAllApiConfigs();
    return configs.where((c) => c.isActive).firstOrNull;
  }

  Future<void> setActiveApiConfig(String id) async {
    final configs = await getAllApiConfigs();

    for (final config in configs) {
      final updated = config.copyWith(isActive: config.id == id);
      await saveApiConfig(updated);
    }
  }

  Future<void> deleteApiConfig(String id) async {
    await _storage.deleteApiConfig(id);
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
    final config = await getApiConfig(id);
    if (config != null) {
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
    }
  }

  // App Settings
  Future<void> saveSettings(AppSettings settings) async {
    if (kDebugMode) {
      print('saveSettings: ${settings.toJson()}');
    }
    await _storage.saveSetting('app_settings', settings.toJson());
  }

  AppSettings getSettings() {
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
      return const AppSettings();
    }
  }
}
