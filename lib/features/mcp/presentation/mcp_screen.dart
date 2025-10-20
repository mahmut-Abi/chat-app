import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/platform_utils.dart';
import '../domain/mcp_config.dart';
import '../../../core/providers/providers.dart';
import 'mcp_config_screen.dart';
import '../../../core/utils/message_utils.dart';

/// MCP 配置界面
class McpScreen extends ConsumerWidget {
  const McpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(mcpConfigsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('MCP 配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => const McpConfigScreen(),
                ),
              );
              if (result == true) ref.invalidate(mcpConfigsProvider);
            },
          ),
        ],
      ),
      body: configsAsync.when(
        data: (configs) => configs.isEmpty
              ? _buildEmptyState(context)
              : _buildConfigList(context, ref, configs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text('暂无 MCP 服务器', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('点击右上角添加按钮创建配置', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildConfigList(
    BuildContext context,
    WidgetRef ref,
    List<McpConfig> configs,
  ) {
    return ListView.builder(
      itemCount: configs.length,
      itemBuilder: (context, index) {
        final config = configs[index];
        final connectionStatus = ref.watch(
          mcpConnectionStatusProvider(config.id),
        );

        return Card(
          color: Theme.of(context).cardColor.withValues(alpha: 0.7),
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              Icons.cloud,
              color: _getStatusColor(connectionStatus),
            ),
            title: Text(config.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      config.connectionType == McpConnectionType.stdio
                          ? Icons.terminal
                          : Icons.http,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      config.connectionType == McpConnectionType.stdio
                          ? 'Stdio'
                          : 'HTTP',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(config.endpoint),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(connectionStatus),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(connectionStatus),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: config.enabled,
                  onChanged: (value) async {
                    final repository = ref.read(mcpRepositoryProvider);
                    final updated = config.copyWith(enabled: value);
                    await repository.updateConfig(updated);
                    if (!value &&
                        connectionStatus == McpConnectionStatus.connected) {
                      await repository.disconnect(config.id);
                    }
                    ref.invalidate(mcpConfigsProvider);
                  },
                ),
                IconButton(
                  icon: Icon(
                    connectionStatus == McpConnectionStatus.connected
                        ? Icons.stop
                        : Icons.play_arrow,
                  ),
                  onPressed: config.enabled
                      ? () async {
                          if (connectionStatus ==
                              McpConnectionStatus.connected) {
                            await ref
                                .read(mcpRepositoryProvider)
                                .disconnect(config.id);
                          } else {
                            await ref
                                .read(mcpRepositoryProvider)
                                .connect(config);
                          }
                          ref.invalidate(mcpConfigsProvider);
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => McpConfigScreen(config: config),
                      ),
                    );
                    if (result == true) ref.invalidate(mcpConfigsProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteConfig(context, ref, config.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(McpConnectionStatus status) {
    switch (status) {
      case McpConnectionStatus.connected:
        return Colors.green;
      case McpConnectionStatus.connecting:
        return Colors.orange;
      case McpConnectionStatus.error:
        return Colors.red;
      case McpConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String _getStatusText(McpConnectionStatus status) {
    switch (status) {
      case McpConnectionStatus.connected:
        return '已连接';
      case McpConnectionStatus.connecting:
        return '连接中...';
      case McpConnectionStatus.error:
        return '连接失败';
      case McpConnectionStatus.disconnected:
        return '未连接';
    }
  }

  void _deleteConfig(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除该 MCP 配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(mcpRepositoryProvider);
                await repository.deleteConfig(id);

                ref.invalidate(mcpConfigsProvider);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('删除成功')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
                }
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
