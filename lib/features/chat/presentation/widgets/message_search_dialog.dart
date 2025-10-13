import 'package:flutter/material.dart';
import '../../domain/conversation.dart';
import '../../domain/message.dart';

// 消息搜索对话框
class MessageSearchDialog extends StatefulWidget {
  final Conversation conversation;
  final Function(int) onMessageSelected;

  const MessageSearchDialog({
    super.key,
    required this.conversation,
    required this.onMessageSelected,
  });

  @override
  State<MessageSearchDialog> createState() => _MessageSearchDialogState();
}

class _MessageSearchDialogState extends State<MessageSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<MapEntry<int, Message>> _searchResults = [];

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = <MapEntry<int, Message>>[];
    final lowerQuery = query.toLowerCase();

    for (int i = 0; i < widget.conversation.messages.length; i++) {
      final message = widget.conversation.messages[i];
      if (message.content.toLowerCase().contains(lowerQuery)) {
        results.add(MapEntry(i, message));
      }
    }

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('搜索消息'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '输入关键词...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 16),
            if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
              const Expanded(child: Center(child: Text('未找到匹配的消息')))
            else if (_searchResults.isEmpty)
              const Expanded(child: Center(child: Text('请输入关键词开始搜索')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final entry = _searchResults[index];
                    final message = entry.value;
                    final messageIndex = entry.key;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          message.role == MessageRole.user
                              ? Icons.person
                              : Icons.smart_toy,
                          color: message.role == MessageRole.user
                              ? Colors.blue
                              : Colors.green,
                        ),
                        title: Text(
                          message.content.length > 100
                              ? '${message.content.substring(0, 100)}...'
                              : message.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${message.role == MessageRole.user ? "用户" : "AI"} • ${_formatTime(message.timestamp)}',
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onMessageSelected(messageIndex);
                        },
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
