import 'package:flutter/material.dart';
import '../../domain/agent_tool.dart';
import '../../../agent/data/unified_tool_service.dart';
import '../../../agent/domain/agent_tool.dart' as agent_domain;

/// Agent 选择器组件
class AgentSelector extends StatelessWidget {
  final List<AgentConfig> agents;
  final AgentConfig? selectedAgent;
  final ValueChanged<AgentConfig?> onChanged;

  const AgentSelector({
    super.key,
    required this.agents,
    this.selectedAgent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.amber[700],
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '没有可用的 Agent，请先配置',
                style: TextStyle(color: Colors.amber[700], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agent',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButton<AgentConfig>(
          value: selectedAgent,
          isExpanded: true,
          hint: const Text('选择 Agent...'),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('没有 Agent'),
            ),
            ...agents.map(
              (agent) => DropdownMenuItem(
                value: agent,
                child: Row(
                  children: [
                    if (agent.iconName != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.build,
                          size: 16,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(agent.name),
                          if (agent.description != null)
                            Text(
                              agent.description!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
        if (selectedAgent != null) ...[]
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '配置信息',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                if (selectedAgent!.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '描述: \${selectedAgent!.description}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                Text(
                  '工具数量: \${selectedAgent!.toolIds.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
