import 'mcp_repository.dart';
import 'mcp_client_base.dart';
import '../../../core/services/log_service.dart';

/// MCP 工具服务 - 获取和管理 MCP 工具
class McpToolsService {
  final McpRepository _repository;
  final _log = LogService();

  McpToolsService(this._repository);

  /// 获取指定配置的工具列表
  Future<List<Map<String, dynamic>>> getToolsForConfig(
    String configId,
  ) async {
    _log.info('获取 MCP 工具列表', {'configId': configId});
    try {
      final client = _repository.getClient(configId);
      if (client == null) {
        _log.warning('MCP 客户端未连接', {'configId': configId});
        return [];
      }

      final tools = await client.listTools();
      if (tools == null) {
        _log.warning('工具列表为空', {'configId': configId});
        return [];
      }

      _log.info('成功获取 MCP 工具', {
        'configId': configId,
        'count': tools.length,
      });
      return tools;
    } catch (e) {
      _log.error('获取工具列表失败', e);
      return [];
    }
  }

  /// 获取所有已连接配置的工具列表
  Future<List<McpToolWithConfig>> getAllToolsWithConfig() async {
    _log.info('获取所有 MCP 工具列表');
    try {
      final configs = await _repository.getAllConfigs();
      final allTools = <McpToolWithConfig>[];

      for (final config in configs) {
        if (config.enabled) {
          final tools = await getToolsForConfig(config.id);
          for (final tool in tools) {
            allTools.add(McpToolWithConfig(
              configId: config.id,
              configName: config.name,
              tool: tool,
            ));
          }
        }
      }

      _log.info('成功获取所有工具', {'count': allTools.length});
      return allTools;
    } catch (e) {
      _log.error('获取所有工具列表失败', e);
      return [];
    }
  }

  /// 搜索工具
  Future<List<Map<String, dynamic>>> searchTools(
    String configId,
    String query,
  ) async {
    _log.info('搜索工具', {'configId': configId, 'query': query});
    try {
      final tools = await getToolsForConfig(configId);
      final lowercaseQuery = query.toLowerCase();

      return tools
          .where((tool) {
            final name = (tool['name'] as String? ?? '').toLowerCase();
            final description =
                (tool['description'] as String? ?? '').toLowerCase();
            return name.contains(lowercaseQuery) ||
                description.contains(lowercaseQuery);
          })
          .toList();
    } catch (e) {
      _log.error('搜索工具失败', e);
      return [];
    }
  }
}

/// MCP 工具及其对应的配置
class McpToolWithConfig {
  final String configId;
  final String configName;
  final Map<String, dynamic> tool;

  McpToolWithConfig({
    required this.configId,
    required this.configName,
    required this.tool,
  });

  String get toolName => tool['name'] as String? ?? 'Unknown';
  String get toolDescription => tool['description'] as String? ?? '';
  Map<String, dynamic> get toolParameters =>
      tool['parameters'] as Map<String, dynamic>? ?? {};
}
