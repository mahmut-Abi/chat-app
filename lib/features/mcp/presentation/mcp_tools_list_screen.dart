import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../data/mcp_tools_service.dart';
import '../domain/mcp_config.dart';
import '../../../core/providers/providers.dart';

/// MCP 工具列表显示屏幕
class McpToolsListScreen extends ConsumerStatefulWidget {
  final String configId;
  final String configName;

  const McpToolsListScreen({
    required this.configId,
    required this.configName,
    super.key,
  });

  @override
  ConsumerState<McpToolsListScreen> createState() => _McpToolsListScreenState();
}

class _McpToolsListScreenState extends ConsumerState<McpToolsListScreen> {
  late McpToolsService _toolsService;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final repository = ref.read(mcpRepositoryProvider);
    _toolsService = McpToolsService(repository);
  }

  @override
  Widget build(BuildContext context) {
    final toolsAsync = ref.watch(mcpToolsProvider(widget.configId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MCP 工具列表'),
            Text(
              widget.configName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索工具...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: toolsAsync.when(
              data: (tools) {
                final filteredTools = _filterTools(tools, _searchQuery);
                if (filteredTools.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildToolsList(context, filteredTools);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text('加载失败'),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterTools(
    List<Map<String, dynamic>> tools,
    String query,
  ) {
    if (query.isEmpty) return tools;

    final lowercaseQuery = query.toLowerCase();
    return tools.where((tool) {
      final name = (tool['name'] as String? ?? '').toLowerCase();
      final description = (tool['description'] as String? ?? '').toLowerCase();
      return name.contains(lowercaseQuery) || description.contains(lowercaseQuery);
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_circle_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '暂无工具' : '未找到匹配的工具',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildToolsList(
    BuildContext context,
    List<Map<String, dynamic>> tools,
  ) {
    return ListView.builder(
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        final toolName = tool['name'] as String? ?? 'Unknown';
        final toolDescription = tool['description'] as String? ?? '';
        final parameters = tool['parameters'] as Map<String, dynamic>? ?? {};

        return Card(
          color: Theme.of(context).cardColor.withValues(alpha: 0.7),
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: ExpansionTile(
            title: Text(toolName),
            subtitle: toolDescription.isNotEmpty
                ? Text(
                    toolDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            leading: Icon(
              Icons.build,
              color: Theme.of(context).colorScheme.primary,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (toolDescription.isNotEmpty) ...[                      Text(
                        '描述',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        toolDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      '参数',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (parameters.isEmpty)
                      Text(
                        '无参数',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      _buildParametersView(context, parameters),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParametersView(
    BuildContext context,
    Map<String, dynamic> parameters,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: SelectableText(
          _formatJson(parameters),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }

  String _formatJson(Map<String, dynamic> data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}
