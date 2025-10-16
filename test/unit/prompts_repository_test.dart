import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/prompts/data/prompts_repository.dart';
import 'package:chat_app/features/prompts/domain/prompt_template.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([StorageService])
import 'prompts_repository_test.mocks.dart';

void main() {
  late PromptsRepository repository;
  late MockStorageService mockStorage;

  setUp(() {
    mockStorage = MockStorageService();
    repository = PromptsRepository(mockStorage);
  });

  group('PromptsRepository', () {
    test('应该成功创建模板', () async {
      when(
        mockStorage.savePromptTemplate(any, any),
      ).thenAnswer((_) async => {});

      final template = await repository.createTemplate(
        name: '测试模板',
        content: '这是一个测试模板',
        category: '通用',
        tags: const ['测试'],
      );

      expect(template.name, '测试模板');
      expect(template.content, '这是一个测试模板');
      expect(template.category, '通用');
      expect(template.tags, const ['测试']);
      expect(template.isFavorite, false);
      verify(mockStorage.savePromptTemplate(template.id, any)).called(1);
    });

    test('应该成功获取模板', () async {
      final testTemplate = PromptTemplate(
        id: 'test-id',
        name: '测试模板',
        content: '测试内容',
        category: '通用',
        tags: const [],
        createdAt: DateTime.now(),
      );

      when(
        mockStorage.getPromptTemplate('test-id'),
      ).thenReturn(testTemplate.toJson());

      final template = await repository.getTemplate('test-id');

      expect(template, isNotNull);
      expect(template!.id, 'test-id');
      expect(template.name, '测试模板');
    });

    test('应该成功删除模板', () async {
      when(
        mockStorage.deletePromptTemplate('test-id'),
      ).thenAnswer((_) async => {});

      await repository.deleteTemplate('test-id');

      verify(mockStorage.deletePromptTemplate('test-id')).called(1);
    });
  });
}
