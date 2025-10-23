import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/services/log_service.dart';
import '../../../core/providers/providers.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/message_utils.dart';

/// 日志查看界面
class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  LogLevel? _selectedLevel;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logService = ref.watch(logServiceProvider);
    final allLogs = logService.getAllLogs();

    // 过滤日志
    var logs = allLogs;
    if (_selectedLevel != null) {
      logs = logs.where((log) => log.level == _selectedLevel).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs
          .where((log) => log.message.toLowerCase().contains(query))
          .toList();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('程序日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出日志',
            onPressed: () => _exportLogs(logService),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清空日志',
            onPressed: () => _clearLogs(logService),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: logs.isEmpty ? _buildEmptyState() : _buildLogsList(logs),
          ),
        ],
      ),
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
              hintText: '搜索日志...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
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
                  selected: _selectedLevel == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedLevel = null);
                  },
                ),
                const SizedBox(width: 8),
                ...LogLevel.values.map(
                  (level) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getLevelText(level)),
                      selected: _selectedLevel == level,
                      onSelected: (selected) {
                        setState(
                          () => _selectedLevel = selected ? level : null,
                        );
                      },
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text('暂无日志记录', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<LogEntry> logs) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogItem(log);
      },
    );
  }

  Widget _buildLogItem(LogEntry log) {
    final dateFormat = DateFormat('HH:mm:ss');

    return Card(
      color: Theme.of(context).cardColor.withValues(alpha: 0.7),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          _getLevelIcon(log.level),
          color: _getLevelColor(log.level),
        ),
        title: Text(log.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text(
              _getLevelText(log.level),
              style: TextStyle(
                fontSize: 12,
                color: _getLevelColor(log.level),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(log.timestamp),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  log.message,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '完整时间: ${log.timestamp}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (log.extra != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '额外信息:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SelectableText(
                    log.extra.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (log.stackTrace != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '堆栈跟踪:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      log.stackTrace!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
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

  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  String _getLevelText(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.error:
        return 'Error';
    }
  }

  Future<void> _exportLogs(LogService logService) async {
    try {
      final content = logService.exportLogsAsText();
      await Clipboard.setData(ClipboardData(text: content));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('日志已复制')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _clearLogs(LogService logService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有日志吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await logService.clearLogs();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('日志已清空')));
      }
    }
  }

  Future<void> _copyLogToClipboard(LogEntry log) async {
    final buffer = StringBuffer();
    buffer.writeln('[${log.level.name.toUpperCase()}] ${log.timestamp}');
    buffer.writeln(log.message);
    if (log.stackTrace != null) {
      buffer.writeln('\nStack Trace:');
      buffer.writeln(log.stackTrace);
    }
    if (log.extra != null) {
      buffer.writeln('\nExtra: ${log.extra}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('日志已复制')));
    }
  }
}
