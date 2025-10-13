import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mcp_config.dart';
import '../data/mcp_provider.dart';

/// MCP 配置界面
class McpScreen extends ConsumerWidget {
  const McpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(mcpConfigsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP 配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: configsAsync.when(
        data: (configs) => configs.isEmpty
            ? _buildEmptyState(context)
            : _buildConfigList(context, ref, configs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
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

  Widget _buildConfigList(BuildContext context, WidgetRef ref, List<McpConfig> configs) {
    return ListView.builder(
      itemCount: configs.length,
      itemBuilder: (context, index) {
        final config = configs[index];
        final connectionStatus = ref.watch(
          mcpConnectionStatusProvider(config.id),
        );
        
        return Card(
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
                IconButton(
                  icon: Icon(
                    connectionStatus == McpConnectionStatus.connected
                        ? Icons.stop
                        : Icons.play_arrow,
                  ),
                  onPressed: () async {
                    if (connectionStatus == McpConnectionStatus.connected) {
                      await ref.read(mcpRepositoryProvider).disconnect(config.id);
                    } else {
                      await ref.read(mcpRepositoryProvider).connect(config);
                    }
                    ref.invalidate(mcpConfigsProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(context, ref, config),
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

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final endpointController = TextEditingController();
    final descriptionController = TextEditingController();

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
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '输入描述信息',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _addConfig(
              context,
              ref,
              nameController.text,
              endpointController.text,
              descriptionController.text,
            ),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addConfig(
    BuildContext context,
    WidgetRef ref,
    String name,
    String endpoint,
    String description,
  ) async {
    if (name.isEmpty || endpoint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写名称和端点')),
      );
      return;
    }
    
    try {
      final repository = ref.read(mcpRepositoryProvider);
      await repository.createConfig(
        name: name,
        endpoint: endpoint,
        description: description.isEmpty ? null : description,
      );
      
      ref.invalidate(mcpConfigsProvider);
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添加成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }
  
  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, McpConfig config) async {
    final nameController = TextEditingController(text: config.name);
    final endpointController = TextEditingController(text: config.endpoint);
    final descriptionController = TextEditingController(text: config.description ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑 MCP 服务器'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名称',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endpointController,
              decoration: const InputDecoration(
                labelText: '端点',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
              ),
              maxLines: 2,
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
              _updateConfig(
                context,
                ref,
                config,
                nameController.text,
                endpointController.text,
                descriptionController.text,
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateConfig(
    BuildContext context,
    WidgetRef ref,
    McpConfig config,
    String name,
    String endpoint,
    String description,
  ) async {
    if (name.isEmpty || endpoint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写名称和端点')),
      );
      return;
    }
    
    try {
      final repository = ref.read(mcpRepositoryProvider);
      final updated = config.copyWith(
        name: name,
        endpoint: endpoint,
        description: description.isEmpty ? null : description,
      );
      await repository.updateConfig(updated);
      
      ref.invalidate(mcpConfigsProvider);
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
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
