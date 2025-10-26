import 'package:flutter/material.dart';
import '../../domain/conversation.dart';

class ConversationSearchScreen extends StatefulWidget {
  final List<Conversation> conversations;
  final ValueChanged<Conversation> onConversationSelected;

  const ConversationSearchScreen({
    super.key,
    required this.conversations,
    required this.onConversationSelected,
  });

  @override
  State<ConversationSearchScreen> createState() =>
      _ConversationSearchScreenState();
}

class _ConversationSearchScreenState extends State<ConversationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Conversation> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _filteredConversations = widget.conversations;
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = widget.conversations;
      } else {
        final searchLower = query.toLowerCase();
        _filteredConversations = widget.conversations.where((conv) {
          return conv.title.toLowerCase().contains(searchLower) ||
              conv.messages.any(
                (msg) => msg.content.toLowerCase().contains(searchLower),
              );
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: const InputDecoration(
            hintText: '搜索对话...',
            border: InputBorder.none,
            hintStyle: TextStyle(fontSize: 18),
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: _filterConversations,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _filterConversations('');
              },
            ),
        ],
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '搜索对话标题或消息内容',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredConversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到相关对话',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = _filteredConversations[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _getPreviewText(conversation),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${conversation.messages.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text('条消息', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            onTap: () {
              Navigator.of(context).pop();
              widget.onConversationSelected(conversation);
            },
          ),
        );
      },
    );
  }

  String _getPreviewText(Conversation conv) {
    if (conv.messages.isEmpty) return '无消息';
    final lastMessage = conv.messages.last;
    return lastMessage.content.replaceAll('\n', ' ');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
