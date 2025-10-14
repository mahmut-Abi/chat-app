import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/agent_tool.dart';
import '../data/agent_provider.dart';
import 'agent_config_screen.dart';
import 'tool_config_screen.dart';

/// Agent 管理界面
class AgentScreen extends ConsumerWidget {
  const AgentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agent 管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Agent', icon: Icon(Icons.smart_toy)),
              Tab(text: '工具', icon: Icon(Icons.build)),
            ],
          ),
        ),
        body: TabBarView(children: [_AgentTab(), _ToolsTab()]),
      ),
    );
  }
}

/// Agent 标签页
class _AgentTab extends ConsumerWidget {
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
                ? _buildEmptyState(context, '暂无 Agent')
                : _buildAgentList(context, ref, agents),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('加载失败: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildAgentList(
    BuildContext context,
    WidgetRef ref,
    List<AgentConfig> agents,
  ) {
    return ListView.builder(
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              Icons.smart_toy,
              color: agent.enabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            title: Text(agent.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.description ?? '无描述'),
                const SizedBox(height: 4),
                Text(
                  agent.enabled ? '已启用' : '已停用',
                  style: TextStyle(
                    fontSize: 12,
                    color: agent.enabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: agent.enabled,
                  onChanged: (value) async {
                    final repository = ref.read(agentRepositoryProvider);
                    final updated = agent.copyWith(enabled: value);
                    await repository.updateAgent(updated);
                    ref.invalidate(agentConfigsProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AgentConfigScreen(config: agent),
                      ),
                    );
                    if (result == true) ref.invalidate(agentConfigsProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAgent(context, ref, agent.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteAgent(BuildContext context, WidgetRef ref, String id) {
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
                await repository.deleteAgent(id);

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

/// 工具标签页
class _ToolsTab extends ConsumerWidget {
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
                ? _buildEmptyState(context, '暂无工具')
                : _buildToolsList(context, ref, tools),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('加载失败: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildToolsList(
    BuildContext context,
    WidgetRef ref,
    List<AgentTool> tools,
  ) {
    return ListView.builder(
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              _getToolIcon(tool.type),
              color: tool.enabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            title: Text(tool.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tool.description),
                const SizedBox(height: 4),
                Text(
                  tool.enabled ? '已启用' : '已停用',
                  style: TextStyle(
                    fontSize: 12,
                    color: tool.enabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: tool.enabled,
                  onChanged: (value) async {
                    final repository = ref.read(agentRepositoryProvider);
                    await repository.updateToolStatus(tool.id, value);
                    ref.invalidate(agentToolsProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteTool(context, ref, tool.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getToolIcon(AgentToolType type) {
    switch (type) {
      case AgentToolType.search:
        return Icons.search;
      case AgentToolType.codeExecution:
        return Icons.code;
      case AgentToolType.fileOperation:
        return Icons.folder;
      case AgentToolType.calculator:
        return Icons.calculate;
      case AgentToolType.custom:
        return Icons.extension;
    }
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
