import 'package:json_annotation/json_annotation.dart';

part 'function_call.g.dart';

// Function Calling 相关数据模型

@JsonSerializable()
class FunctionDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const FunctionDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  factory FunctionDefinition.fromJson(Map<String, dynamic> json) =>
      _$FunctionDefinitionFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionDefinitionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ToolDefinition {
  final String type;
  final FunctionDefinition function;

  const ToolDefinition({
    required this.type,
    required this.function,
  });

  factory ToolDefinition.fromJson(Map<String, dynamic> json) =>
      _$ToolDefinitionFromJson(json);

  Map<String, dynamic> toJson() => _$ToolDefinitionToJson(this);
}

@JsonSerializable()
class FunctionCall {
  final String name;
  final String arguments;

  const FunctionCall({
    required this.name,
    required this.arguments,
  });

  factory FunctionCall.fromJson(Map<String, dynamic> json) =>
      _$FunctionCallFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionCallToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ToolCall {
  final String id;
  final String type;
  final FunctionCall function;

  const ToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallToJson(this);
}
