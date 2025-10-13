import 'package:flutter/material.dart';

/// 批量操作工具栏
class BatchActionsBar extends StatelessWidget {
  final Set<String> selectedIds;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onAddTags;

  const BatchActionsBar({
    super.key,
    required this.selectedIds,
    required this.onCancel,
    required this.onDelete,
    required this.onExport,
    required this.onAddTags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
            tooltip: '取消',
          ),
          const SizedBox(width: 8),
          Text(
            '已选择 ${selectedIds.length} 项',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.label),
            onPressed: onAddTags,
            tooltip: '添加标签',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: onExport,
            tooltip: '导出',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
            tooltip: '删除',
          ),
        ],
      ),
    );
  }
}
