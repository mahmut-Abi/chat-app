import '../domain/mcp_config.dart';
import '../../../core/storage/storage_service.dart';
import 'mcp_client_base.dart';
import 'mcp_client_factory.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/log_service.dart';

/// MCP 仓库
class McpRepository {
  final StorageService _storage;
  final Map<String, McpClientBase> _clients = {};
  final _log = LogService();

  McpRepository(this._storage);

  /// 创建 MCP 配置
  Future<McpConfig> createConfig({
    required String name,
    McpConnectionType connectionType = McpConnectionType.http,
    required String endpoint,
    List<String>? args,
    Map<String, String>? env,
    String? description,
    Map<String, dynamic>? headers,
  }) async {
    _log.info('创建 MCP 配置', {
      'name': name,
      'connectionType': connectionType.toString(),
      'endpoint': endpoint,
      'hasArgs': args != null,
      'hasEnv': env != null,
    });

    final config = McpConfig(
      id: const Uuid().v4(),
      name: name,
      connectionType: connectionType,
      endpoint: endpoint,
      args: args,
      env: env,
      description: description,
      headers: headers,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.saveSetting('mcp_config_${config.id}', config.toJson());
    _log.debug('MCP 配置已保存', {'configId': config.id});
    return config;
  }

  /// 添加 MCP 配置 (createConfig 的别名)
  Future<McpConfig> addConfig(McpConfig config) async {
    await _storage.saveSetting('mcp_config_\${config.id}', config.toJson());
    return config;
  }

  /// 获取所有 MCP 配置
  Future<List<McpConfig>> getAllConfigs() async {
    _log.debug('获取所有 MCP 配置');
    try {
      final keys = await _storage.getAllKeys();
      final mcpKeys = keys.where((k) => k.startsWith('mcp_config_')).toList();

      final configs = <McpConfig>[];
      for (final key in mcpKeys) {
        final data = _storage.getSetting(key);
        if (data != null && data is Map<String, dynamic>) {
          try {
            configs.add(McpConfig.fromJson(data));
          } catch (e) {
            // 跳过无效的配置
          }
        }
      }

      return configs;
    } catch (e) {
      return [];
    }
  }

  /// 更新 MCP 配置
  Future<void> updateConfig(McpConfig config) async {
    _log.info('更新 MCP 配置', {'configId': config.id, 'name': config.name});
    final updated = config.copyWith(updatedAt: DateTime.now());
    await _storage.saveSetting('mcp_config_${config.id}', updated.toJson());
  }

  /// 删除 MCP 配置
  Future<void> deleteConfig(String id) async {
    _log.info('删除 MCP 配置: id=$id');
    await _disconnectClient(id);
    await _storage.deleteSetting('mcp_config_$id');
  }

  /// 连接到 MCP 服务器
  Future<bool> connect(McpConfig config) async {
    _log.info('连接 MCP 服务器: name=${config.name}, endpoint=${config.endpoint}');
    final client = McpClientFactory.createClient(config);
    final success = await client.connect();

    if (success) {
      _clients[config.id] = client;
      _log.info('MCP 连接成功: name=${config.name}');
    } else {
      _log.warning('MCP 连接失败: name=${config.name}');
    }

    return success;
  }

  /// 断开 MCP 连接
  Future<void> disconnect(String configId) async {
    _log.info('断开 MCP 连接: id=$configId');
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
  McpClientBase? getClient(String configId) {
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
