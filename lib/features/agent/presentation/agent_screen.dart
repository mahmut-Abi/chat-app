import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/agent_tool.dart';

/// Agent 管理界面
class AgentScreen extends ConsumerStatefulWidget {
  const AgentScreen({super.key});

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  final List<AgentConfig> _agents = [];
  final List<AgentTool> _tools = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agent 管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Agent', icon: Icon(Icons.smart_toy)),
              Tab(text: '工具', icon: Icon(Icons.build)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAgentTab(),
            _buildToolsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddAgentDialog,
            icon: const Icon(Icons.add),
            label: const Text('创建 Agent'),
          ),
        ),
        Expanded(
          child: _agents.isEmpty
              ? _buildEmptyState('暂无 Agent')
              : _buildAgentList(),
        ),
      ],
    );
  }

  Widget _buildToolsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddToolDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加工具'),
          ),
        ),
        Expanded(
          child: _tools.isEmpty
              ? _buildEmptyState('暂无工具')
              : _buildToolsList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAgentList() {
    return ListView.builder(
      itemCount: _agents.length,
      itemBuilder: (context, index) {
        final agent = _agents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.smart_toy),
            title: Text(agent.name),
            subtitle: Text(agent.description ?? '无描述'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: agent.enabled,
                  onChanged: (value) {
                    // TODO: 实现启用/禁用
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAgent(agent.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolsList() {
    return ListView.builder(
      itemCount: _tools.length,
      itemBuilder: (context, index) {
        final tool = _tools[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(_getToolIcon(tool.type)),
            title: Text(tool.name),
            subtitle: Text(tool.description),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTool(tool.id),
            ),
          ),
        );
      },
    );
  }

  IconData _getToolIcon(AgentToolType type) {
    switch (type) {
      case AgentToolType.search:
        return Icons.search;
      case AgentToolType.codeExecution:
        return Icons.code;
      case AgentToolType.fileOperation:
        return Icons.folder;
      case AgentToolType.calculator:
        return Icons.calculate;
      case AgentToolType.custom:
        return Icons.extension;
    }
  }

  Future<void> _showAddAgentDialog() async {
    // TODO: 实现创建 Agent 对话框
  }

  Future<void> _showAddToolDialog() async {
    // TODO: 实现添加工具对话框
  }

  void _deleteAgent(String id) {
    // TODO: 实现删除 Agent
  }

  void _deleteTool(String id) {
    // TODO: 实现删除工具
  }
}
