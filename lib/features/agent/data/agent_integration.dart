import '../domain/agent_tool.dart';
import 'agent_repository.dart';
import 'tool_executor.dart';
import '../../chat/domain/message.dart';

/// Agent 与聊天功能集成
class AgentIntegration {
  final AgentRepository _repository;
  final ToolExecutorManager _executorManager;

  AgentIntegration(this._repository, this._executorManager);

  /// 处理带 Agent 的消息
  Future<Message> processMessageWithAgent(
    Message userMessage,
    AgentConfig agent,
  ) async {
    // 获取 Agent 的工具
    final tools = await _getAgentTools(agent);

    // 检查消息中是否需要调用工具
    final toolCalls = _extractToolCalls(userMessage.content);

    if (toolCalls.isEmpty) {
      return userMessage;
    }

    // 执行工具调用
    final results = await _executeToolCalls(toolCalls, tools);

    // 构建带工具结果的消息
    final enrichedContent = _buildEnrichedContent(userMessage.content, results);

    return userMessage.copyWith(content: enrichedContent);
  }

  /// 获取 Agent 的工具列表
  Future<List<AgentTool>> _getAgentTools(AgentConfig agent) async {
    final allTools = await _repository.getAllTools();
    return allTools.where((tool) => agent.toolIds.contains(tool.id)).toList();
  }

  /// 提取工具调用
  List<Map<String, dynamic>> _extractToolCalls(String content) {
    // 简单的工具调用解析
    // 实际应用中应该使用 AI 模型的 function calling 功能
    final calls = <Map<String, dynamic>>[];

    // 示例：检测类似 "@calculator 1+1" 的模式
    final calculatorPattern = RegExp(r'@calculator\s+(.+)');
    final match = calculatorPattern.firstMatch(content);

    if (match != null) {
      calls.add({
        'tool': 'calculator',
        'input': {'expression': match.group(1)},
      });
    }

    return calls;
  }

  /// 执行工具调用
  Future<List<ToolExecutionResult>> _executeToolCalls(
    List<Map<String, dynamic>> toolCalls,
    List<AgentTool> availableTools,
  ) async {
    final results = <ToolExecutionResult>[];

    for (final call in toolCalls) {
      final toolName = call['tool'] as String;
      final input = call['input'] as Map<String, dynamic>;

      // 查找对应的工具
      final tool = availableTools.firstWhere(
        (t) => t.name.toLowerCase() == toolName.toLowerCase(),
        orElse: () => throw Exception('未找到工具: $toolName'),
      );

      // 执行工具
      final result = await _repository.executeTool(tool, input);
      results.add(result);
    }

    return results;
  }

  /// 构建带工具结果的消息内容
  String _buildEnrichedContent(
    String originalContent,
    List<ToolExecutionResult> results,
  ) {
    final buffer = StringBuffer(originalContent);
    buffer.writeln('\n\n---\n**工具执行结果:**\n');

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('\n${i + 1}. ');

      if (result.success) {
        buffer.writeln('✅ 执行成功');
        if (result.result != null) {
          buffer.writeln('```\n${result.result}\n```');
        }
      } else {
        buffer.writeln('❌ 执行失败');
        if (result.error != null) {
          buffer.writeln('**错误**: ${result.error}');
        }
      }
    }

    return buffer.toString();
  }
}
