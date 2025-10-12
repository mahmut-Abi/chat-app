import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/message.dart';
import '../../../../shared/widgets/markdown_message.dart';
import '../../../../shared/widgets/message_actions.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;
  final ValueChanged<String>? onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onRegenerate,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context, isUser),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasError)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  else if (message.role == MessageRole.assistant)
                    MarkdownMessage(
                      content: message.content,
                      isDarkMode:
                          Theme.of(context).brightness == Brightness.dark,
                    )
                  else
                    SelectableText(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MessageActions(
                        isUserMessage: isUser,
                        onCopy: () {
                          Clipboard.setData(
                            ClipboardData(text: message.content),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('消息已复制'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        onEdit: isUser && onEdit != null
                            ? () => _showEditDialog(context)
                            : null,
                        onDelete: onDelete,
                        onRegenerate: !isUser && onRegenerate != null
                            ? onRegenerate
                            : null,
                      ),
                      if (message.isStreaming)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(context, isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '输入消息内容...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && onEdit != null) {
      onEdit!(result);
    }
    controller.dispose();
  }
}
