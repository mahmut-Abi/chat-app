import 'package:json_annotation/json_annotation.dart';

part 'agent_tool.g.dart';

/// Agent 工具定义
@JsonSerializable()
class AgentTool {
  final String id;
  final String name;
  final String description;
  final AgentToolType type;
  final Map<String, dynamic> parameters;
  final bool enabled;
  final String? iconName;

  AgentTool({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.parameters = const {},
    this.enabled = true,
    this.iconName,
  });

  factory AgentTool.fromJson(Map<String, dynamic> json) =>
      _$AgentToolFromJson(json);

  Map<String, dynamic> toJson() => _$AgentToolToJson(this);
}

/// 工具类型
enum AgentToolType {
  search, // 网络搜索
  codeExecution, // 代码执行
  fileOperation, // 文件操作
  calculator, // 计算器
  custom, // 自定义
}

/// 工具执行结果
@JsonSerializable()
class ToolExecutionResult {
  final bool success;
  final String? result;
  final String? error;
  final Map<String, dynamic>? metadata;

  ToolExecutionResult({
    required this.success,
    this.result,
    this.error,
    this.metadata,
  });

  factory ToolExecutionResult.fromJson(Map<String, dynamic> json) =>
      _$ToolExecutionResultFromJson(json);

  Map<String, dynamic> toJson() => _$ToolExecutionResultToJson(this);
}

/// Agent 配置
@JsonSerializable()
class AgentConfig {
  final String id;
  final String name;
  final String? description;
  final List<String> toolIds;
  final String? systemPrompt;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBuiltIn; // 是否为内置 Agent
  final String? iconName; // 图标名称

  AgentConfig({
    required this.id,
    required this.name,
    this.description,
    required this.toolIds,
    this.systemPrompt,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.isBuiltIn = false,
    this.iconName,
  });

  factory AgentConfig.fromJson(Map<String, dynamic> json) =>
      _$AgentConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AgentConfigToJson(this);

  AgentConfig copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? toolIds,
    String? systemPrompt,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBuiltIn,
    String? iconName,
  }) {
    return AgentConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      toolIds: toolIds ?? this.toolIds,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      iconName: iconName ?? this.iconName,
    );
  }
}
