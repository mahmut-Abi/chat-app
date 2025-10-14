import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/prompt_template.dart';
import '../../../core/providers/providers.dart';

class PromptConfigScreen extends ConsumerStatefulWidget {
  final PromptTemplate? template;

  const PromptConfigScreen({super.key, this.template});

  @override
  ConsumerState<PromptConfigScreen> createState() => _PromptConfigScreenState();
}

class _PromptConfigScreenState extends ConsumerState<PromptConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;

  late bool _isFavorite;

  @override
  void initState() {
    super.initState();

    final template = widget.template;
    _nameController = TextEditingController(text: template?.name ?? '');
    _contentController = TextEditingController(text: template?.content ?? '');
    _categoryController = TextEditingController(
      text: template?.category ?? '通用',
    );
    _tagsController = TextEditingController(
      text: template?.tags.join(', ') ?? '',
    );

    _isFavorite = template?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? '创建提示词模板' : '编辑提示词模板'),
        actions: [
          if (widget.template != null)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              tooltip: '收藏',
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicSection(),
            const SizedBox(height: 24),
            _buildContentSection(),
            const SizedBox(height: 24),
            _buildMetadataSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSection() {
    return Card(
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
                labelText: '模板名称 *',
                hintText: '例如: 代码审查助手',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入模板名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: '分类',
                hintText: '例如: 编程、写作、翻译',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('提示词内容', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '支持变量: {{variable_name}}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '内容 *',
                hintText: '输入提示词模板内容...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入提示词内容';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              '字数: ${_contentController.text.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('标签与属性', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '用逗号分隔,例如: 编程, Python, 代码审查',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_offer),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('收藏此模板'),
              subtitle: const Text('收藏后可快速访问'),
              value: _isFavorite,
              onChanged: (value) {
                setState(() {
                  _isFavorite = value;
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
          child: FilledButton(
            onPressed: _saveTemplate,
            child: const Text('保存'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final promptsRepo = ref.read(promptsRepositoryProvider);

      if (widget.template == null) {
        // 创建新模板
        await promptsRepo.createTemplate(
          name: _nameController.text,
          content: _contentController.text,
          category: _categoryController.text.isEmpty
              ? '通用'
              : _categoryController.text,
          tags: tags,
        );
      } else {
        // 更新模板
        await promptsRepo.updateTemplate(
          widget.template!.id,
          name: _nameController.text,
          content: _contentController.text,
          category: _categoryController.text.isEmpty
              ? '通用'
              : _categoryController.text,
          tags: tags,
        );

        // 更新收藏状态
        if (_isFavorite != widget.template!.isFavorite) {
          await promptsRepo.toggleFavorite(widget.template!.id);
        }
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
