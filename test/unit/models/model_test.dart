/// AI 模型数据测试

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/models/domain/model.dart';

void main() {
  group('AiModel', () {
    test('应该能够创建 AiModel 实例', () {
      const model = AiModel(
        id: 'gpt-4',
        name: 'GPT-4',
        apiConfigId: 'config-1',
        apiConfigName: 'OpenAI',
        description: 'GPT-4 model',
        contextLength: 8192,
        supportsFunctions: true,
        supportsVision: false,
      );

      expect(model.id, 'gpt-4');
      expect(model.name, 'GPT-4');
      expect(model.apiConfigId, 'config-1');
      expect(model.apiConfigName, 'OpenAI');
      expect(model.description, 'GPT-4 model');
      expect(model.contextLength, 8192);
      expect(model.supportsFunctions, true);
      expect(model.supportsVision, false);
    });

    test('应该能够从 JSON 创建 AiModel', () {
      final json = {
        'id': 'gpt-3.5-turbo',
        'name': 'GPT-3.5 Turbo',
        'apiConfigId': 'config-2',
        'apiConfigName': 'OpenAI',
        'description': 'Fast and efficient',
        'contextLength': 4096,
        'supportsFunctions': false,
        'supportsVision': false,
      };

      final model = AiModel.fromJson(json);

      expect(model.id, 'gpt-3.5-turbo');
      expect(model.name, 'GPT-3.5 Turbo');
      expect(model.contextLength, 4096);
    });

    test('应该能够将 AiModel 转为 JSON', () {
      const model = AiModel(
        id: 'claude-3',
        name: 'Claude 3',
        apiConfigId: 'config-3',
        apiConfigName: 'Anthropic',
        contextLength: 100000,
      );

      final json = model.toJson();

      expect(json['id'], 'claude-3');
      expect(json['name'], 'Claude 3');
      expect(json['apiConfigId'], 'config-3');
      expect(json['contextLength'], 100000);
    });

    test('应该能够使用 copyWith 复制并修改属性', () {
      const original = AiModel(
        id: 'model-1',
        name: 'Model 1',
        apiConfigId: 'config-1',
        apiConfigName: 'Provider 1',
        contextLength: 4096,
      );

      final modified = original.copyWith(
        name: 'Modified Model',
        contextLength: 8192,
      );

      expect(modified.id, 'model-1');
      expect(modified.name, 'Modified Model');
      expect(modified.contextLength, 8192);
      expect(modified.apiConfigId, 'config-1');
    });

    test('应该正确实现 Equatable', () {
      const model1 = AiModel(
        id: 'model-1',
        name: 'Model 1',
        apiConfigId: 'config-1',
        apiConfigName: 'Provider 1',
      );

      const model2 = AiModel(
        id: 'model-1',
        name: 'Model 1',
        apiConfigId: 'config-1',
        apiConfigName: 'Provider 1',
      );

      const model3 = AiModel(
        id: 'model-2',
        name: 'Model 2',
        apiConfigId: 'config-2',
        apiConfigName: 'Provider 2',
      );

      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
    });
  });
}
