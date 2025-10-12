import 'package:flutter/material.dart';

class MessageActions extends StatelessWidget {
  final bool isUserMessage;
  final VoidCallback onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;

  const MessageActions({
    super.key,
    required this.isUserMessage,
    required this.onCopy,
    this.onShare,
    this.onEdit,
    this.onDelete,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onCopy,
          tooltip: 'Copy',
        ),
        if (onShare != null) const SizedBox(width: 8),
        if (onShare != null)
          IconButton(
            icon: const Icon(Icons.share, size: 16),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onShare,
            tooltip: '分享',
          ),
        if (onEdit != null) const SizedBox(width: 8),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
        if (onRegenerate != null) const SizedBox(width: 8),
        if (onRegenerate != null)
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onRegenerate,
            tooltip: 'Regenerate',
          ),
        if (onDelete != null) const SizedBox(width: 8),
        if (onDelete != null)
          IconButton(
            icon: Icon(
              Icons.delete,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
      ],
    );
  }
}
