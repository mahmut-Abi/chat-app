import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/message.dart';
import '../../../../shared/widgets/enhanced_markdown_message.dart';
import '../../../../shared/widgets/message_actions.dart';
import 'dart:io';
import 'image_viewer_screen.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;
  final ValueChanged<String>? onEdit;
  final String? modelName;

  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onRegenerate,
    this.onEdit,
    this.modelName,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isMobile = MediaQuery.of(context).size.width < 600;

    // 使用 RepaintBoundary 减少不必要的重绘
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: isUser
            ? _buildUserMessage(context, isMobile)
            : _buildAssistantMessage(context, isMobile),
      ),
    );
  }

  // 用户消息布局：头像在右上角
  Widget _buildUserMessage(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 头像和名称在右上方
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '用户',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              _buildAvatar(context, true),
            ],
          ),
        ),
        // 消息内容右对齐
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(child: _buildMessageContent(context, isMobile, true)),
          ],
        ),
      ],
    );
  }

  // AI助手消息布局：头像在左上角
  Widget _buildAssistantMessage(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像和名称在左上方
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _buildAvatar(context, false),
              const SizedBox(width: 8),
              Text(
                modelName ?? 'AI 助手',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // 消息内容左对齐
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(child: _buildMessageContent(context, isMobile, false)),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageContent(
    BuildContext context,
    bool isMobile,
    bool isUser,
  ) {
    return GestureDetector(
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
        return GestureDetector(
          onTap: () => _showImageViewer(context, image.path),
          child: ClipRRect(
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
          ),
        );
      }).toList(),
    );
  }

  void _showImageViewer(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ImageViewerScreen(imagePath: imagePath),
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
