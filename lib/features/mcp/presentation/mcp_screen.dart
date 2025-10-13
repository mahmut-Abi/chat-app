import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mcp_config.dart';

/// MCP 配置界面
class McpScreen extends ConsumerStatefulWidget {
  const McpScreen({super.key});

  @override
  ConsumerState<McpScreen> createState() => _McpScreenState();
}

class _McpScreenState extends ConsumerState<McpScreen> {
  final List<McpConfig> _configs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP 配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
            tooltip: '添加 MCP 服务器',
          ),
        ],
      ),
      body: _configs.isEmpty
          ? _buildEmptyState()
          : _buildConfigList(),
    );
  }

  Widget _buildEmptyState() {
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
          Text(
            '暂无 MCP 服务器',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角添加按钮创建配置',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigList() {
    return ListView.builder(
      itemCount: _configs.length,
      itemBuilder: (context, index) {
        final config = _configs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              Icons.cloud,
              color: config.enabled ? Colors.green : Colors.grey,
            ),
            title: Text(config.name),
            subtitle: Text(config.endpoint),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: config.enabled,
                  onChanged: (value) {
                    // TODO: 实现启用/禁用
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteConfig(config.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final endpointController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加 MCP 服务器'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '输入服务器名称',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endpointController,
              decoration: const InputDecoration(
                labelText: '端点',
                hintText: 'http://localhost:3000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现添加配置
              Navigator.of(context).pop();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _deleteConfig(String id) {
    // TODO: 实现删除配置
  }
}
