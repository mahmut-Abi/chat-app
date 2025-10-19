import 'package:flutter/material.dart';
import '../../domain/message.dart';
import 'message_bubble.dart';

/// 聊天消息列表组件
class ChatMessageList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final bool isMobile;
  final Function(int) onDeleteMessage;
  final Function(int) onRegenerateMessage;
  final Function(int, String) onEditMessage;
  final String? currentModelName;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isMobile,
    required this.onDeleteMessage,
    required this.onRegenerateMessage,
    required this.onEditMessage,
    this.currentModelName,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('开始新对话', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '输入消息开始与 AI 交流',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // 使用完全透明的背景，让 PageBackground 的背景图片显示出来
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.0), // 完全透明，让背景图片显示出来
      ),
      child: ListView.builder(
        controller: scrollController,
        addRepaintBoundaries: true,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: isMobile ? 60 : 16,
          bottom: 16,
        ),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return RepaintBoundary(
            child: MessageBubble(
              message: message,
              modelName: message.role == MessageRole.assistant
                  ? currentModelName
                  : null,
              onDelete: () => onDeleteMessage(index),
              onRegenerate: message.role == MessageRole.assistant
                  ? () => onRegenerateMessage(index)
                  : null,
              onEdit: (newContent) => onEditMessage(index, newContent),
            ),
          );
        },
      ),
    );
  }
}
