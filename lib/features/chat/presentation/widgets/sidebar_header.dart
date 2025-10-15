import 'package:flutter/material.dart';

class SidebarHeader extends StatelessWidget {
  final VoidCallback onCreateConversation;
  final VoidCallback onManageGroups;
  final VoidCallback? onSearch;

  const SidebarHeader({
    super.key,
    required this.onCreateConversation,
    required this.onManageGroups,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Chat App',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (onSearch != null)
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: '搜索对话',
                  onPressed: onSearch,
                ),
              IconButton(
                icon: const Icon(Icons.folder_outlined),
                tooltip: '管理分组',
                onPressed: onManageGroups,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreateConversation,
              icon: const Icon(Icons.add),
              label: const Text('新建对话'),
            ),
          ),
        ],
      ),
    );
  }
}
