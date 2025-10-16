import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/conversation_log.dart';
import '../../../core/providers/providers.dart';

class ConversationLogsTab extends ConsumerStatefulWidget {
  const ConversationLogsTab({super.key});

  @override
  ConsumerState<ConversationLogsTab> createState() =>
      _ConversationLogsTabState();
}

class _ConversationLogsTabState extends ConsumerState<ConversationLogsTab> {
  ConversationLogType? _selectedType;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<ConversationLog>>(
            future: _loadLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('加载失败: \${snapshot.error}'));
              }
              final logs = snapshot.data ?? [];
              if (logs.isEmpty) return _buildEmptyState();
              return _buildLogsList(logs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索对话日志...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('全部'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = null);
                  },
                ),
                const SizedBox(width: 8),
                ...ConversationLogType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getTypeText(type)),
                      selected: _selectedType == type,
                      onSelected: (selected) => setState(
                        () => _selectedType = selected ? type : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无对话日志', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<ConversationLog> logs) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) => _buildLogItem(logs[index]),
    );
  }

  Widget _buildLogItem(ConversationLog log) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final color = _getTypeColor(log.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Icon(_getTypeIcon(log.type), color: color),
        title: Text(
          _getTypeText(log.type),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          dateFormat.format(log.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: log.tokenCount != null
            ? Chip(
                label: Text('\${log.tokenCount} tokens'),
                backgroundColor: Colors.blue.withOpacity(0.1),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.modelName != null) ..[
                  Row(
                    children: [
                      const Icon(Icons.model_training, size: 16),
                      const SizedBox(width: 8),
                      Text('模型: \${log.modelName}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (log.responseTime != null) ..[
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 8),
                      Text('响应时间: \${log.responseTime}ms'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(),
                const SizedBox(height: 8),
                SelectableText(log.content, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('复制'),
                      onPressed: () => _copyLogToClipboard(log),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<ConversationLog>> _loadLogs() async {
    final logsRepo = ref.read(logsRepositoryProvider);
    var logs = await logsRepo.getConversationLogs(type: _selectedType);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((log) => log.content.toLowerCase().contains(query)).toList();
    }

    return logs;
  }

  IconData _getTypeIcon(ConversationLogType type) {
    return switch (type) {
      ConversationLogType.userMessage => Icons.person,
      ConversationLogType.assistantMessage => Icons.smart_toy,
      ConversationLogType.systemMessage => Icons.settings,
      ConversationLogType.functionCall => Icons.functions,
      ConversationLogType.error => Icons.error,
      ConversationLogType.contextUpdate => Icons.update,
    };
  }

  Color _getTypeColor(ConversationLogType type) {
    return switch (type) {
      ConversationLogType.userMessage => Colors.blue,
      ConversationLogType.assistantMessage => Colors.green,
      ConversationLogType.systemMessage => Colors.orange,
      ConversationLogType.functionCall => Colors.purple,
      ConversationLogType.error => Colors.red,
      ConversationLogType.contextUpdate => Colors.teal,
    };
  }

  String _getTypeText(ConversationLogType type) {
    return switch (type) {
      ConversationLogType.userMessage => '用户消息',
      ConversationLogType.assistantMessage => '助手回复',
      ConversationLogType.systemMessage => '系统消息',
      ConversationLogType.functionCall => '函数调用',
      ConversationLogType.error => '错误',
      ConversationLogType.contextUpdate => '上下文更新',
    };
  }

  Future<void> _copyLogToClipboard(ConversationLog log) async {
    final buffer = StringBuffer();
    buffer.writeln('[\${_getTypeText(log.type)}] \${log.timestamp}');
    if (log.modelName != null) buffer.writeln('模型: \${log.modelName}');
    if (log.tokenCount != null) buffer.writeln('Tokens: \${log.tokenCount}');
    if (log.responseTime != null) {
      buffer.writeln('响应时间: \${log.responseTime}ms');
    }
    buffer.writeln();
    buffer.writeln(log.content);

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日志已复制')),
      );
    }
  }
}
