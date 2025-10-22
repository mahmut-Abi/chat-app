import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/agent_tool.dart';
import '../../../../core/providers/providers.dart';
import '../agent_config_screen.dart';
import 'agent_list_item.dart';
import 'empty_state_widget.dart';

/// Agent 标签页
class AgentTab extends ConsumerWidget {
  const AgentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentConfigsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => const AgentConfigScreen(),
                ),
              );
              if (result == true) ref.invalidate(agentConfigsProvider);
            },
            icon: const Icon(Icons.add),
            label: const Text('创建 Agent'),
          ),
        ),
        Expanded(
          child: agentsAsync.when(
            data: (agents) => agents.isEmpty
                ? const EmptyStateWidget(message: '暂无 Agent')
                : _buildAgentList(context, ref, agents),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('加载失败: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentList(
    BuildContext context,
    WidgetRef ref,
    List<AgentConfig> agents,
  ) {
    return ListView.builder(
      itemCount: agents.length,
      itemBuilder: (context, index) => AgentListItem(
        agent: agents[index],
        onDelete: () => _deleteAgent(
          context,
          ref,
          agents[index].id,
          isBuiltIn: agents[index].isBuiltIn,
        ),
      ),
    );
  }

  void _deleteAgent(
    BuildContext context,
    WidgetRef ref,
    String id, {
    bool isBuiltIn = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除该 Agent 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repository = ref.read(agentRepositoryProvider);
                await repository.deleteAgentWithPersistence(id, isBuiltIn);

                ref.invalidate(agentConfigsProvider);

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
