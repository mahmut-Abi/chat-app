import 'package:flutter/material.dart';
import '../../domain/conversation.dart';

class ConversationSearch extends StatefulWidget {
  final List<Conversation> conversations;
  final ValueChanged<Conversation> onConversationSelected;

  const ConversationSearch({
    super.key,
    required this.conversations,
    required this.onConversationSelected,
  });

  @override
  State<ConversationSearch> createState() => _ConversationSearchState();
}

class _ConversationSearchState extends State<ConversationSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _filteredConversations = widget.conversations;
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = widget.conversations;
      } else {
        _filteredConversations = widget.conversations.where((conv) {
          return conv.title.toLowerCase().contains(query.toLowerCase()) ||
              conv.messages.any(
                (msg) =>
                    msg.content.toLowerCase().contains(query.toLowerCase()),
              );
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索对话...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterConversations('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _filterConversations,
          ),
        ),
        Expanded(
          child: _filteredConversations.isEmpty
              ? Center(
                  child: Text(
                    '未找到匹配的对话',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conv = _filteredConversations[index];
                    return ListTile(
                      title: Text(conv.title),
                      subtitle: Text(
                        _getPreviewText(conv),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatDate(conv.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () => widget.onConversationSelected(conv),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getPreviewText(Conversation conv) {
    if (conv.messages.isEmpty) return '无消息';
    return conv.messages.last.content;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
