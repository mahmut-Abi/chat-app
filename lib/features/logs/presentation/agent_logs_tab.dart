import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/agent_log.dart';
import '../../../core/providers/providers.dart';

class AgentLogsTab extends ConsumerStatefulWidget {
  const AgentLogsTab({super.key});

  @override
  ConsumerState<AgentLogsTab> createState() => _AgentLogsTabState();
}

class _AgentLogsTabState extends ConsumerState<AgentLogsTab> {
  AgentLogType? _selectedType;
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
          child: FutureBuilder<List<AgentLog>>(
            future: _loadLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('加载失败: ${snapshot.error}'));
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
              hintText: '搜索Agent日志...',
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
                ...AgentLogType.values.map(
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
          Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无Agent日志', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<AgentLog> logs) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) => _buildLogItem(logs[index]),
    );
  }

  Widget _buildLogItem(AgentLog log) {
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
          '${log.agentName} - ${dateFormat.format(log.timestamp)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: log.executionTime != null
            ? Chip(
                label: Text('${log.executionTime}ms'),
                backgroundColor: Colors.blue.withOpacity(0.1),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.message, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(log.message)),
                  ],
                ),
                if (log.toolName != null) ..[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.build, size: 16),
                      const SizedBox(width: 8),
                      Text('工具: ${log.toolName}'),
                    ],
                  ),
                ],
                if (log.taskId != null) ..[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.task, size: 16),
                      const SizedBox(width: 8),
                      Text('任务ID: ${log.taskId}'),
                    ],
                  ),
                ],
                if (log.errorMessage != null) ..[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
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

  Future<List<AgentLog>> _loadLogs() async {
    final logsRepo = ref.read(logsRepositoryProvider);
    var logs = await logsRepo.getAgentLogs(type: _selectedType);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((log) => 
        log.message.toLowerCase().contains(query) ||
        log.agentName.toLowerCase().contains(query)
      ).toList();
    }

    return logs;
  }

  IconData _getTypeIcon(AgentLogType type) {
    return switch (type) {
      AgentLogType.taskStarted => Icons.play_arrow,
      AgentLogType.taskCompleted => Icons.check_circle,
      AgentLogType.taskFailed => Icons.error,
      AgentLogType.toolExecution => Icons.build,
      AgentLogType.decisionMaking => Icons.psychology,
      AgentLogType.stateUpdate => Icons.update,
      AgentLogType.error => Icons.error_outline,
    };
  }

  Color _getTypeColor(AgentLogType type) {
    return switch (type) {
      AgentLogType.taskStarted => Colors.blue,
      AgentLogType.taskCompleted => Colors.green,
      AgentLogType.taskFailed => Colors.red,
      AgentLogType.toolExecution => Colors.purple,
      AgentLogType.decisionMaking => Colors.teal,
      AgentLogType.stateUpdate => Colors.orange,
      AgentLogType.error => Colors.red,
    };
  }

  String _getTypeText(AgentLogType type) {
    return switch (type) {
      AgentLogType.taskStarted => '任务开始',
      AgentLogType.taskCompleted => '任务完成',
      AgentLogType.taskFailed => '任务失败',
      AgentLogType.toolExecution => '工具执行',
      AgentLogType.decisionMaking => '决策制定',
      AgentLogType.stateUpdate => '状态更新',
      AgentLogType.error => '错误',
    };
  }

  Future<void> _copyLogToClipboard(AgentLog log) async {
    final buffer = StringBuffer();
    buffer.writeln('[${_getTypeText(log.type)}] ${log.timestamp}');
    buffer.writeln('Agent: ${log.agentName}');
    buffer.writeln('消息: ${log.message}');
    if (log.taskId != null) buffer.writeln('任务ID: ${log.taskId}');
    if (log.toolName != null) buffer.writeln('工具: ${log.toolName}');
    if (log.executionTime != null) buffer.writeln('执行时间: ${log.executionTime}ms');
    if (log.errorMessage != null) buffer.writeln('错误: ${log.errorMessage}');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日志已复制')),
      );
    }
  }
}
