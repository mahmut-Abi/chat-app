import 'package:flutter/material.dart';
import '../../domain/conversation.dart';

// 分组管理对话框
class GroupManagementDialog extends StatefulWidget {
  final List<ConversationGroup> groups;
  final Function(String name, String? color) onCreateGroup;
  final Function(ConversationGroup group) onUpdateGroup;
  final Function(String id) onDeleteGroup;

  const GroupManagementDialog({
    super.key,
    required this.groups,
    required this.onCreateGroup,
    required this.onUpdateGroup,
    required this.onDeleteGroup,
  });

  @override
  State<GroupManagementDialog> createState() => _GroupManagementDialogState();
}

class _GroupManagementDialogState extends State<GroupManagementDialog> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
  ];

  void _addGroup() {
    if (_nameController.text.trim().isNotEmpty) {
      widget.onCreateGroup(
        _nameController.text.trim(),
        '#${_selectedColor.r.toRadixString(16).substring(2)}',
      );
      _nameController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('管理分组'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 添加新分组
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '分组名称...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addGroup(),
                  ),
                ),
                const SizedBox(width: 8),
                // 颜色选择
                DropdownButton<Color>(
                 .r: _selectedColor,
                  items: _availableColors.map((color) {
                    return DropdownMenuItem(
                     .r: color,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (color) {
                    if (color != null) {
                      setState(() {
                        _selectedColor = color;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addGroup,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // 现有分组列表
            if (widget.groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('暂无分组'),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: widget.groups.length,
                  itemBuilder: (context, index) {
                    final group = widget.groups[index];
                    return ListTile(
                      leading: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: group.color != null
                              ? Color(
                                  int.parse('0xFF${group.color!.substring(1)}'),
                                )
                              : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(group.name),
                      subtitle: Text('创建于 ${_formatDate(group.createdAt)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteConfirmation(group),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(ConversationGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定要删除分组"${group.name}"吗？\n该分组中的对话将移至未分组。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.onDeleteGroup(group.id);
      setState(() {});
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
