import 'mcp_client_base.dart';
import '../domain/mcp_config.dart';

/// MCP 客户端扩展接口 - 支持提示词
abstract class McpClientWithPrompts extends McpClientBase {
  McpClientWithPrompts({required super.config});

  /// 获取提示词列表
  Future<List<Map<String, dynamic>>?> listPrompts();

  /// 获取单个提示词详情
  Future<Map<String, dynamic>?> getPrompt(String promptName) async {
    final prompts = await listPrompts();
    if (prompts == null) return null;
    try {
      return prompts.firstWhere(
        (p) => p['name'] == promptName,
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }
}

/// MCP 客户端扩展接口 - 支持资源
abstract class McpClientWithResources extends McpClientBase {
  McpClientWithResources({required super.config});

  /// 获取资源列表
  Future<List<Map<String, dynamic>>?> listResources();

  /// 获取单个资源详情
  Future<Map<String, dynamic>?> getResource(String resourceUri) async {
    final resources = await listResources();
    if (resources == null) return null;
    try {
      return resources.firstWhere(
        (r) => r['uri'] == resourceUri,
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }
}

/// MCP 客户端完整接口 - 支持所有资源
abstract class McpClientComplete extends McpClientBase
    implements McpClientWithPrompts, McpClientWithResources {
  McpClientComplete({required super.config});
}
