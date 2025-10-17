import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/token_usage/domain/token_record.dart';

void main() {
  group('TokenRecord', () {
    test('应该正确创建 TokenRecord 实例', () {
      // Arrange
      final timestamp = DateTime(2025, 1, 17, 12, 0);

      // Act
      final record = TokenRecord(
        id: 'test_id',
        conversationId: 'conv_123',
        conversationTitle: '测试对话',
        messageId: 'msg_456',
        model: 'gpt-4',
        promptTokens: 100,
        completionTokens: 200,
        totalTokens: 300,
        timestamp: timestamp,
        messagePreview: '这是一个测试消息',
      );

      // Assert
      expect(record.id, 'test_id');
      expect(record.conversationId, 'conv_123');
      expect(record.conversationTitle, '测试对话');
      expect(record.messageId, 'msg_456');
      expect(record.model, 'gpt-4');
      expect(record.promptTokens, 100);
      expect(record.completionTokens, 200);
      expect(record.totalTokens, 300);
      expect(record.timestamp, timestamp);
      expect(record.messagePreview, '这是一个测试消息');
    });

    test('应该支持不带 messagePreview 创建实例', () {
      // Arrange & Act
      final record = TokenRecord(
        id: 'test_id',
        conversationId: 'conv_123',
        conversationTitle: '测试对话',
        messageId: 'msg_456',
        model: 'gpt-3.5-turbo',
        promptTokens: 50,
        completionTokens: 150,
        totalTokens: 200,
        timestamp: DateTime.now(),
      );

      // Assert
      expect(record.messagePreview, isNull);
    });

    test('应该正确序列化为 JSON', () {
      // Arrange
      final timestamp = DateTime(2025, 1, 17, 12, 0);
      final record = TokenRecord(
        id: 'test_id',
        conversationId: 'conv_123',
        conversationTitle: '测试对话',
        messageId: 'msg_456',
        model: 'gpt-4',
        promptTokens: 100,
        completionTokens: 200,
        totalTokens: 300,
        timestamp: timestamp,
        messagePreview: '测试消息',
      );

      // Act
      final json = record.toJson();

      // Assert
      expect(json['id'], 'test_id');
      expect(json['conversationId'], 'conv_123');
      expect(json['conversationTitle'], '测试对话');
      expect(json['messageId'], 'msg_456');
      expect(json['model'], 'gpt-4');
      expect(json['promptTokens'], 100);
      expect(json['completionTokens'], 200);
      expect(json['totalTokens'], 300);
      expect(json['timestamp'], timestamp.toIso8601String());
      expect(json['messagePreview'], '测试消息');
    });

    test('应该正确从 JSON 反序列化', () {
      // Arrange
      final timestamp = DateTime(2025, 1, 17, 12, 0);
      final json = {
        'id': 'test_id',
        'conversationId': 'conv_123',
        'conversationTitle': '测试对话',
        'messageId': 'msg_456',
        'model': 'gpt-4',
        'promptTokens': 100,
        'completionTokens': 200,
        'totalTokens': 300,
        'timestamp': timestamp.toIso8601String(),
        'messagePreview': '测试消息',
      };

      // Act
      final record = TokenRecord.fromJson(json);

      // Assert
      expect(record.id, 'test_id');
      expect(record.conversationId, 'conv_123');
      expect(record.conversationTitle, '测试对话');
      expect(record.messageId, 'msg_456');
      expect(record.model, 'gpt-4');
      expect(record.promptTokens, 100);
      expect(record.completionTokens, 200);
      expect(record.totalTokens, 300);
      expect(record.timestamp, timestamp);
      expect(record.messagePreview, '测试消息');
    });

    test('应该正确处理不带 messagePreview 的 JSON', () {
      // Arrange
      final timestamp = DateTime(2025, 1, 17, 12, 0);
      final json = {
        'id': 'test_id',
        'conversationId': 'conv_123',
        'conversationTitle': '测试对话',
        'messageId': 'msg_456',
        'model': 'gpt-3.5-turbo',
        'promptTokens': 50,
        'completionTokens': 150,
        'totalTokens': 200,
        'timestamp': timestamp.toIso8601String(),
      };

      // Act
      final record = TokenRecord.fromJson(json);

      // Assert
      expect(record.messagePreview, isNull);
      expect(record.totalTokens, 200);
    });

    test('应该正确进行序列化-反序列化往返', () {
      // Arrange
      final original = TokenRecord(
        id: 'test_id',
        conversationId: 'conv_123',
        conversationTitle: '测试对话',
        messageId: 'msg_456',
        model: 'gpt-4',
        promptTokens: 100,
        completionTokens: 200,
        totalTokens: 300,
        timestamp: DateTime(2025, 1, 17, 12, 0),
        messagePreview: '测试消息',
      );

      // Act
      final json = original.toJson();
      final restored = TokenRecord.fromJson(json);

      // Assert
      expect(restored.id, original.id);
      expect(restored.conversationId, original.conversationId);
      expect(restored.conversationTitle, original.conversationTitle);
      expect(restored.messageId, original.messageId);
      expect(restored.model, original.model);
      expect(restored.promptTokens, original.promptTokens);
      expect(restored.completionTokens, original.completionTokens);
      expect(restored.totalTokens, original.totalTokens);
      expect(restored.timestamp, original.timestamp);
      expect(restored.messagePreview, original.messagePreview);
    });

    test('应该正确计算 Token 总数', () {
      // Arrange & Act
      final record = TokenRecord(
        id: 'test_id',
        conversationId: 'conv_123',
        conversationTitle: '测试对话',
        messageId: 'msg_456',
        model: 'gpt-4',
        promptTokens: 150,
        completionTokens: 250,
        totalTokens: 400,
        timestamp: DateTime.now(),
      );

      // Assert
      expect(record.totalTokens, 400);
      expect(
        record.promptTokens + record.completionTokens,
        400,
      ); // 验证 total 应该等于 prompt + completion
    });

    test('应该支持不同的模型名称', () {
      // Arrange
      final models = [
        'gpt-3.5-turbo',
        'gpt-4',
        'gpt-4-turbo',
        'claude-3-opus',
        'claude-3-sonnet',
      ];

      // Act & Assert
      for (final model in models) {
        final record = TokenRecord(
          id: 'test_id',
          conversationId: 'conv_123',
          conversationTitle: '测试对话',
          messageId: 'msg_456',
          model: model,
          promptTokens: 100,
          completionTokens: 200,
          totalTokens: 300,
          timestamp: DateTime.now(),
        );

        expect(record.model, model);
      }
    });
  });
}
