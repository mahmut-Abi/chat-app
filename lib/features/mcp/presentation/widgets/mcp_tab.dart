import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../domain/mcp_config.dart';
import '../mcp_config_screen.dart';
import 'mcp_list_item.dart';
import '../../../../../shared/widgets/loading_widget.dart';

/// MCP 列表标签页
class McpTab extends ConsumerWidget {
  const McpTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(mcpConfigsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => const McpConfigScreen(),
                ),
              );
              if (result == true) ref.invalidate(mcpConfigsProvider);
            },
            icon: const Icon(Icons.add),
            label: const Text('添加 MCP 服务器'),
          ),
        ),
        Expanded(
          child: configsAsync.when(
            data: (configs) => configs.isEmpty
                ? const EmptyStateWidget(message: '暂无 MCP 服务器')
                : _buildConfigList(context, ref, configs),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('加载失败: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigList(
    BuildContext context,
    WidgetRef ref,
    List<McpConfig> configs,
  ) {
    return ListView.builder(
      itemCount: configs.length,
      itemBuilder: (context, index) => McpListItem(
        config: configs[index],
        onDelete: () => _deleteConfig(
          context,
          ref,
          configs[index].id,
        ),
      ),
    );
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
