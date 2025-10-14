import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/prompts/domain/prompt_template.dart';

void main() {
  group('PromptTemplate', () {
    test('应该正确创建提示词模板', () {
      final template = PromptTemplate(
        id: 'prompt-1',
        name: '代码审查',
        content: '请帮我审查以下代码...',
        category: '编程',
        tags: const ['代码', '审查'],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(template.id, 'prompt-1');
      expect(template.name, '代码审查');
      expect(template.content, '请帮我审查以下代码...');
      expect(template.category, '编程');
      expect(template.tags, ['代码', '审查']);
      expect(template.isFavorite, false);
    });

    test('应该正确更新模板', () {
      final template = PromptTemplate(
        id: 'prompt-1',
        name: '原始名称',
        content: '原始内容',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = template.copyWith(
        name: '新名称',
        content: '新内容',
        isFavorite: true,
      );

      expect(updated.name, '新名称');
      expect(updated.content, '新内容');
      expect(updated.isFavorite, true);
      expect(updated.id, template.id);
    });

    test('应该正确序列化和反序列化', () {
      final template = PromptTemplate(
        id: 'prompt-1',
        name: '测试模板',
        content: '测试内容',
        category: '测试',
        tags: const ['tag1', 'tag2'],
        createdAt: DateTime(2024, 1, 1),
        isFavorite: true,
      );

      final json = template.toJson();
      final restored = PromptTemplate.fromJson(json);

      expect(restored.id, template.id);
      expect(restored.name, template.name);
      expect(restored.content, template.content);
      expect(restored.category, template.category);
      expect(restored.tags, template.tags);
      expect(restored.isFavorite, template.isFavorite);
    });

    test('相同属性的模板应该相等', () {
      final template1 = PromptTemplate(
        id: 'prompt-1',
        name: '测试',
        content: '内容',
        createdAt: DateTime(2024, 1, 1),
      );

      final template2 = PromptTemplate(
        id: 'prompt-1',
        name: '测试',
        content: '内容',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(template1, equals(template2));
    });
  });
}
