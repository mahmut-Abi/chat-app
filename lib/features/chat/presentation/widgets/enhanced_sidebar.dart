import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/conversation.dart';
import 'conversation_tags_dialog.dart';

// 增强版侧边栏组件
class EnhancedSidebar extends StatefulWidget {
  final List<Conversation> conversations;
  final List<ConversationGroup> groups;
  final Conversation? selectedConversation;
  final Function(Conversation) onConversationSelected;
  final Function() onCreateConversation;
  final Function(String id) onDeleteConversation;
  final Function(Conversation) onRenameConversation;
  final Function(Conversation, List<String>) onUpdateTags;
  final Function() onManageGroups;

  const EnhancedSidebar({
    super.key,
    required this.conversations,
    required this.groups,
    required this.selectedConversation,
    required this.onConversationSelected,
    required this.onCreateConversation,
    required this.onDeleteConversation,
    required this.onRenameConversation,
    required this.onUpdateTags,
    required this.onManageGroups,
  });

  @override
  State<EnhancedSidebar> createState() => _EnhancedSidebarState();
}

class _EnhancedSidebarState extends State<EnhancedSidebar> {
  String? _selectedGroupId;
  String? _selectedTag;

  List<Conversation> get _filteredConversations {
    var filtered = widget.conversations;

    if (_selectedGroupId != null) {
      filtered = filtered
          .where((c) => c.groupId == _selectedGroupId)
          .toList();
    }

    if (_selectedTag != null) {
      filtered = filtered
          .where((c) => c.tags.contains(_selectedTag))
          .toList();
    }

    return filtered;
  }

  Set<String> get _allTags {
    final tags = <String>{};
    for (final conv in widget.conversations) {
      tags.addAll(conv.tags);
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: _filteredConversations.isEmpty
                ? _buildEmptyState()
                : _buildConversationList(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Chat App',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.folder_outlined),
                tooltip: '管理分组',
                onPressed: widget.onManageGroups,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onCreateConversation,
              icon: const Icon(Icons.add),
              label: const Text('新建对话'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分组筛选
          if (widget.groups.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.folder, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _selectedGroupId,
                    hint: const Text('所有分组'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('所有分组'),
                      ),
                      ...widget.groups.map((group) {
                        return DropdownMenuItem(
                          value: group.id,
                          child: Row(
                            children: [
                              if (group.color != null)
                                Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                          '0xFF${group.color!.substring(1)}',
                                      ),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(group.name),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGroupId = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // 标签筛选
          if (_allTags.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.label, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (_selectedTag != null)
                        FilterChip(
                          label: Text(_selectedTag!),
                          selected: true,
                          onSelected: (_) {
                            setState(() {
                              _selectedTag = null;
                            });
                          },
                        ),
                      if (_selectedTag == null)
                        ..._allTags.take(3).map((tag) {
                          return ActionChip(
                            label: Text(tag),
                            onPressed: () {
                              setState(() {
                                _selectedTag = tag;
                              });
                            },
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    return ListView.builder(
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = _filteredConversations[index];
        final isSelected = widget.selectedConversation?.id == conversation.id;

        return ListTile(
          selected: isSelected,
          leading: const Icon(Icons.chat_bubble_outline),
          title: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: conversation.tags.isNotEmpty
              ? Wrap(
                  spacing: 4,
                  children: conversation.tags.take(2).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 10),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                )
              : Text(
                  _formatDate(conversation.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('重命名'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tags',
                child: Row(
                  children: [
                    Icon(Icons.label),
                    SizedBox(width: 8),
                    Text('管理标签'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  widget.onRenameConversation(conversation);
                  break;
                case 'tags':
                  _showTagsDialog(conversation);
                  break;
                case 'delete':
                  widget.onDeleteConversation(conversation.id);
                  break;
              }
            },
          ),
          onTap: () => widget.onConversationSelected(conversation),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无对话',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('设置'),
        onTap: () {
          context.push('/settings');
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Future<void> _showTagsDialog(Conversation conversation) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => ConversationTagsDialog(
        initialTags: conversation.tags,
      ),
    );

    if (result != null) {
      widget.onUpdateTags(conversation, result);
    }
  }
}
