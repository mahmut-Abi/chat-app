import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/agent_tool.dart';
import '../../../../core/providers/providers.dart';
import '../tool_config_screen.dart';

/// 工具列表项
class ToolListItem extends ConsumerWidget {
  final AgentTool tool;
  final VoidCallback onDelete;

  const ToolListItem({super.key, required this.tool, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Theme.of(context).cardColor.withValues(alpha: 0.7),
      elevation: 2,
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
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => ToolConfigScreen(tool: tool),
                  ),
                );
                if (result == true) ref.invalidate(agentToolsProvider);
              },
            ),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
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
}
