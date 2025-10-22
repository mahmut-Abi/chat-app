import 'mcp_repository.dart';
import 'mcp_client_base.dart';
import '../../../core/services/log_service.dart';

/// MCP 资源服务 - 获取和管理 MCP 资源（工具、提示词、资源）
class McpResourcesService {
  final McpRepository _repository;
  final _log = LogService();

  McpResourcesService(this._repository);

  /// 获取指定配置的工具列表
  Future<List<Map<String, dynamic>>> getTools(String configId) async {
    _log.info('获取工具列表', {'configId': configId});
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

      _log.info('成功获取工具列表', {
        'configId': configId,
        'count': tools.length,
      });
      return tools;
    } catch (e) {
      _log.error('获取工具列表失败', e);
      return [];
    }
  }

  /// 获取指定配置的提示词列表
  Future<List<Map<String, dynamic>>> getPrompts(String configId) async {
    _log.info('获取提示词列表', {'configId': configId});
    try {
      final client = _repository.getClient(configId);
      if (client == null) {
        _log.warning('MCP 客户端未连接', {'configId': configId});
        return [];
      }

      // 检查客户端是否支持 listPrompts
      if (client is! McpClientBaseWithPrompts) {
        _log.warning('客户端不支持提示词列表', {'configId': configId});
        return [];
      }

      final prompts = await (client as McpClientBaseWithPrompts).listPrompts();
      if (prompts == null) {
        _log.warning('提示词列表为空', {'configId': configId});
        return [];
      }

      _log.info('成功获取提示词列表', {
        'configId': configId,
        'count': prompts.length,
      });
      return prompts;
    } catch (e) {
      _log.error('获取提示词列表失败', e);
      return [];
    }
  }

  /// 获取指定配置的资源列表
  Future<List<Map<String, dynamic>>> getResources(String configId) async {
    _log.info('获取资源列表', {'configId': configId});
    try {
      final client = _repository.getClient(configId);
      if (client == null) {
        _log.warning('MCP 客户端未连接', {'configId': configId});
        return [];
      }

      // 检查客户端是否支持 listResources
      if (client is! McpClientBaseWithResources) {
        _log.warning('客户端不支持资源列表', {'configId': configId});
        return [];
      }

      final resources =
          await (client as McpClientBaseWithResources).listResources();
      if (resources == null) {
        _log.warning('资源列表为空', {'configId': configId});
        return [];
      }

      _log.info('成功获取资源列表', {
        'configId': configId,
        'count': resources.length,
      });
      return resources;
    } catch (e) {
      _log.error('获取资源列表失败', e);
      return [];
    }
  }

  /// 获取所有资源（工具、提示词、资源）
  Future<McpResourcesSummary> getAllResources(String configId) async {
    _log.info('获取所有资源', {'configId': configId});
    try {
      final tools = await getTools(configId);
      final prompts = await getPrompts(configId);
      final resources = await getResources(configId);

      return McpResourcesSummary(
        configId: configId,
        tools: tools,
        prompts: prompts,
        resources: resources,
      );
    } catch (e) {
      _log.error('获取所有资源失败', e);
      return McpResourcesSummary(
        configId: configId,
        tools: [],
        prompts: [],
        resources: [],
      );
    }
  }

  /// 搜索工具
  Future<List<Map<String, dynamic>>> searchTools(
    String configId,
    String query,
  ) async {
    try {
      final tools = await getTools(configId);
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

  /// 搜索提示词
  Future<List<Map<String, dynamic>>> searchPrompts(
    String configId,
    String query,
  ) async {
    try {
      final prompts = await getPrompts(configId);
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
      _log.error('搜索提示词失败', e);
      return [];
    }
  }
}

/// MCP 资源总结
class McpResourcesSummary {
  final String configId;
  final List<Map<String, dynamic>> tools;
  final List<Map<String, dynamic>> prompts;
  final List<Map<String, dynamic>> resources;

  McpResourcesSummary({
    required this.configId,
    required this.tools,
    required this.prompts,
    required this.resources,
  });

  int get totalCount => tools.length + prompts.length + resources.length;

  Map<String, int> get counts => {
    'tools': tools.length,
    'prompts': prompts.length,
    'resources': resources.length,
  };
}

/// MCP 客户端扩展接口 - 支持提示词
abstract class McpClientBaseWithPrompts extends McpClientBase {
  McpClientBaseWithPrompts({required super.config});

  /// 获取提示词列表
  Future<List<Map<String, dynamic>>?> listPrompts();
}

/// MCP 客户端扩展接口 - 支持资源
abstract class McpClientBaseWithResources extends McpClientBase {
  McpClientBaseWithResources({required super.config});

  /// 获取资源列表
  Future<List<Map<String, dynamic>>?> listResources();
}

/// MCP 客户端完整接口 - 支持所有资源
abstract class McpClientBaseFull extends McpClientBase {
  McpClientBaseFull({required super.config});

  /// 获取提示词列表
  Future<List<Map<String, dynamic>>?> listPrompts();

  /// 获取资源列表
  Future<List<Map<String, dynamic>>?> listResources();
}
