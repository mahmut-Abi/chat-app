import 'package:flutter/material.dart';
import '../../domain/conversation.dart';
import 'conversation_tags_dialog.dart';
import 'package:go_router/go_router.dart';

/// 现代化侧边栏组件
class ModernSidebar extends StatefulWidget {
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

  const ModernSidebar({
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
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar>
    with SingleTickerProviderStateMixin {
  String? _selectedGroupId;
  String? _selectedTag;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildFilterBar(context),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _filteredConversations.isEmpty
                  ? _buildEmptyState(context)
                  : _buildConversationList(context),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_rounded,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Chat App',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (widget.onSearch != null)
                IconButton(
                  icon: Icon(Icons.search, color: colorScheme.primary),
                  tooltip: '搜索',
                  onPressed: widget.onSearch,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: widget.onCreateConversation,
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建对话'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.groups.isEmpty && _allTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.groups.isNotEmpty) ...[
            Expanded(child: _buildGroupFilter(context)),
            const SizedBox(width: 8),
          ],
          if (_allTags.isNotEmpty) Expanded(child: _buildTagFilter(context)),
        ],
      ),
    );
  }

  Widget _buildGroupFilter(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: _selectedGroupId,
      decoration: InputDecoration(
        labelText: '分组',
        prefixIcon: const Icon(Icons.folder_outlined, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('全部')),
        ...widget.groups.map(
          (group) => DropdownMenuItem(value: group.id, child: Text(group.name)),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedGroupId = value);
      },
    );
  }

  Widget _buildTagFilter(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: _selectedTag,
      decoration: InputDecoration(
        labelText: '标签',
        prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('全部')),
        ..._allTags.map(
          (tag) => DropdownMenuItem(value: tag, child: Text(tag)),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedTag = value);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _getEmptyMessage(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方按钮开始新对话',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    if (_selectedGroupId != null) return '该分组暂无对话';
    if (_selectedTag != null) return '该标签暂无对话';
    return '暂无对话';
  }

  Widget _buildConversationList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = _filteredConversations[index];
        return _buildConversationItem(context, conversation);
      },
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Conversation conversation,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = widget.selectedConversation?.id == conversation.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.8)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.chat_bubble_rounded,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? colorScheme.onPrimaryContainer : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(conversation.updatedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            if (conversation.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: conversation.tags.take(2).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.2)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        onTap: () => widget.onConversationSelected(conversation),
        trailing: PopupMenuButton(
          icon: Icon(
            Icons.more_vert,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
            PopupMenuItem(
              onTap: () => widget.onRenameConversation(conversation),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('重命名'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _showTagsDialog(conversation),
              child: const Row(
                children: [
                  Icon(Icons.local_offer_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('管理标签'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              onTap: () => widget.onDeleteConversation(conversation.id),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Text('删除', style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickAccessButton(
                  context,
                  icon: Icons.psychology_outlined,
                  label: '模型',
                  onTap: () {
                    Navigator.of(context).pop();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => context.push('/models'),
                    );
                  },
                ),
                _buildQuickAccessButton(
                  context,
                  icon: Icons.lightbulb_outline,
                  label: '提示词',
                  onTap: () {
                    Navigator.of(context).pop();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => context.push('/prompts'),
                    );
                  },
                ),
                _buildQuickAccessButton(
                  context,
                  icon: Icons.smart_toy_outlined,
                  label: '智能体',
                  onTap: () {
                    Navigator.of(context).pop();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => context.push('/agent'),
                    );
                  },
                ),
                _buildQuickAccessButton(
                  context,
                  icon: Icons.extension_outlined,
                  label: 'MCP',
                  onTap: () {
                    Navigator.of(context).pop();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => context.push('/mcp'),
                    );
                  },
                ),
                _buildQuickAccessButton(
                  context,
                  icon: Icons.access_time_outlined,
                  label: 'Token',
                  onTap: () {
                    Navigator.of(context).pop();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => context.push('/token-usage'),
                    );
                  },
                ),
                _buildQuickAccessButton(
                  context,
                  icon: Icons.article_outlined,
                  label: '日志',
                  onTap: () {
                    Navigator.of(context).pop();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => context.push('/logs'),
                    );
                  },
                ),
                _buildQuickAccessButton(
                  context,
                  icon: Icons.settings_outlined,
                  label: '设置',
                  onTap: () {
                    Navigator.of(context).pop();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => context.push('/settings'),
                    );
                  },
                ),
                _buildQuickAccessButton(
                  context,
                  icon: Icons.folder_outlined,
                  label: '分组',
                  onTap: widget.onManageGroups,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays == 0) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
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
