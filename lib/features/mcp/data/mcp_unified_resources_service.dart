import 'mcp_repository.dart';
import 'mcp_resources_client.dart';
import '../../../core/services/log_service.dart';

/// MCP 箱统资源服务 - 一个统一的接口获取所有 MCP 资源
class McpUnifiedResourcesService {
  final McpRepository _repository;
  final _log = LogService();

  McpUnifiedResourcesService(this._repository);

  /// 获取指定配置的所有资源
  Future<MCPAllResources> getAllResources(String configId) async {
    _log.info('获取所有 MCP 资源', {'configId': configId});
    try {
      final client = _repository.getClient(configId);
      if (client == null) {
        _log.warning('MCP 客户端未连接', {'configId': configId});
        return MCPAllResources(
          tools: [],
          prompts: [],
          resources: [],
        );
      }

      // 尝试是否是 McpResourcesClient
      if (client is McpResourcesClient) {
        return await (client as McpResourcesClient).getAllResources();
      }

      // 回退到基本获取
      _log.info('使用基本客户端获取资源');
      final tools = await client.listTools() ?? [];

      return MCPAllResources(
        tools: tools,
        prompts: [],
        resources: [],
      );
    } catch (e) {
      _log.error('获取 MCP 资源常常', e);
      return MCPAllResources(
        tools: [],
        prompts: [],
        resources: [],
      );
    }
  }

  /// 获取所有定义的 MCP 配置的资源
  Future<Map<String, MCPAllResources>> getAllResourcesForAllConfigs(
    List<String> configIds,
  ) async {
    _log.info('获取所有配置的资源', {'configCount': configIds.length});
    try {
      final results = <String, MCPAllResources>{};

      for (final configId in configIds) {
        results[configId] = await getAllResources(configId);
      }

      _log.info('成功获取所有配置的资源');
      return results;
    } catch (e) {
      _log.error('获取所有配置资源常常', e);
      return {};
    }
  }

  /// 检查配置是否支持提示词
  Future<bool> supportsPrompts(String configId) async {
    try {
      final client = _repository.getClient(configId);
      if (client is McpResourcesClient) {
        final prompts =
            await (client as McpResourcesClient).listPromptsWithFallback();
        return prompts != null && prompts.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 检查配置是否支持资源
  Future<bool> supportsResources(String configId) async {
    try {
      final client = _repository.getClient(configId);
      if (client is McpResourcesClient) {
        final resources =
            await (client as McpResourcesClient).listResourcesWithFallback();
        return resources != null && resources.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 搜索工具
  Future<List<Map<String, dynamic>>> searchTools(
    String configId,
    String query,
  ) async {
    try {
      final client = _repository.getClient(configId);
      if (client == null) return [];

      final tools = await client.listTools() ?? [];
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
      _log.error('搜索工具常常', e);
      return [];
    }
  }

  /// 搜索提示词
  Future<List<Map<String, dynamic>>> searchPrompts(
    String configId,
    String query,
  ) async {
    try {
      final client = _repository.getClient(configId);
      if (client is! McpResourcesClient) return [];

      final prompts =
          await (client as McpResourcesClient).listPromptsWithFallback() ?? [];
      final lowercaseQuery = query.toLowerCase();

      return prompts
          .where((prompt) {
            final name = (prompt['name'] as String? ?? '').toLowerCase();
            final description =
                (prompt['description'] as String? ?? '').toLowerCase();
            return name.contains(lowercaseQuery) ||
                description.contains(lowercaseQuery);
          })
          .toList();
    } catch (e) {
      _log.error('搜索提示词常常', e);
      return [];
    }
  }

  /// 搜索资源
  Future<List<Map<String, dynamic>>> searchResources(
    String configId,
    String query,
  ) async {
    try {
      final client = _repository.getClient(configId);
      if (client is! McpResourcesClient) return [];

      final resources =
          await (client as McpResourcesClient).listResourcesWithFallback() ??
              [];
      final lowercaseQuery = query.toLowerCase();

      return resources
          .where((resource) {
            final uri = (resource['uri'] as String? ?? '').toLowerCase();
            final name = (resource['name'] as String? ?? '').toLowerCase();
            return uri.contains(lowercaseQuery) || name.contains(lowercaseQuery);
          })
          .toList();
    } catch (e) {
      _log.error('搜索资源常常', e);
      return [];
    }
  }
}
