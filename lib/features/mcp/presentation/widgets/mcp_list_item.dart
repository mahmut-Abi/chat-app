import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../domain/mcp_config.dart';
import '../mcp_config_screen.dart';

/// MCP 列表项
class McpListItem extends ConsumerWidget {
  final McpConfig config;
  final VoidCallback onDelete;

  const McpListItem({super.key, required this.config, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(
      mcpConnectionStatusProvider(config.id),
    );

    return Card(
      color: Theme.of(context).cardColor.withOpacity(0.7),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusBackgroundColor(context, connectionStatus),
          child: Icon(
            Icons.cloud_outlined,
            color: _getStatusColor(connectionStatus),
            size: 22,
          ),
        ),
        title: Text(config.name),
        titleAlignment: ListTileTitleAlignment.top,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  config.connectionType == McpConnectionType.stdio
                      ? Icons.terminal_outlined
                      : Icons.http_outlined,
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
            Text(config.endpoint, style: const TextStyle(fontSize: 12)),
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
                    : Icons.play_arrow_outlined,
              ),
              onPressed: config.enabled
                  ? () async {
                      if (connectionStatus == McpConnectionStatus.connected) {
                        await ref.read(mcpRepositoryProvider).disconnect(config.id);
                      } else {
                        final success =
                            await ref.read(mcpRepositoryProvider).connect(config);
                        if (kDebugMode) {
                          print('[MCP] Connect result: $success');
                        }
                        await Future.delayed(
                          const Duration(milliseconds: 800),
                        );
                      }
                      ref.invalidate(
                        mcpConnectionStatusProvider(config.id),
                      );
                      ref.invalidate(mcpConfigsProvider);
                    }
                  : null,
            ),
            if (connectionStatus == McpConnectionStatus.connected)
              IconButton(
                icon: const Icon(Icons.build_outlined),
                tooltip: '查看工具列表',
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
              onPressed: onDelete,
            ),
          ],
        ),
      ),
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

  Color _getStatusBackgroundColor(
    BuildContext context,
    McpConnectionStatus status,
  ) {
    return _getStatusColor(status).withOpacity(0.2);
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
}
