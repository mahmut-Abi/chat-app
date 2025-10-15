import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/agent_tool.dart';
import '../../../../core/providers/providers.dart';
import '../tool_config_screen.dart';
import 'tool_list_item.dart';
import 'empty_state_widget.dart';

/// 工具标签页
class ToolsTab extends ConsumerWidget {
  const ToolsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsAsync = ref.watch(agentToolsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => const ToolConfigScreen(),
                ),
              );
              if (result == true) ref.invalidate(agentToolsProvider);
            },
            icon: const Icon(Icons.add),
            label: const Text('添加工具'),
          ),
        ),
        Expanded(
          child: toolsAsync.when(
            data: (tools) => tools.isEmpty
                ? const EmptyStateWidget(message: '暂无工具')
                : _buildToolsList(context, ref, tools),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('加载失败: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildToolsList(
    BuildContext context,
    WidgetRef ref,
    List<AgentTool> tools,
  ) {
    return ListView.builder(
      itemCount: tools.length,
      itemBuilder: (context, index) => ToolListItem(
        tool: tools[index],
        onDelete: () => _deleteTool(context, ref, tools[index].id),
      ),
    );
  }

  void _deleteTool(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除该工具吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(agentRepositoryProvider);
                await repository.deleteTool(id);

                ref.invalidate(agentToolsProvider);

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
