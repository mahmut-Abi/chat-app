import '../domain/mcp_config.dart';
import '../../../core/storage/storage_service.dart';
import 'mcp_client.dart';
import 'package:uuid/uuid.dart';

/// MCP 仓库
class McpRepository {
  final StorageService _storage;
  final Map<String, McpClient> _clients = {};
  
  McpRepository(this._storage);

  /// 创建 MCP 配置
  Future<McpConfig> createConfig({
    required String name,
    required String endpoint,
    String? description,
    Map<String, dynamic>? headers,
  }) async {
    final config = McpConfig(
      id: const Uuid().v4(),
      name: name,
      endpoint: endpoint,
      description: description,
      headers: headers,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.saveSetting('mcp_config_${config.id}', config.toJson());
    return config;
  }

  /// 获取所有 MCP 配置
  List<McpConfig> getAllConfigs() {
    // TODO: 实现从 storage 读取所有配置
    return [];
  }

  /// 更新 MCP 配置
  Future<void> updateConfig(McpConfig config) async {
    final updated = config.copyWith(updatedAt: DateTime.now());
    await _storage.saveSetting('mcp_config_${config.id}', updated.toJson());
  }

  /// 删除 MCP 配置
  Future<void> deleteConfig(String id) async {
    await _disconnectClient(id);
    // TODO: 实现从 storage 删除
  }

  /// 连接到 MCP 服务器
  Future<bool> connect(McpConfig config) async {
    final client = McpClient(config: config);
    final success = await client.connect();
    
    if (success) {
      _clients[config.id] = client;
    }
    
    return success;
  }

  /// 断开 MCP 连接
  Future<void> disconnect(String configId) async {
    await _disconnectClient(configId);
  }

  Future<void> _disconnectClient(String configId) async {
    final client = _clients[configId];
    if (client != null) {
      await client.disconnect();
      client.dispose();
      _clients.remove(configId);
    }
  }

  /// 获取客户端
  McpClient? getClient(String configId) {
    return _clients[configId];
  }

  /// 获取连接状态
  McpConnectionStatus? getConnectionStatus(String configId) {
    return _clients[configId]?.status;
  }

  void dispose() {
    for (final client in _clients.values) {
      client.dispose();
    }
    _clients.clear();
  }
}
