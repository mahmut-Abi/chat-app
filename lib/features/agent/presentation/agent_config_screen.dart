import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/agent_tool.dart';
import '../../../core/providers/providers.dart';

class AgentConfigScreen extends ConsumerStatefulWidget {
  final AgentConfig? config;

  const AgentConfigScreen({super.key, this.config});

  @override
  ConsumerState<AgentConfigScreen> createState() => _AgentConfigScreenState();
}

class _AgentConfigScreenState extends ConsumerState<AgentConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _systemPromptController;

  late Set<String> _selectedToolIds;
  late bool _enabled;

  @override
  void initState() {
    super.initState();

    final config = widget.config;
    _nameController = TextEditingController(text: config?.name ?? '');
    _descriptionController = TextEditingController(
      text: config?.description ?? '',
    );
    _systemPromptController = TextEditingController(
      text: config?.systemPrompt ?? '',
    );

    _selectedToolIds = Set.from(config?.toolIds ?? []);
    _enabled = config?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolsAsync = ref.watch(agentToolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? '创建 Agent' : '编辑 Agent'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicSection(),
            const SizedBox(height: 24),
            _buildToolsSection(toolsAsync),
            const SizedBox(height: 24),
            _buildSystemPromptSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSection() {
    return Card(
      color: Theme.of(context).cardColor.withValues(alpha: 0.7),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('基本信息', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Agent 名称 *',
                hintText: '例如: 代码助手',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.smart_toy),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入 Agent 名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述 (可选)',
                hintText: '描述该 Agent 的功能和用途',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用 Agent'),
              subtitle: const Text('启用后可在聊天中使用该 Agent'),
              value: _enabled,
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection(AsyncValue<List<AgentTool>> toolsAsync) {
    return Card(
      color: Theme.of(context).cardColor.withValues(alpha: 0.7),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('可用工具', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '选择该 Agent 可以使用的工具',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            toolsAsync.when(
              data: (tools) {
                if (tools.isEmpty) {
                  return const Text('暂无可用工具');
                }
                return Column(
                  children: tools.map((tool) {
                    final isSelected = _selectedToolIds.contains(tool.id);
                    return CheckboxListTile(
                      title: Text(tool.name),
                      subtitle: Text(tool.description),
                      value: isSelected,
                      secondary: Icon(_getToolIcon(tool.type)),
                      enabled: tool.enabled,
                      onChanged: tool.enabled
                          ? (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedToolIds.add(tool.id);
                                } else {
                                  _selectedToolIds.remove(tool.id);
                                }
                              });
                            }
                          : null,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Text('加载失败: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemPromptSection() {
    return Card(
      color: Theme.of(context).cardColor.withValues(alpha: 0.7),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('系统提示词', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '定义 Agent 的行为和个性',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _systemPromptController,
              decoration: const InputDecoration(
                labelText: '系统提示词 (可选)',
                hintText: '例如: 你是一个专业的代码助手，擅长...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(onPressed: _saveConfig, child: const Text('保存')),
        ),
      ],
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

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final config = AgentConfig(
        id: widget.config?.id ?? _uuid.v4(),
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        toolIds: _selectedToolIds.toList(),
        systemPrompt: _systemPromptController.text.isEmpty
            ? null
            : _systemPromptController.text,
        enabled: _enabled,
        createdAt: widget.config?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(agentRepositoryProvider);
      await repository.saveConfig(config);

      // 刷新 Agent 配置列表
      ref.invalidate(agentConfigsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }
}
