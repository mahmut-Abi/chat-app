import '../domain/api_config.dart';
import '../../../core/storage/storage_service.dart';
import 'package:uuid/uuid.dart';

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
    await _storage.saveSetting('app_settings', settings.toJson());
  }

  AppSettings getSettings() {
    final data = _storage.getSetting<Map<String, dynamic>>('app_settings');
    if (data == null) return const AppSettings();
    return AppSettings.fromJson(data);
  }

  Future<void> updateThemeMode(String themeMode) async {
    final settings = getSettings();
    final updated = settings.copyWith(themeMode: themeMode);
    await saveSettings(updated);
  }

  Future<void> updateLanguage(String language) async {
    final settings = getSettings();
    final updated = settings.copyWith(language: language);
    await saveSettings(updated);
  }

  Future<void> updateFontSize(double fontSize) async {
    final settings = getSettings();
    final updated = settings.copyWith(fontSize: fontSize);
    await saveSettings(updated);
  }
}
