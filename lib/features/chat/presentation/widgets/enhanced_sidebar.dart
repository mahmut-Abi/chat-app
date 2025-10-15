import 'package:flutter/material.dart';
import '../../domain/conversation.dart';
import 'conversation_tags_dialog.dart';
import 'sidebar_header.dart';
import 'sidebar_filter_bar.dart';
import 'sidebar_footer.dart';

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
  final VoidCallback? onSearch;

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
    this.onSearch,
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
      filtered = filtered.where((c) => c.groupId == _selectedGroupId).toList();
    }

    if (_selectedTag != null) {
      filtered = filtered.where((c) => c.tags.contains(_selectedTag)).toList();
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
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          SidebarHeader(
            onCreateConversation: widget.onCreateConversation,
            onManageGroups: widget.onManageGroups,
            onSearch: widget.onSearch,
          ),
          SidebarFilterBar(
            groups: widget.groups,
            allTags: _allTags,
            selectedGroupId: _selectedGroupId,
            selectedTag: _selectedTag,
            onGroupSelected: (groupId) {
              setState(() => _selectedGroupId = groupId);
            },
            onTagSelected: (tag) {
              setState(() => _selectedTag = tag);
            },
          ),
          Expanded(
            child: _filteredConversations.isEmpty
                ? _buildEmptyState()
                : _buildConversationList(),
          ),
          const SidebarFooter(),
        ],
      ),
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
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无对话',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
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
          leading: Icon(
            Icons.chat_bubble_outline,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          title: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(conversation.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (conversation.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: conversation.tags.take(2).map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
            ],
          ),
          onTap: () => widget.onConversationSelected(conversation),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('重命名'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onRenameConversation(conversation);
                  },
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.local_offer),
                  title: const Text('管理标签'),
                  onTap: () {
                    Navigator.pop(context);
                    _showTagsDialog(conversation);
                  },
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('删除', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDeleteConversation(conversation.id);
                  },
                ),
              ),
            ],
          ),
        );
      },
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
      builder: (context) =>
          ConversationTagsDialog(initialTags: conversation.tags),
    );

    if (result != null) {
      widget.onUpdateTags(conversation, result);
    }
  }
}
