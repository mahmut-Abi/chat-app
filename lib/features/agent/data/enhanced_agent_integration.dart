import 'dart:convert';
import 'tool_definitions_service.dart';
import '../domain/agent_tool.dart';
import 'agent_repository.dart';
import '../../chat/domain/message.dart';
import '../../chat/domain/function_call.dart';
import '../../../core/services/log_service.dart';
import '../../mcp/data/mcp_tool_integration.dart';
import 'tool_definitions_service.dart';

/// 增强的 Agent 集成服务
/// 支持 Function Calling 和工具执行
class EnhancedAgentIntegration {
  final AgentRepository _repository;
  final _log = LogService();
  final McpToolIntegration? _mcpIntegration;

  EnhancedAgentIntegration(
    this._repository, {
    McpToolIntegration? mcpIntegration,
  }) : _mcpIntegration = mcpIntegration;

  /// 获取 Agent 的工具定义（用于 API 调用）
  Future<List<ToolDefinition>> getAgentToolDefinitions(
    AgentConfig agent, {
    bool includeMcpTools = true,
  }) async {
    _log.info('获取 Agent 工具定义', {'agentId': agent.id, 'agentName': agent.name});

    final tools = await _getAgentTools(agent);
    final definitions = <ToolDefinition>[];

    for (final tool in tools) {
      if (!tool.enabled) continue;

      definitions.add(
        ToolDefinition(
          type: 'function',
          function: FunctionDefinition(
            name: tool.name,
            description: tool.description,
            parameters: tool.parameters.isNotEmpty
                ? tool.parameters
                : _getDefaultParameters(tool.type),
          ),
        ),
      );
    }

    // 添加 MCP 工具
    if (includeMcpTools && _mcpIntegration != null) {
      try {
        final mcpTools = await _mcpIntegration!.getAllMcpToolDefinitions();
        definitions.addAll(mcpTools);
        _log.debug('MCP 工具已添加', {'count': mcpTools.length});
      } catch (e) {
        _log.error('添加 MCP 工具失败', e);
      }
    }

    _log.debug('工具定义已构建', {'count': definitions.length});
    return definitions;
  }

  /// 处理工具调用响应
  Future<Message> processToolCallResponse(
    Message assistantMessage,
    AgentConfig agent,
  ) async {
    if (assistantMessage.toolCalls == null ||
        assistantMessage.toolCalls!.isEmpty) {
      return assistantMessage;
    }

    _log.info('处理工具调用', {
      'agentId': agent.id,
      'toolCallsCount': assistantMessage.toolCalls!.length,
    });

    final tools = await _getAgentTools(agent);
    final results = <ToolExecutionResult>[];

    for (final toolCall in assistantMessage.toolCalls!) {
      final result = await _executeToolCall(toolCall, tools);
      results.add(result);
    }

    // 将工具执行结果存储到 metadata
    final metadata = Map<String, dynamic>.from(assistantMessage.metadata ?? {});
    metadata['toolResults'] = results.map((r) => r.toJson()).toList();

    return assistantMessage.copyWith(metadata: metadata);
  }

  /// 构建工具结果消息列表（用于继续对话）
  List<Map<String, dynamic>> buildToolResultMessages(
    List<ToolCall> toolCalls,
    List<ToolExecutionResult> results,
  ) {
    final messages = <Map<String, dynamic>>[];

    for (var i = 0; i < toolCalls.length; i++) {
      final toolCall = toolCalls[i];
      final result = i < results.length ? results[i] : null;

      messages.add({
        'role': 'tool',
        'tool_call_id': toolCall.id,
        'content': result != null && result.success == true
            ? (result.result ?? '执行成功')
            : (result?.error ?? '执行失败'),
      });
    }

    return messages;
  }

  /// 获取 Agent 的工具列表
  Future<List<AgentTool>> _getAgentTools(AgentConfig agent) async {
    final allTools = await _repository.getAllTools();
    return allTools.where((tool) => agent.toolIds.contains(tool.id)).toList();
  }

  /// 执行单个工具调用
  Future<ToolExecutionResult> _executeToolCall(
    ToolCall toolCall,
    List<AgentTool> availableTools,
  ) async {
    try {
      _log.debug('执行工具调用', {
        'id': toolCall.id,
        'function': toolCall.function.name,
      });

      // 先尝试查找 Agent 工具
      final tool = availableTools
          .where((t) => t.name == toolCall.function.name)
          .firstOrNull;

      // 如果不是 Agent 工具，尝试使用 MCP 工具
      if (tool == null && _mcpIntegration != null) {
        return await _executeMcpTool(toolCall);
      }

      if (tool == null) {
        throw Exception('未找到工具: ${toolCall.function.name}');
      }

      // 解析参数
      final Map<String, dynamic> arguments;
      try {
        arguments = jsonDecode(toolCall.function.arguments);
      } catch (e) {
        throw Exception('无效的工具参数: ${e.toString()}');
      }

      // 执行工具
      final result = await _repository.executeTool(tool, arguments);

      _log.info('工具执行完成', {
        'tool': toolCall.function.name,
        'success': result.success,
      });

      return result;
    } catch (e, stackTrace) {
      _log.error('工具执行失败', {
        'tool': toolCall.function.name,
        'error': e.toString(),
      });

      return ToolExecutionResult(
        success: false,
        error: '执行失败: ${e.toString()}',
        metadata: {'stackTrace': stackTrace.toString()},
      );
    }
  }

  /// 执行 MCP 工具
  Future<ToolExecutionResult> _executeMcpTool(ToolCall toolCall) async {
    if (_mcpIntegration == null) {
      return ToolExecutionResult(success: false, error: 'MCP 集成未启用');
    }

    try {
      // 解析参数
      final Map<String, dynamic> arguments;
      try {
        arguments = jsonDecode(toolCall.function.arguments);
      } catch (e) {
        throw Exception('无效的工具参数: ${e.toString()}');
      }

      // 查找对应的 MCP 配置
      final mcpConfigId = await _mcpIntegration!.findMcpConfigForTool(
        toolCall.function.name,
      );

      if (mcpConfigId == null) {
        return ToolExecutionResult(
          success: false,
          error: '未找到 MCP 工具: ${toolCall.function.name}',
        );
      }

      // 执行 MCP 工具
      return await _mcpIntegration!.executeMcpTool(
        mcpConfigId,
        toolCall.function.name,
        arguments,
      );
    } catch (e) {
      _log.error('MCP 工具执行失败', e);
      return ToolExecutionResult(
        success: false,
        error: '执行失败: ${e.toString()}',
      );
    }
  }

  /// 获取默认参数定义
  Map<String, dynamic> _getDefaultParameters(AgentToolType type) {
    return ToolDefinitionsService.getDefaultParameters(type);
  }

  /// 格式化工具结果为可读文本
  String formatToolResults(List<ToolExecutionResult> results) {
    if (results.isEmpty) return '';

    final buffer = StringBuffer('\n\n---\n**工具执行结果:**\n');

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

      if (result.metadata != null && result.metadata!.isNotEmpty) {
        buffer.writeln('\n**附加信息**: ${result.metadata}');
      }
    }

    return buffer.toString();
  }
}
