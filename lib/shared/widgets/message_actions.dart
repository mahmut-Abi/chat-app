import 'package:flutter/material.dart';

class MessageActions extends StatelessWidget {
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;
  final bool isUserMessage;

  const MessageActions({
    super.key,
    this.onCopy,
    this.onRegenerate,
    this.onDelete,
    this.isUserMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    
    if (onCopy != null) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: onCopy,
          tooltip: '复制',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }
    
    if (!isUserMessage && onRegenerate != null) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 8));
      }
      actions.add(
        IconButton(
          icon: const Icon(Icons.refresh, size: 16),
          onPressed: onRegenerate,
          tooltip: '重新生成',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }
    
    if (onDelete != null) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 8));
      }
      actions.add(
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 16),
          onPressed: onDelete,
          tooltip: '删除',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }
}
