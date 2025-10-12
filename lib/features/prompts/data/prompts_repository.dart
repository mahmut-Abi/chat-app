import '../domain/prompt_template.dart';
import '../../../core/storage/storage_service.dart';
import 'package:uuid/uuid.dart';

class PromptsRepository {
  final StorageService _storage;
  final _uuid = const Uuid();

  PromptsRepository(this._storage);

  Future<PromptTemplate> createTemplate({
    required String name,
    required String content,
    String category = '通用',
    List<String> tags = const [],
  }) async {
    final template = PromptTemplate(
      id: _uuid.v4(),
      name: name,
      content: content,
      category: category,
      tags: tags,
      createdAt: DateTime.now(),
    );

    await _storage.savePromptTemplate(template.id, template.toJson());
    return template;
  }

  Future<void> saveTemplate(PromptTemplate template) async {
    await _storage.savePromptTemplate(template.id, template.toJson());
  }

  Future<PromptTemplate?> getTemplate(String id) async {
    final data = await _storage.getPromptTemplate(id);
    if (data == null) return null;
    return PromptTemplate.fromJson(data);
  }

  Future<List<PromptTemplate>> getAllTemplates() async {
    final templates = await _storage.getAllPromptTemplates();
    return templates.map((data) => PromptTemplate.fromJson(data)).toList();
  }

  Future<List<PromptTemplate>> getTemplatesByCategory(String category) async {
    final templates = await getAllTemplates();
    return templates.where((t) => t.category == category).toList();
  }

  Future<List<PromptTemplate>> getFavoriteTemplates() async {
    final templates = await getAllTemplates();
    return templates.where((t) => t.isFavorite).toList();
  }

  Future<void> deleteTemplate(String id) async {
    await _storage.deletePromptTemplate(id);
  }

  Future<void> updateTemplate(
    String id, {
    required String name,
    required String content,
    String? category,
    List<String>? tags,
    bool? isFavorite,
  }) async {
    final template = await getTemplate(id);
    if (template != null) {
      final updated = template.copyWith(
        name: name,
        content: content,
        category: category,
        tags: tags,
        isFavorite: isFavorite,
        updatedAt: DateTime.now(),
      );
      await saveTemplate(updated);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final template = await getTemplate(id);
    if (template != null) {
      final updated = template.copyWith(isFavorite: !template.isFavorite);
      await saveTemplate(updated);
    }
  }
}
