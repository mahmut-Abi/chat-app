import 'mcp_repository.dart';
import '../../../core/services/log_service.dart';

/// 默认 MCP 服务器配置
class DefaultMcpServers {
  static final _log = LogService();

  /// 初始化示例 MCP 服务器
  /// 已禁用 - 无需内置示例配置
  static Future<void> initializeExampleServers(McpRepository repository) async {
    // 空实现，不分配任何示例配置
    return;
  }

  /// 创建用户友好的快速开始配置
  /// 已禁用 - 无需内置快速开始配置
  static Future<void> initializeQuickStartServers(
    McpRepository repository,
  ) async {
    // 空实现，不分配任何快速开始配置
    return;
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

      _log.info('MCP 服务器配置重置完成');
    } catch (e, stackTrace) {
      _log.error('重置 MCP 服务器配置失败', e, stackTrace);
      rethrow;
    }
  }
}
