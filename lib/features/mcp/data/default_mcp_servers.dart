import '../domain/mcp_config.dart';
import 'mcp_repository.dart';
import '../../../core/services/log_service.dart';
import 'package:uuid/uuid.dart';

/// 默认 MCP 服务器配置
class DefaultMcpServers {
  static final _log = LogService();

  /// 初始化示例 MCP 服务器
  static Future<void> initializeExampleServers(McpRepository repository) async {
    _log.info('开始初始化示例 MCP 服务器');
    // 被禁用 - 无需内置 MCP 配置
    return;
  }

  /// 创建用户友好的快速开始配置
  // DISABLED - No built-in configs needed
  //static Future<void> initializeQuickStartServers(
    McpRepository repository,
  ) async {
    _log.info('开始初始化快速开始 MCP 服务器');

    try {
      final existingConfigs = await repository.getAllConfigs();

      // 如果已有配置，跳过
      if (existingConfigs.isNotEmpty) {
        _log.info('已存在 MCP 服务器配置，跳过快速开始初始化');
        return;
      }

      // 创建一个简单的 echo 服务器示例
      final quickStart = McpConfig(
        id: const Uuid().v4(),
        name: '快速开始 - Echo 服务器',
        connectionType: McpConnectionType.http,
        endpoint: 'http://localhost:3000',
        description: '''快速开始配置 - 本地 Echo 服务器

这是一个简单的测试配置，用于验证 MCP 功能。

使用方法：
1. 启动本地 MCP 服务器（端口 3000）
2. 点击"连接"按钮
3. 在聊天中使用 MCP 工具

更多信息请参考文档：docs/mcp-integration.md''',
        headers: {'Content-Type': 'application/json'},
        enabled: false, // 默认禁用，需要用户手动启用
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.addConfig(quickStart);

      _log.info('快速开始 MCP 服务器配置创建成功');
    } catch (e, stackTrace) {
      _log.error('初始化快速开始 MCP 服务器失败', e, stackTrace);
    }
  }

  /// 重置 MCP 服务器配置
  static Future<void> resetMcpServers(McpRepository repository) async {
    _log.info('重置 MCP 服务器配置');

    try {
      // 删除所有配置
      final existingConfigs = await repository.getAllConfigs();
      for (final config in existingConfigs) {
        await repository.deleteConfig(config.id);
      }

      // 重新创建示例配置
      await initializeExampleServers(repository);

      _log.info('MCP 服务器配置重置完成');
    } catch (e, stackTrace) {
      _log.error('重置 MCP 服务器配置失败', e, stackTrace);
      rethrow;
    }
  }
}
