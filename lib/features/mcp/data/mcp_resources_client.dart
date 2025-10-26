import 'http_mcp_client.dart';
import '../../../core/services/log_service.dart';

/// MCP 资源客户端 - 支持工具、提示词、资源获取
class McpResourcesClient extends HttpMcpClient {
  final LogService _log = LogService();

  McpResourcesClient({required super.config, super.dio});

  /// 获取指定配置的工具列表
  Future<List<Map<String, dynamic>>?> listToolsWithFallback() async {
    _log.debug('获取工具列表(fallback)');
    try {
      // 先尝试标准 /tools 端点
      var tools = await listTools();
      if (tools != null && tools.isNotEmpty) {
        return tools;
      }

      // 帮尝试其他常见端点
      final altEndpoints = ['/api/tools', '/v1/tools', '/tools/list'];
      for (final endpoint in altEndpoints) {
        try {
          final response = await dio.get(endpoint);
          if (response.statusCode == 200) {
            final data = response.data;
            if (data is List) {
              tools = data.cast<Map<String, dynamic>>();
            } else if (data is Map && data['tools'] is List) {
              tools = (data['tools'] as List).cast<Map<String, dynamic>>();
            }
            if (tools != null && tools.isNotEmpty) {
              return tools;
            }
          }
        } catch (e) {
          _log.debug('尝试端点 $endpoint 失败: $e');
        }
      }

      return tools ?? [];
    } catch (e) {
      _log.error('获取工具列表失败', e);
      return null;
    }
  }

  /// 获取指定配置的提示词列表
  Future<List<Map<String, dynamic>>?> listPromptsWithFallback() async {
    _log.debug('获取提示词列表(fallback)');
    try {
      var prompts = await _listPromptsInternal();
      if (prompts != null && prompts.isNotEmpty) {
        return prompts;
      }

      // 帮尝试其他常见端点
      final altEndpoints = ['/api/prompts', '/v1/prompts', '/prompts/list'];
      for (final endpoint in altEndpoints) {
        try {
          final response = await dio.get(endpoint);
          if (response.statusCode == 200) {
            final data = response.data;
            if (data is List) {
              prompts = data.cast<Map<String, dynamic>>();
            } else if (data is Map && data['prompts'] is List) {
              prompts = (data['prompts'] as List).cast<Map<String, dynamic>>();
            }
            if (prompts != null && prompts.isNotEmpty) {
              return prompts;
            }
          }
        } catch (e) {
          _log.debug('尝试端点 $endpoint 失败: $e');
        }
      }

      return prompts ?? [];
    } catch (e) {
      _log.error('获取提示词列表失败', e);
      return null;
    }
  }

  /// 内部提示词获取方法
  Future<List<Map<String, dynamic>>?> _listPromptsInternal() async {
    try {
      final response = await dio.get('/prompts');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map<String, dynamic>) {
          if (data['prompts'] is List) {
            return (data['prompts'] as List).cast<Map<String, dynamic>>();
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取指定配置的资源列表
  Future<List<Map<String, dynamic>>?> listResourcesWithFallback() async {
    _log.debug('获取资源列表(fallback)');
    try {
      var resources = await _listResourcesInternal();
      if (resources != null && resources.isNotEmpty) {
        return resources;
      }

      // 帮尝试其他常见端点
      final altEndpoints = [
        '/api/resources',
        '/v1/resources',
        '/resources/list',
      ];
      for (final endpoint in altEndpoints) {
        try {
          final response = await dio.get(endpoint);
          if (response.statusCode == 200) {
            final data = response.data;
            if (data is List) {
              resources = data.cast<Map<String, dynamic>>();
            } else if (data is Map && data['resources'] is List) {
              resources = (data['resources'] as List)
                  .cast<Map<String, dynamic>>();
            }
            if (resources != null && resources.isNotEmpty) {
              return resources;
            }
          }
        } catch (e) {
          _log.debug('尝试端点 $endpoint 失败: $e');
        }
      }

      return resources ?? [];
    } catch (e) {
      _log.error('获取资源列表失败', e);
      return null;
    }
  }

  /// 内部资源获取方法
  Future<List<Map<String, dynamic>>?> _listResourcesInternal() async {
    try {
      final response = await dio.get('/resources');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map<String, dynamic>) {
          if (data['resources'] is List) {
            return (data['resources'] as List).cast<Map<String, dynamic>>();
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取所有资源
  Future<MCPAllResources> getAllResources() async {
    _log.debug('获取所有 MCP 资源');
    try {
      final toolsFuture = listToolsWithFallback();
      final promptsFuture = listPromptsWithFallback();
      final resourcesFuture = listResourcesWithFallback();

      final results = await Future.wait([
        toolsFuture,
        promptsFuture,
        resourcesFuture,
      ]);

      return MCPAllResources(
        tools: results[0] ?? [],
        prompts: results[1] ?? [],
        resources: results[2] ?? [],
      );
    } catch (e) {
      _log.error('获取所有 MCP 资源失败', e);
      return MCPAllResources(tools: [], prompts: [], resources: []);
    }
  }

  /// 获取 Dio 客户端
}

/// MCP 所有资源
class MCPAllResources {
  final List<Map<String, dynamic>> tools;
  final List<Map<String, dynamic>> prompts;
  final List<Map<String, dynamic>> resources;

  MCPAllResources({
    required this.tools,
    required this.prompts,
    required this.resources,
  });

  int get totalCount => tools.length + prompts.length + resources.length;

  Map<String, int> get resourceCounts => {
    'tools': tools.length,
    'prompts': prompts.length,
    'resources': resources.length,
  };

  bool get isEmpty => totalCount == 0;

  bool get hasTools => tools.isNotEmpty;
  bool get hasPrompts => prompts.isNotEmpty;
  bool get hasResources => resources.isNotEmpty;
}
