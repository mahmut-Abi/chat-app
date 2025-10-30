import '../domain/mcp_config.dart';
import 'mcp_repository.dart';
import '../../agent/domain/agent_tool.dart';
import '../../chat/domain/function_call.dart';
import '../../../core/services/log_service.dart';
import 'dart:convert';

/// MCP 工具与 Agent 系统集成
class McpToolIntegration {
  final McpRepository _repository;
  final _log = LogService();

  McpToolIntegration(this._repository);

  /// 将 MCP 工具转换为 Agent 工具定义
  Future<List<ToolDefinition>> getMcpToolDefinitions(String mcpConfigId) async {
    _log.info('获取 MCP 工具定义', {'mcpConfigId': mcpConfigId});

    final client = _repository.getClient(mcpConfigId);
    if (client == null) {
      _log.warning('MCP 客户端未连接', {'mcpConfigId': mcpConfigId});
      return [];
    }

    try {
      final mcpTools = await client.listTools();
      if (mcpTools == null) {
        _log.warning('获取 MCP 工具列表失败');
        return [];
      }

      final toolDefinitions = <ToolDefinition>[];
      for (final mcpTool in mcpTools) {
        toolDefinitions.add(_convertMcpToolToDefinition(mcpTool));
      }

      _log.info('成功转换 MCP 工具', {'count': toolDefinitions.length});
      return toolDefinitions;
    } catch (e) {
      _log.error('获取 MCP 工具失败', e);
      return [];
    }
  }

  /// 执行 MCP 工具
  Future<ToolExecutionResult> executeMcpTool(
    String mcpConfigId,
    String toolName,
    Map<String, dynamic> parameters,
  ) async {
    _log.info('执行 MCP 工具', {
      'mcpConfigId': mcpConfigId,
      'toolName': toolName,
      'parametersKeys': parameters.keys.toList(),
    });

    final client = _repository.getClient(mcpConfigId);
    if (client == null) {
      _log.warning('MCP 客户端未连接');
      return ToolExecutionResult(success: false, error: 'MCP 客户端未连接');
    }

    try {
      final result = await client.callTool(toolName, parameters);
      if (result == null) {
        return ToolExecutionResult(success: false, error: '工具执行返回空结果');
      }

      _log.info('MCP 工具执行成功', {'toolName': toolName});

      return ToolExecutionResult(
        success: true,
        result: _formatToolResult(result),
        metadata: result,
      );
    } catch (e) {
      _log.error('MCP 工具执行失败', e);
      return ToolExecutionResult(
        success: false,
        error: '执行失败: ${e.toString()}',
      );
    }
  }

  /// 将 MCP 工具转换为 Function Definition
  ToolDefinition _convertMcpToolToDefinition(Map<String, dynamic> mcpTool) {
    // 确保参数定义的格式完整
    var parameters = mcpTool['parameters'] as Map<String, dynamic>? ?? {};
    
    // 如果参数为空，使用默认的空对象参数定义
    if (parameters.isEmpty) {
      parameters = {
        'type': 'object',
        'properties': {},
        'required': [],
      };
    }
    
    // 确保参数有type字段
    if (!parameters.containsKey('type')) {
      parameters = {
        'type': 'object',
        ...parameters,
      };
    }
    
    // 规范化工具名称
    final toolName = (mcpTool['name'] as String? ?? 'unknown').trim();
    
    return ToolDefinition(
      type: 'function',
      function: FunctionDefinition(
        name: toolName,
        description: mcpTool['description'] as String? ?? '',
        parameters: parameters,
      ),
    );
  }

  /// 格式化工具执行结果
  String _formatToolResult(Map<String, dynamic> result) {
    try {
      // 如果结果有特定格式，按格式输出
      if (result.containsKey('content')) {
        return result['content'].toString();
      }

      // 否则输出 JSON
      return jsonEncode(result);
    } catch (e) {
      return result.toString();
    }
  }

  /// 获取所有启用的 MCP 配置
  Future<List<McpConfig>> getEnabledMcpConfigs() async {
    final configs = await _repository.getAllConfigs();
    return configs.where((c) => c.enabled).toList();
  }

  /// 批量获取多个 MCP 服务器的工具
  Future<List<ToolDefinition>> getAllMcpToolDefinitions() async {
    _log.info('获取所有 MCP 工具');

    final configs = await getEnabledMcpConfigs();
    final allTools = <ToolDefinition>[];

    for (final config in configs) {
      final tools = await getMcpToolDefinitions(config.id);
      allTools.addAll(tools);
    }

    _log.info('成功获取所有 MCP 工具', {'count': allTools.length});
    return allTools;
  }

  /// 根据工具名称查找对应的 MCP 配置
  Future<String?> findMcpConfigForTool(String toolName) async {
    final configs = await getEnabledMcpConfigs();

    for (final config in configs) {
      final client = _repository.getClient(config.id);
      if (client == null) continue;

      try {
        final tools = await client.listTools();
        if (tools == null) continue;

        final hasTool = tools.any((t) => t['name'] == toolName);
        if (hasTool) {
          return config.id;
        }
      } catch (e) {
        _log.error('查找工具失败', e);
      }
    }

    return null;
  }
}
