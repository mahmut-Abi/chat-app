import 'dart:async';
import '../domain/agent_tool.dart';
import 'agent_repository.dart';
import '../../chat/domain/function_call.dart';
import '../../mcp/data/mcp_tool_integration.dart';
import '../../../core/services/log_service.dart';
import 'dart:convert';
import 'tool_definitions_service.dart';

/// 统一工具服务
/// 整合 Agent 工具和 MCP 工具，提供统一的调用接口
class UnifiedToolService {
  final AgentRepository _agentRepository;
  final McpToolIntegration _mcpIntegration;
  final _log = LogService();

  // 工具定义缓存
  final Map<String, List<ToolDefinition>> _toolCache = {};
  DateTime? _lastCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  UnifiedToolService(this._agentRepository, this._mcpIntegration);

  /// 清除缓存
  void clearCache() {
    _toolCache.clear();
    _lastCacheTime = null;
    // MCP integration cache clearing handled separately
    _log.debug('工具缓存已清除');
  }

  /// 检查缓存是否过期
  bool _isCacheExpired() {
    if (_lastCacheTime == null) return true;
    return DateTime.now().difference(_lastCacheTime!) > _cacheDuration;
  }

  /// 获取 Agent 的所有可用工具定义（Agent 工具 + MCP 工具）
  Future<List<ToolDefinition>> getToolDefinitions(
    AgentConfig agent, {
    bool includeAgentTools = true,
    bool includeMcpTools = true,
    bool useCache = true,
  }) async {
    final cacheKey = '${agent.id}_${includeAgentTools}_$includeMcpTools';

    // 检查缓存
    if (useCache && _toolCache.containsKey(cacheKey) && !_isCacheExpired()) {
      _log.debug('使用缓存的工具定义', {'agentId': agent.id});
      return _toolCache[cacheKey]!;
    }

    _log.info('获取统一工具定义', {
      'agentId': agent.id,
      'agentName': agent.name,
      'includeAgentTools': includeAgentTools,
      'includeMcpTools': includeMcpTools,
    });

    final definitions = <ToolDefinition>[];

    // 添加 Agent 工具
    if (includeAgentTools) {
      try {
        final agentTools = await _getAgentToolDefinitions(agent);
        definitions.addAll(agentTools);
        _log.info('Agent 工具已添加', {'count': agentTools.length});
      } catch (e) {
        _log.error('获取 Agent 工具失败', e);
      }
    }

    // 添加 MCP 工具
    if (includeMcpTools) {
      try {
        final mcpTools = await _mcpIntegration.getAllMcpToolDefinitions();
        definitions.addAll(mcpTools);
        _log.info('MCP 工具已添加', {'count': mcpTools.length});
      } catch (e) {
        _log.error('获取 MCP 工具失败', e);
      }
    }

    _log.info('工具定义已构建', {'totalCount': definitions.length});

    // 存入缓存
    _toolCache[cacheKey] = definitions;
    _lastCacheTime = DateTime.now();

    return definitions;
  }

  /// 获取 Agent 工具定义
  Future<List<ToolDefinition>> _getAgentToolDefinitions(
    AgentConfig agent,
  ) async {
    final allTools = await _agentRepository.getAllTools();
    final tools = allTools.where((t) => agent.toolIds.contains(t.id)).toList();
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

    return definitions;
  }

  /// 执行工具调用
  Future<ToolExecutionResult> executeTool(
    ToolCall toolCall,
    AgentConfig agent,
  ) async {
    _log.info('执行工具调用', {
      'toolName': toolCall.function.name,
      'agentId': agent.id,
    });

    try {
      // 解析参数
      final Map<String, dynamic> arguments;
      try {
        arguments = jsonDecode(toolCall.function.arguments);
      } catch (e) {
        return ToolExecutionResult(
          success: false,
          error: '无效的工具参数: ${e.toString()}',
        );
      }

      // 先尝试作为 Agent 工具执行
      final agentToolResult = await _tryExecuteAgentTool(
        toolCall.function.name,
        arguments,
        agent,
      );

      if (agentToolResult != null) {
        return agentToolResult;
      }

      // 再尝试作为 MCP 工具执行
      final mcpToolResult = await _tryExecuteMcpTool(
        toolCall.function.name,
        arguments,
      );

      if (mcpToolResult != null) {
        return mcpToolResult;
      }

      // 未找到工具
      return ToolExecutionResult(
        success: false,
        error: '未找到工具: ${toolCall.function.name}',
      );
    } catch (e) {
      _log.error('工具执行异常', e);
      return ToolExecutionResult(
        success: false,
        error: '执行失败: ${e.toString()}',
      );
    }
  }

  /// 尝试执行 Agent 工具
  Future<ToolExecutionResult?> _tryExecuteAgentTool(
    String toolName,
    Map<String, dynamic> arguments,
    AgentConfig agent,
  ) async {
    try {
      final allTools = await _agentRepository.getAllTools();
      final tools = allTools
          .where((t) => agent.toolIds.contains(t.id))
          .toList();
      final tool = tools.where((t) => t.name == toolName).firstOrNull;

      if (tool == null) return null;

      _log.info('执行 Agent 工具', {'toolName': toolName});
      return await _agentRepository.executeTool(tool, arguments);
    } catch (e) {
      _log.error('Agent 工具执行失败', e);
      return ToolExecutionResult(
        success: false,
        error: '执行失败: ${e.toString()}',
      );
    }
  }

  /// 尝试执行 MCP 工具
  Future<ToolExecutionResult?> _tryExecuteMcpTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    try {
      // 查找对应的 MCP 配置
      final mcpConfigId = await _mcpIntegration.findMcpConfigForTool(toolName);

      if (mcpConfigId == null) return null;

      _log.info('执行 MCP 工具', {
        'toolName': toolName,
        'mcpConfigId': mcpConfigId,
      });
      return await _mcpIntegration.executeMcpTool(
        mcpConfigId,
        toolName,
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

  /// 批量执行工具调用
  Future<List<ToolExecutionResult>> executeToolCalls(
    List<ToolCall> toolCalls,
    AgentConfig agent,
  ) async {
    _log.info('批量执行工具调用', {'count': toolCalls.length});

    final results = <ToolExecutionResult>[];

    for (final toolCall in toolCalls) {
      final result = await executeTool(toolCall, agent);
      results.add(result);
    }

    return results;
  }

  /// 构建工具结果消息
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
        'content': result != null && result.success
            ? (result.result ?? '执行成功')
            : (result?.error ?? '执行失败'),
      });
    }

    return messages;
  }

  /// 格式化工具结果
  String formatToolResults(List<ToolExecutionResult> results) {
    if (results.isEmpty) return '';

    final buffer = StringBuffer();

    for (var i = 0; i < results.length; i++) {
      final result = results[i];

      if (result.success) {
        buffer.writeln('✅ 工具执行成功');
        if (result.result != null && result.result!.isNotEmpty) {
          buffer.writeln(result.result);
        }
      } else {
        buffer.writeln('❌ 工具执行失败');
        if (result.error != null) {
          buffer.writeln('错误: ${result.error}');
        }
      }

      if (i < results.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// 获取默认参数定义
  Map<String, dynamic> _getDefaultParameters(AgentToolType type) {
    return ToolDefinitionsService.getDefaultParameters(type);
  }
}
