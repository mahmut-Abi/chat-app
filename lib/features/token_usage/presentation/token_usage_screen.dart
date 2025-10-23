import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/providers/providers.dart';
import '../domain/token_record.dart';
import 'package:intl/intl.dart';

/// Token 消耗记录页面
class TokenUsageScreen extends ConsumerWidget {
  const TokenUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRepo = ref.watch(chatRepositoryProvider);
    final conversations = chatRepo.getAllConversations();

    // 计算总 token 消耗
    int totalTokens = 0;
    final List<TokenRecord> records = [];

    for (final conv in conversations) {
      for (final msg in conv.messages) {
        if (msg.tokenCount != null && msg.tokenCount! > 0) {
          totalTokens += msg.tokenCount!;
          records.add(
            TokenRecord(
              id: '${conv.id}_${msg.id}',
              conversationId: conv.id,
              conversationTitle: conv.title,
              messageId: msg.id,
              model:
                  conv.settings['model'] as String? ??
                  msg.model ??
                  'gpt-3.5-turbo',
              promptTokens: msg.promptTokens ?? 0, // 如果消息有 promptTokens 则使用
              completionTokens: msg.tokenCount!,
              totalTokens: msg.tokenCount!,
              timestamp: msg.timestamp,
              messagePreview: msg.content.length > 50
                  ? '${msg.content.substring(0, 50)}...'
                  : msg.content,
            ),
          );
        }
      }
    }

    // 按时间排序
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Token 消耗记录'),
      ),
      body: Column(
        children: [
          _buildSummaryCard(context, totalTokens, records.length),
          const Divider(height: 1),
          Expanded(
            child: records.isEmpty
                ? _buildEmptyState(context)
                : _buildRecordsList(context, records),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    int totalTokens,
    int recordCount,
  ) {
    return Card(
      color: Theme.of(context).cardColor.withValues(alpha: 0.7),
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              '总消耗',
              '$totalTokens',
              Icons.token,
              Colors.blue,
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            _buildStatItem(
              context,
              '记录数',
              '$recordCount',
              Icons.receipt_long,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text('暂无 Token 消耗记录', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '开始对话后将显示 Token 消耗',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, List<TokenRecord> records) {
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildRecordItem(context, record);
      },
    );
  }

  Widget _buildRecordItem(BuildContext context, TokenRecord record) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.chat_bubble_outline,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        record.conversationTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (record.messagePreview != null)
            Text(
              record.messagePreview!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(record.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${record.totalTokens}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text('tokens', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
