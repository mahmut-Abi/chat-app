import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/features/models/data/models_repository.dart';
import 'package:chat_app/core/network/openai_api_client.dart';

import 'models_repository_test.mocks.dart';

@GenerateMocks([OpenAIApiClient])
void main() {
  group('ModelsRepository', () {
    late ModelsRepository repository;
    late MockOpenAIApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockOpenAIApiClient();
      repository = ModelsRepository(mockApiClient);
    });

    test('应该成功获取可用模型', () async {
      when(
        mockApiClient.getAvailableModels(),
      ).thenAnswer((_) async => ['gpt-4', 'gpt-3.5-turbo']);

      final models = await repository.getAvailableModels();

      expect(models.length, 2);
      expect(models[0].id, 'gpt-4');
      expect(models[1].id, 'gpt-3.5-turbo');
    });

    test('应该在 API 失败时返回默认模型', () async {
      when(mockApiClient.getAvailableModels()).thenThrow(Exception('API 错误'));

      final models = await repository.getAvailableModels();

      expect(models.isNotEmpty, true);
      expect(models.any((m) => m.id == 'gpt-4'), true);
      expect(models.any((m) => m.id == 'gpt-3.5-turbo'), true);
    });

    test('应该正确识别 GPT-4 Turbo 的上下文长度', () async {
      when(
        mockApiClient.getAvailableModels(),
      ).thenAnswer((_) async => ['gpt-4-turbo']);

      final models = await repository.getAvailableModels();
      final turboModel = models.firstWhere((m) => m.id == 'gpt-4-turbo');

      expect(turboModel.contextLength, 128000);
    });

    test('应该正确识别支持视觉的模型', () async {
      when(
        mockApiClient.getAvailableModels(),
      ).thenAnswer((_) async => ['gpt-4o', 'gpt-4-turbo']);

      final models = await repository.getAvailableModels();

      expect(models.every((m) => m.supportsVision), true);
    });

    test('应该正确识别支持函数调用的模型', () async {
      when(
        mockApiClient.getAvailableModels(),
      ).thenAnswer((_) async => ['gpt-4', 'gpt-3.5-turbo']);

      final models = await repository.getAvailableModels();

      expect(models.every((m) => m.supportsFunctions), true);
    });
  });
}
