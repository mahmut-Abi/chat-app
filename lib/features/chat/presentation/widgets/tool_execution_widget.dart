import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/message_utils.dart';

/// 工具执行结果显示组件
class ToolExecutionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> toolResults;

  const ToolExecutionWidget({super.key, required this.toolResults});

  @override
  State<ToolExecutionWidget> createState() => _ToolExecutionWidgetState();
}

class _ToolExecutionWidgetState extends State<ToolExecutionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '工具调用 (${widget.toolResults.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ..._buildExpandedContent(context),
        ],
      ),
    );
  }

  List<Widget> _buildExpandedContent(BuildContext context) {
    return widget.toolResults.asMap().entries.map((entry) {
      final index = entry.key;
      final result = entry.value;
      final isSuccess = result['success'] == true;

      return Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSuccess
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  '工具 ${index + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _copyResult(context, result),
                  tooltip: '复制结果',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isSuccess && result['result'] != null) ...[
              Text(
                '结果:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  result['result'].toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ] else if (!isSuccess && result['error'] != null) ...[
              Text(
                '错误:',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  result['error'].toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            if (result['metadata'] != null && result['metadata'] is Map) ...[
              const SizedBox(height: 8),
              Text(
                '详情:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              _buildMetadata(context, result['metadata']),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMetadata(BuildContext context, Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: metadata.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '${entry.key}:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _copyResult(BuildContext context, Map<String, dynamic> result) {
    final text = result['success'] == true
        ? result['result']?.toString() ?? ''
        : result['error']?.toString() ?? '';

    Clipboard.setData(ClipboardData(text: text));
    MessageUtils.showCopied(context);
  }
}
