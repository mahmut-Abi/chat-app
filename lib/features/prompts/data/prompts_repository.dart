import '../domain/prompt_template.dart';
import '../../../core/storage/storage_service.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/log_service.dart';

class PromptsRepository {
  final StorageService _storage;
  final _uuid = const Uuid();
  final _log = LogService();

  PromptsRepository(this._storage);

  Future<PromptTemplate> createTemplate({
    required String name,
    required String content,
    String category = '通用',
    List<String> tags = const [],
  }) async {
    _log.debug('开始创建提示词模板', {
      'name': name,
      'category': category,
      'tagsCount': tags.length,
      'contentLength': content.length,
    });

    final template = PromptTemplate(
      id: _uuid.v4(),
      name: name,
      content: content,
      category: category,
      tags: tags,
      createdAt: DateTime.now(),
    );
    _log.info('提示词模板创建成功', {'templateId': template.id, 'name': name});

    await _storage.savePromptTemplate(template.id, template.toJson());
    _log.debug('提示词模板已保存', {'templateId': template.id});
    return template;
  }

  Future<void> saveTemplate(PromptTemplate template) async {
    _log.debug('保存提示词模板', {'templateId': template.id, 'name': template.name});
    await _storage.savePromptTemplate(template.id, template.toJson());
  }

  Future<PromptTemplate?> getTemplate(String id) async {
    _log.debug('获取提示词模板', {'templateId': id});
    final data = _storage.getPromptTemplate(id);
    if (data == null) {
      _log.debug('提示词模板不存在', {'templateId': id});
      return null;
    }
    _log.debug('提示词模板已找到', {'templateId': id});
    return PromptTemplate.fromJson(data);
  }

  Future<List<PromptTemplate>> getAllTemplates() async {
    _log.debug('获取所有提示词模板');
    final templates = _storage.getAllPromptTemplates();
    _log.info('获取到提示词模板列表', {'count': templates.length});
    return templates.map((data) => PromptTemplate.fromJson(data)).toList();
  }

  Future<List<PromptTemplate>> getTemplatesByCategory(String category) async {
    _log.debug('按分类获取提示词模板', {'category': category});
    final templates = await getAllTemplates();
    final filtered = templates.where((t) => t.category == category).toList();
    _log.debug('找到匹配的模板', {'category': category, 'count': filtered.length});
    return filtered;
  }

  Future<List<PromptTemplate>> getFavoriteTemplates() async {
    _log.debug('获取收藏的提示词模板');
    final templates = await getAllTemplates();
    final favorites = templates.where((t) => t.isFavorite).toList();
    _log.info('找到收藏模板', {'count': favorites.length});
    return favorites;
  }

  Future<void> deleteTemplate(String id) async {
    _log.info('删除提示词模板', {'templateId': id});
    await _storage.deletePromptTemplate(id);
    _log.debug('提示词模板已删除', {'templateId': id});
  }

  Future<void> updateTemplate(
    String id, {
    required String name,
    required String content,
    String? category,
    List<String>? tags,
    bool? isFavorite,
  }) async {
    _log.info('更新提示词模板', {'templateId': id, 'name': name});
    final template = await getTemplate(id);
    if (template != null) {
      _log.debug('找到待更新的模板', {'templateId': id});
      final updated = template.copyWith(
        name: name,
        content: content,
        category: category,
        tags: tags,
        isFavorite: isFavorite,
        updatedAt: DateTime.now(),
      );
      await saveTemplate(updated);
      _log.info('提示词模板更新成功', {'templateId': id});
    } else {
      _log.warning('更新失败：模板不存在', {'templateId': id});
    }
  }

  Future<void> toggleFavorite(String id) async {
    _log.debug('切换模板收藏状态', {'templateId': id});
    final template = await getTemplate(id);
    if (template != null) {
      _log.info('模板收藏状态切换', {
        'templateId': id,
        'newState': !template.isFavorite,
      });
      final updated = template.copyWith(isFavorite: !template.isFavorite);
      await saveTemplate(updated);
    } else {
      _log.warning('模板不存在', {'templateId': id});
    }
  }
}
