import '../domain/agent_tool.dart';
import 'dart:async';
import 'tools/calculator_tool.dart';
import 'tools/search_tool.dart';
import 'tools/file_operation_tool.dart';

/// 工具执行器基类
abstract class ToolExecutor {
  AgentToolType get type;

  Future<ToolExecutionResult> execute(
    AgentTool tool,
    Map<String, dynamic> input,
  );
}

/// 工具执行器管理器
/// 负责管理和执行所有工具
class ToolExecutorManager {
  final Map<AgentToolType, ToolExecutor> _executors = {};

  ToolExecutorManager() {
    // 注册内置工具执行器
    _registerBuiltInTools();
  }

  /// 注册内置工具
  void _registerBuiltInTools() {
    registerExecutor(EnhancedCalculatorTool());
    registerExecutor(EnhancedSearchTool());
    registerExecutor(FileOperationTool());
  }

  /// 注册自定义工具执行器
  void registerExecutor(ToolExecutor executor) {
    _executors[executor.type] = executor;
  }

  /// 执行工具
  Future<ToolExecutionResult> execute(
    AgentTool tool,
    Map<String, dynamic> input,
  ) async {
    final executor = _executors[tool.type];
    if (executor == null) {
      return ToolExecutionResult(
        success: false,
        error: '未找到工具执行器: \${tool.type}',
      );
    }

    return executor.execute(tool, input);
  }

  /// 获取所有已注册的工具类型
  List<AgentToolType> getRegisteredToolTypes() {
    return _executors.keys.toList();
  }
}
