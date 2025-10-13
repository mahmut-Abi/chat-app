import 'package:json_annotation/json_annotation.dart';

part 'mcp_config.g.dart';

/// MCP 服务器配置
@JsonSerializable()
class McpConfig {
  final String id;
  final String name;
  final String endpoint;
  final String? description;
  final bool enabled;
  final Map<String, dynamic>? headers;
  final Map<String, String> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  McpConfig({
    required this.id,
    required this.name,
    required this.endpoint,
    this.description,
    this.enabled = true,
    this.headers,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory McpConfig.fromJson(Map<String, dynamic> json) =>
      _$McpConfigFromJson(json);

  Map<String, dynamic> toJson() => _$McpConfigToJson(this);

  McpConfig copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? description,
    bool? enabled,
    Map<String, dynamic>? headers,
    Map<String, String>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return McpConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      headers: headers ?? this.headers,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// MCP 上下文提供者
@JsonSerializable()
class McpContextProvider {
  final String id;
  final String name;
  final String type;
  final String? description;
  final bool enabled;
  final Map<String, dynamic>? config;

  McpContextProvider({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.enabled = true,
    this.config,
  });

  factory McpContextProvider.fromJson(Map<String, dynamic> json) =>
      _$McpContextProviderFromJson(json);

  Map<String, dynamic> toJson() => _$McpContextProviderToJson(this);
}

/// MCP 连接状态
enum McpConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}
