import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'api_config.g.dart';

@JsonSerializable()
class ApiConfig extends Equatable {
  final String id;
  final String name;
  final String provider;
  final String baseUrl;
  final String apiKey;
  final String? organization;
  final String? proxyUrl;
  final String? proxyUsername;
  final String? proxyPassword;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const ApiConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    this.organization,
    this.proxyUrl,
    this.proxyUsername,
    this.proxyPassword,
    this.isActive = true,
    this.metadata,
  });

  factory ApiConfig.fromJson(Map<String, dynamic> json) =>
      _$ApiConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ApiConfigToJson(this);

  ApiConfig copyWith({
    String? id,
    String? name,
    String? provider,
    String? baseUrl,
    String? apiKey,
    String? organization,
    String? proxyUrl,
    String? proxyUsername,
    String? proxyPassword,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      organization: organization ?? this.organization,
      proxyUrl: proxyUrl ?? this.proxyUrl,
      proxyUsername: proxyUsername ?? this.proxyUsername,
      proxyPassword: proxyPassword ?? this.proxyPassword,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        provider,
        baseUrl,
        apiKey,
        organization,
        proxyUrl,
        proxyUsername,
        proxyPassword,
        isActive,
        metadata,
      ];
}

@JsonSerializable()
class AppSettings extends Equatable {
  final String themeMode;
  final String language;
  final double fontSize;
  final bool enableMarkdown;
  final bool enableCodeHighlight;
  final bool enableLatex;

  const AppSettings({
    this.themeMode = 'system',
    this.language = 'en',
    this.fontSize = 14.0,
    this.enableMarkdown = true,
    this.enableCodeHighlight = true,
    this.enableLatex = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  AppSettings copyWith({
    String? themeMode,
    String? language,
    double? fontSize,
    bool? enableMarkdown,
    bool? enableCodeHighlight,
    bool? enableLatex,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      fontSize: fontSize ?? this.fontSize,
      enableMarkdown: enableMarkdown ?? this.enableMarkdown,
      enableCodeHighlight: enableCodeHighlight ?? this.enableCodeHighlight,
      enableLatex: enableLatex ?? this.enableLatex,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        language,
        fontSize,
        enableMarkdown,
        enableCodeHighlight,
        enableLatex,
      ];
}
