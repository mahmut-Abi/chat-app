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

  // 模型参数配置
  final String defaultModel;
  final double temperature;
  final int maxTokens;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;

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
    this.defaultModel = 'gpt-3.5-turbo',
    this.temperature = 0.7,
    this.maxTokens = 2000,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
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
    String? defaultModel,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
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
      defaultModel: defaultModel ?? this.defaultModel,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
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
    defaultModel,
    temperature,
    maxTokens,
    topP,
    frequencyPenalty,
    presencePenalty,
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
  final String? themeColor;
  final int? customThemeColor;
  final String? backgroundImage; // 背景图片路径 (assets 或自定义路径)
  final double backgroundOpacity; // 背景透明度 0.0-1.0

  const AppSettings({
    this.themeMode = 'system',
    this.language = 'en',
    this.fontSize = 14.0,
    this.enableMarkdown = true,
    this.enableCodeHighlight = true,
    this.enableLatex = false,
    this.themeColor,
    this.customThemeColor,
    this.backgroundImage,
    this.backgroundOpacity = 0.8, // 20% 透明
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
    String? themeColor,
    int? customThemeColor,
    String? backgroundImage,
    bool clearBackgroundImage = false,
    double? backgroundOpacity,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      fontSize: fontSize ?? this.fontSize,
      enableMarkdown: enableMarkdown ?? this.enableMarkdown,
      enableCodeHighlight: enableCodeHighlight ?? this.enableCodeHighlight,
      enableLatex: enableLatex ?? this.enableLatex,
      themeColor: themeColor ?? this.themeColor,
      customThemeColor: customThemeColor ?? this.customThemeColor,
      backgroundImage: clearBackgroundImage
          ? null
          : (backgroundImage ?? this.backgroundImage),
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
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
    themeColor,
    customThemeColor,
    backgroundImage,
    backgroundOpacity,
  ];
}
