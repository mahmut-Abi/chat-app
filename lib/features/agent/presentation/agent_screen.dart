import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/agent_tool.dart';
import '../data/agent_provider.dart';

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
        body: TabBarView(
          children: [
            _AgentTab(),
            _ToolsTab(),
          ],
        ),
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
            onPressed: () => _showAddAgentDialog(context, ref),
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
            error: (error, stack) => Center(
              child: Text('加载失败: $error'),
            ),
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
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAgentList(BuildContext context, WidgetRef ref, List<AgentConfig> agents) {
    return ListView.builder(
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.smart_toy),
            title: Text(agent.name),
            subtitle: Text(agent.description ?? '无描述'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditAgentDialog(context, ref, agent),
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

  Future<void> _showAddAgentDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final systemPromptController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建 Agent'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '输入 Agent 名称',
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
              const SizedBox(height: 16),
              TextField(
                controller: systemPromptController,
                decoration: const InputDecoration(
                  labelText: '系统提示词（可选）',
                  hintText: '输入系统提示词',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _createAgent(
              context,
              ref,
              nameController.text,
              descriptionController.text,
              systemPromptController.text,
            ),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAgent(
    BuildContext context,
    WidgetRef ref,
    String name,
    String description,
    String systemPrompt,
  ) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写 Agent 名称')),
      );
      return;
    }

    try {
      final repository = ref.read(agentRepositoryProvider);
      await repository.createAgent(
        name: name,
        description: description.isEmpty ? null : description,
        toolIds: [],
        systemPrompt: systemPrompt.isEmpty ? null : systemPrompt,
      );

      ref.invalidate(agentConfigsProvider);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  Future<void> _showEditAgentDialog(
    BuildContext context,
    WidgetRef ref,
    AgentConfig agent,
  ) async {
    final nameController = TextEditingController(text: agent.name);
    final descriptionController = TextEditingController(text: agent.description ?? '');
    final systemPromptController = TextEditingController(text: agent.systemPrompt ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑 Agent'),
        content: SingleChildScrollView(
          child: Column(
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
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: systemPromptController,
                decoration: const InputDecoration(
                  labelText: '系统提示词（可选）',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _updateAgent(
              context,
              ref,
              agent,
              nameController.text,
              descriptionController.text,
              systemPromptController.text,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAgent(
    BuildContext context,
    WidgetRef ref,
    AgentConfig agent,
    String name,
    String description,
    String systemPrompt,
  ) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写 Agent 名称')),
      );
      return;
    }

    try {
      final repository = ref.read(agentRepositoryProvider);
      final updated = agent.copyWith(
        name: name,
        description: description.isEmpty ? null : description,
        systemPrompt: systemPrompt.isEmpty ? null : systemPrompt,
      );
      await repository.updateAgent(updated);

      ref.invalidate(agentConfigsProvider);

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
            onPressed: () => _showAddToolDialog(context, ref),
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
            error: (error, stack) => Center(
              child: Text('加载失败: $error'),
            ),
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
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildToolsList(BuildContext context, WidgetRef ref, List<AgentTool> tools) {
    return ListView.builder(
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(_getToolIcon(tool.type)),
            title: Text(tool.name),
            subtitle: Text(tool.description),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTool(context, ref, tool.id),
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

  Future<void> _showAddToolDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    AgentToolType selectedType = AgentToolType.calculator;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加工具'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '输入工具名称',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '描述',
                    hintText: '输入工具描述',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AgentToolType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: '工具类型',
                  ),
                  items: AgentToolType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getToolTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => _createTool(
                context,
                ref,
                nameController.text,
                descriptionController.text,
                selectedType,
              ),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  String _getToolTypeName(AgentToolType type) {
    switch (type) {
      case AgentToolType.search:
        return '网络搜索';
      case AgentToolType.codeExecution:
        return '代码执行';
      case AgentToolType.fileOperation:
        return '文件操作';
      case AgentToolType.calculator:
        return '计算器';
      case AgentToolType.custom:
        return '自定义';
    }
  }

  Future<void> _createTool(
    BuildContext context,
    WidgetRef ref,
    String name,
    String description,
    AgentToolType type,
  ) async {
    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写工具名称和描述')),
      );
      return;
    }

    try {
      final repository = ref.read(agentRepositoryProvider);
      await repository.createTool(
        name: name,
        description: description,
        type: type,
      );

      ref.invalidate(agentToolsProvider);

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
