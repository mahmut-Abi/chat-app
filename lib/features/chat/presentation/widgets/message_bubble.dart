import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/message.dart';
import '../../../../shared/widgets/enhanced_markdown_message.dart';
import '../../../../shared/widgets/message_actions.dart';
import 'dart:io';
import '../../../../core/utils/share_utils.dart';

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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context, isUser),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: isMobile ? () => _showContextMenu(context) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 显示图片附件
                    if (message.images != null && message.images!.isNotEmpty)
                      _buildImageAttachments(context),
                    if (message.images != null && message.images!.isNotEmpty)
                      const SizedBox(height: 8),
                    if (message.hasError)
                      Text(
                        message.content,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    else if (message.role == MessageRole.assistant)
                      EnhancedMarkdownMessage(content: message.content)
                    else
                      SelectableText(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.tokenCount != null) ...[
                          Text(
                            '${message.tokenCount} tokens',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 12,
                            color: Theme.of(context).dividerColor,
                          ),
                          const SizedBox(width: 8),
                        ],
                        // 移动端隐藏按钮，桌面端显示
                        if (!isMobile)
                          MessageActions(
                            isUserMessage: isUser,
                            onCopy: () => _copyMessage(context),
                            onShare: () =>
                                ShareUtils.shareText(message.content),
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
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(context, isUser),
        ],
      ),
    );
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('消息已复制'), duration: Duration(seconds: 1)),
    );
  }

  void _showContextMenu(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                ShareUtils.shareText(message.content);
              },
            ),
            if (isUser && onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
            if (!isUser && onRegenerate != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('重新生成'),
                onTap: () {
                  Navigator.pop(context);
                  onRegenerate!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  '删除',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAttachments(BuildContext context) {
    final images = message.images!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.map((image) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
        );
      }).toList(),
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
