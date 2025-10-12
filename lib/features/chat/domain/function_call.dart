import 'package:freezed_annotation/freezed_annotation.dart';

part 'function_call.freezed.dart';
part 'function_call.g.dart';

// Function Calling 相关数据模型

@freezed
class FunctionDefinition with _$FunctionDefinition {
  const factory FunctionDefinition({
    required String name,
    String? description,
    required Map<String, dynamic> parameters,
  }) = _FunctionDefinition;

  factory FunctionDefinition.fromJson(Map<String, dynamic> json) =>
      _$FunctionDefinitionFromJson(json);
}

@freezed
class ToolDefinition with _$ToolDefinition {
  const factory ToolDefinition({
    required String type,
    required FunctionDefinition function,
  }) = _ToolDefinition;

  factory ToolDefinition.fromJson(Map<String, dynamic> json) =>
      _$ToolDefinitionFromJson(json);
}

@freezed
class FunctionCall with _$FunctionCall {
  const factory FunctionCall({
    required String name,
    required String arguments,
  }) = _FunctionCall;

  factory FunctionCall.fromJson(Map<String, dynamic> json) =>
      _$FunctionCallFromJson(json);
}

@freezed
class ToolCall with _$ToolCall {
  const factory ToolCall({
    required String id,
    required String type,
    required FunctionCall function,
  }) = _ToolCall;

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);
}

// 内置工具的定义
class BuiltInTools {
  // 获取当前时间
  static ToolDefinition get currentTime => const ToolDefinition(
    type: 'function',
    function: FunctionDefinition(
      name: 'get_current_time',
      description: '获取当前的日期和时间',
      parameters: {'type': 'object', 'properties': {}},
    ),
  );

  // 计算器
  static ToolDefinition get calculator => const ToolDefinition(
    type: 'function',
    function: FunctionDefinition(
      name: 'calculate',
      description: '执行数学计算',
      parameters: {
        'type': 'object',
        'properties': {
          'expression': {'type': 'string', 'description': '要计算的数学表达式'},
        },
        'required': ['expression'],
      },
    ),
  );

  // 获取所有内置工具
  static List<ToolDefinition> get all => [currentTime, calculator];
}
