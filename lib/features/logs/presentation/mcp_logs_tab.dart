import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/mcp_log.dart';
import '../../../core/providers/providers.dart';

class McpLogsTab extends ConsumerStatefulWidget {
  const McpLogsTab({super.key});

  @override
  ConsumerState<McpLogsTab> createState() => _McpLogsTabState();
}

class _McpLogsTabState extends ConsumerState<McpLogsTab> {
  McpLogType? _selectedType;
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
          child: FutureBuilder<List<McpLog>>(
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
              hintText: '搜索MCP日志...',
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
                ...McpLogType.values.map(
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
          Icon(Icons.extension_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无MCP日志', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<McpLog> logs) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) => _buildLogItem(logs[index]),
    );
  }

  Widget _buildLogItem(McpLog log) {
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
          '${log.mcpName} - ${dateFormat.format(log.timestamp)}',
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

  Future<List<McpLog>> _loadLogs() async {
    final logsRepo = ref.read(logsRepositoryProvider);
    var logs = await logsRepo.getMcpLogs(type: _selectedType);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((log) => 
        log.message.toLowerCase().contains(query) ||
        log.mcpName.toLowerCase().contains(query)
      ).toList();
    }

    return logs;
  }

  IconData _getTypeIcon(McpLogType type) {
    return switch (type) {
      McpLogType.toolCall => Icons.play_arrow,
      McpLogType.toolResponse => Icons.check_circle,
      McpLogType.connectionEstablished => Icons.link,
      McpLogType.connectionFailed => Icons.link_off,
      McpLogType.error => Icons.error,
      McpLogType.configUpdate => Icons.settings,
    };
  }

  Color _getTypeColor(McpLogType type) {
    return switch (type) {
      McpLogType.toolCall => Colors.blue,
      McpLogType.toolResponse => Colors.green,
      McpLogType.connectionEstablished => Colors.teal,
      McpLogType.connectionFailed => Colors.orange,
      McpLogType.error => Colors.red,
      McpLogType.configUpdate => Colors.purple,
    };
  }

  String _getTypeText(McpLogType type) {
    return switch (type) {
      McpLogType.toolCall => '工具调用',
      McpLogType.toolResponse => '工具响应',
      McpLogType.connectionEstablished => '连接成功',
      McpLogType.connectionFailed => '连接失败',
      McpLogType.error => '错误',
      McpLogType.configUpdate => '配置更新',
    };
  }

  Future<void> _copyLogToClipboard(McpLog log) async {
    final buffer = StringBuffer();
    buffer.writeln('[${_getTypeText(log.type)}] ${log.timestamp}');
    buffer.writeln('MCP: ${log.mcpName}');
    buffer.writeln('消息: ${log.message}');
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
