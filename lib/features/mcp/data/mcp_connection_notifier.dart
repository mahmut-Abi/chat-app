import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mcp_config.dart';
import 'mcp_repository.dart';

/// MCP 连接状态通知程序
/// 用于瘟总亊整个 MCP 配置的连接状态
class McpConnectionNotifier extends StateNotifier<Map<String, McpConnectionStatus>> {
  final McpRepository _repository;

  McpConnectionNotifier(this._repository) : super({});

  /// 更新指定配置的连接状态
  void updateStatus(String configId, McpConnectionStatus status) {
    state = {
      ...state,
      configId: status,
    };
  }

  /// 获取指定配置的连接状态
  McpConnectionStatus getStatus(String configId) {
    return state[configId] ?? _repository.getConnectionStatus(configId) ??
        McpConnectionStatus.disconnected;
  }

  /// 初始化所有配置的状态
  Future<void> initializeStatus(List<McpConfig> configs) async {
    final newState = <String, McpConnectionStatus>{};
    for (final config in configs) {
      final status = _repository.getConnectionStatus(config.id) ??
          McpConnectionStatus.disconnected;
      newState[config.id] = status;
    }
    state = newState;
  }
}
