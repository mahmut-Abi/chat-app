import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_config.freezed.dart';
part 'api_config.g.dart';

@freezed
class ApiConfig with _$ApiConfig {
  const factory ApiConfig({
    required String id,
    required String name,
    required String provider,
    required String baseUrl,
    required String apiKey,
    String? organization,
    @Default(true) bool isActive,
    Map<String, dynamic>? metadata,
  }) = _ApiConfig;

  factory ApiConfig.fromJson(Map<String, dynamic> json) =>
      _$ApiConfigFromJson(json);
}

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('system') String themeMode,
    @Default('en') String language,
    @Default(14.0) double fontSize,
    @Default(true) bool enableMarkdown,
    @Default(true) bool enableCodeHighlight,
    @Default(false) bool enableLatex,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
