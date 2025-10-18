import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/agent_tool.dart';
import '../providers/agent_provider.dart';

/// Agent 选择对话框
class AgentSelectorDialog extends ConsumerWidget {
  final AgentConfig? currentAgent;
  final Function(AgentConfig?) onAgentSelected;

  const AgentSelectorDialog({
    super.key,
    this.currentAgent,
    required this.onAgentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(allAgentsProvider);

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(context),
            
            const Divider(height: 1),
            
            // Agent 列表
            Flexible(
              child: agentsAsync.when(
                data: (agents) => _buildAgentList(context, agents),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('加载失败: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.smart_toy, size: 24),
          const SizedBox(width: 12),
          const Text(
            '选择 Agent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentList(BuildContext context, List<AgentConfig> agents) {
    if (agents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('暂无可用的 Agent'),
        ),
      );
    }

    // 分组：内置 Agent 和自定义 Agent
    final builtInAgents = agents.where((a) => a.isBuiltIn).toList();
    final customAgents = agents.where((a) => !a.isBuiltIn).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 无 Agent 选项
        _buildAgentTile(
          context,
          null,
          '不使用 Agent',
          '直接与 AI 对话，不附加任何工具',
          Icons.chat_bubble_outline,
          false,
        ),
        
        if (builtInAgents.isNotEmpty) ...[
          const Divider(),
          _buildSectionHeader('内置 Agent'),
          ...builtInAgents.map((agent) => _buildAgentTile(
                context,
                agent,
                agent.name,
                agent.description ?? '',
                _getAgentIcon(agent.iconName),
                true,
              )),
        ],
        
        if (customAgents.isNotEmpty) ...[
          const Divider(),
          _buildSectionHeader('自定义 Agent'),
          ...customAgents.map((agent) => _buildAgentTile(
                context,
                agent,
                agent.name,
                agent.description ?? '',
                _getAgentIcon(agent.iconName),
                false,
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildAgentTile(
    BuildContext context,
    AgentConfig? agent,
    String name,
    String description,
    IconData icon,
    bool isBuiltIn,
  ) {
    final isSelected = agent?.id == currentAgent?.id;

    return ListTile(
      selected: isSelected,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
      ),
      title: Row(
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isBuiltIn) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '内置',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        onAgentSelected(agent);
        Navigator.of(context).pop();
      },
    );
  }

  IconData _getAgentIcon(String? iconName) {
    switch (iconName) {
      case 'assistant':
        return Icons.assistant;
      case 'calculate':
        return Icons.calculate;
      case 'search':
        return Icons.search;
      case 'folder':
        return Icons.folder;
      case 'code':
        return Icons.code;
      default:
        return Icons.smart_toy;
    }
  }
}

/// 显示 Agent 选择对话框的辅助函数
Future<void> showAgentSelector(
  BuildContext context, {
  required AgentConfig? currentAgent,
  required Function(AgentConfig?) onAgentSelected,
}) {
  return showDialog(
    context: context,
    builder: (context) => AgentSelectorDialog(
      currentAgent: currentAgent,
      onAgentSelected: onAgentSelected,
    ),
  );
}
