import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/providers/providers.dart';
import '../domain/prompt_template.dart';
import 'prompt_config_screen.dart';
import '../../../core/utils/message_utils.dart';

class PromptsScreen extends ConsumerStatefulWidget {
  const PromptsScreen({super.key});

  @override
  ConsumerState<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends ConsumerState<PromptsScreen> {
  String _selectedCategory = '全部';
  bool _showOnlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(promptTemplatesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('提示词模板'),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
            ),
            tooltip: '仅显示收藏',
            onPressed: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
            },
          ),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) {
          var filteredTemplates = templates;

          if (_showOnlyFavorites) {
            filteredTemplates = filteredTemplates
                .where((t) => t.isFavorite)
                .toList();
          }

          if (_selectedCategory != '全部') {
            filteredTemplates = filteredTemplates
                .where((t) => t.category == _selectedCategory)
                .toList();
          }

          final categories =
              ['全部'] + templates.map((t) => t.category).toSet().toList();

          return Column(
            children: [
              _buildCategoryFilter(categories),
              Expanded(
                child: filteredTemplates.isEmpty
                    ? _buildEmptyState()
                    : _buildTemplatesList(filteredTemplates),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('暂无提示词模板', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('点击右下角按钮创建新模板', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(List<PromptTemplate> templates) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          color: Theme.of(context).cardColor.withValues(alpha: 0.7),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showTemplateDialog(template),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          template.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: template.isFavorite ? Colors.red : null,
                        ),
                        onPressed: () => _toggleFavorite(template.id),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('编辑')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('删除'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _navigateToEdit(template);
                          } else if (value == 'delete') {
                            _deleteTemplate(template.id);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(template.category),
                        visualDensity: VisualDensity.compact,
                      ),
                      ...template.tags.map(
                        (tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTemplateDialog(PromptTemplate template) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '分类: ${template.category}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              SelectableText(
                template.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _useTemplate(template);
            },
            child: const Text('使用'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PromptConfigScreen()));

    if (result == true) {
      ref.invalidate(promptTemplatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('模板已创建')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _navigateToEdit(PromptTemplate template) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PromptConfigScreen(template: template),
      ),
    );

    if (result == true) {
      ref.invalidate(promptTemplatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('模板已更新')));
      }
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final promptsRepo = ref.read(promptsRepositoryProvider);
    await promptsRepo.toggleFavorite(id);
    ref.invalidate(promptTemplatesProvider);
  }

  Future<void> _deleteTemplate(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个模板吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final promptsRepo = ref.read(promptsRepositoryProvider);
      await promptsRepo.deleteTemplate(id);
      ref.invalidate(promptTemplatesProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('模板已删除')));
      }
    }
  }

  void _useTemplate(PromptTemplate template) {
    // 这里可以实现将模板应用到聊天输入框的逻辑
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('使用模板: ${template.name}')));
  }
}
