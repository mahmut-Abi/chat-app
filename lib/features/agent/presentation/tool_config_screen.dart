import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/agent_tool.dart';
import '../../../core/providers/providers.dart';

class ToolConfigScreen extends ConsumerStatefulWidget {
  final AgentTool? tool;

  const ToolConfigScreen({super.key, this.tool});

  @override
  ConsumerState<ToolConfigScreen> createState() => _ToolConfigScreenState();
}

class _ToolConfigScreenState extends ConsumerState<ToolConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late AgentToolType _selectedType;
  late bool _enabled;

  @override
  void initState() {
    super.initState();

    final tool = widget.tool;
    _nameController = TextEditingController(text: tool?.name ?? '');
    _descriptionController = TextEditingController(
      text: tool?.description ?? '',
    );

    _selectedType = tool?.type ?? AgentToolType.custom;
    _enabled = tool?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tool == null ? '添加工具' : '编辑工具')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicSection(),
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
            Text('工具信息', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '工具名称 *',
                hintText: '例如: 网络搜索',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入工具名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AgentToolType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: '工具类型',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: AgentToolType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getToolIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(_getToolTypeName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '描述该工具的功能和用途',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用工具'),
              subtitle: const Text('启用后可在 Agent 中使用该工具'),
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
          child: FilledButton(onPressed: _saveTool, child: const Text('保存')),
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

  String _getToolTypeName(AgentToolType type) {
    switch (type) {
      case AgentToolType.search:
        return '网络搜索';
      case AgentToolType.codeExecution:
        return '代码执行';
      case AgentToolType.fileOperation:
        return '文件操作';
      case AgentToolType.calculator:
        return '计算器';
      case AgentToolType.custom:
        return '自定义';
    }
  }

  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final repository = ref.read(agentRepositoryProvider);

      if (widget.tool == null) {
        // 创建新工具
        await repository.createTool(
          name: _nameController.text,
          description: _descriptionController.text,
          type: _selectedType,
        );
      } else {
        // 更新工具
        final updatedTool = AgentTool(
          id: widget.tool!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          type: _selectedType,
          enabled: _enabled,
        );
        await repository.updateTool(updatedTool);
      }

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
