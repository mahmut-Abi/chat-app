import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mcp_config.dart';
import 'mcp_repository.dart';

/// MCP 连接状态通知程序
class _McpConnectionNotifier extends StateNotifier<McpConnectionStatus> {
  final McpRepository _repository;
  final String _configId;

  _McpConnectionNotifier(this._repository, this._configId)
      : super(
          _repository.getConnectionStatus(_configId) ??
              McpConnectionStatus.disconnected,
        );

  /// 更新连接状态
  void updateStatus(McpConnectionStatus newStatus) {
    if (state != newStatus) {
      state = newStatus;
    }
  }
}
