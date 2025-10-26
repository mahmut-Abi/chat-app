import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/agent_tool.dart';
import '../../../../core/providers/providers.dart';
import '../agent_config_screen.dart';

/// Agent 列表项
class AgentListItem extends ConsumerWidget {
  final AgentConfig agent;
  final VoidCallback onDelete;

  const AgentListItem({super.key, required this.agent, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Theme.of(context).cardColor.withValues(alpha: 0.7),
      elevation: 2,
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
                    fullscreenDialog: true,
                    builder: (context) => AgentConfigScreen(config: agent),
                  ),
                );
                if (result == true) ref.invalidate(agentConfigsProvider);
              },
            ),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
