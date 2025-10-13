import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';
import 'package:chat_app/features/chat/domain/message.dart';

void main() {
  group('Conversation', () {
    test('应该正确创建会话', () {
      final now = DateTime.now();
      final conversation = Conversation(
        id: 'conv-1',
        title: 'Test Conversation',
        messages: [],
        createdAt: now,
        updatedAt: now,
      );

      expect(conversation.id, 'conv-1');
      expect(conversation.title, 'Test Conversation');
      expect(conversation.messages, isEmpty);
      expect(conversation.isPinned, false);
    });

    test('应该正确添加消息', () {
      final conversation = Conversation(
        id: 'conv-1',
        title: 'Test',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final message = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final updated = conversation.copyWith(
        messages: [...conversation.messages, message],
      );

      expect(updated.messages.length, 1);
      expect(updated.messages.first.content, 'Hello');
    });

    test('应该正确序列化和反序列化', () {
      final conversation = Conversation(
        id: 'conv-1',
        title: 'Test',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['work', 'important'],
      );

      final json = conversation.toJson();
      final restored = Conversation.fromJson(json);

      expect(restored.id, conversation.id);
      expect(restored.title, conversation.title);
      expect(restored.tags, conversation.tags);
    });
  });

  group('ConversationGroup', () {
    test('应该正确创建分组', () {
      final group = ConversationGroup(
        id: 'group-1',
        name: 'Work',
        createdAt: DateTime.now(),
        color: '#FF0000',
      );

      expect(group.id, 'group-1');
      expect(group.name, 'Work');
      expect(group.color, '#FF0000');
    });
  });

  group('ModelConfig', () {
    test('应该正确创建模型配置', () {
      final config = ModelConfig(
        model: 'gpt-4',
      );

      expect(config.model, 'gpt-4');
      expect(config.temperature, 0.7);
      expect(config.maxTokens, 2048);
    });

    test('应该正确更新配置', () {
      final config = ModelConfig(model: 'gpt-3.5-turbo');
      final updated = config.copyWith(
        temperature: 0.9,
        maxTokens: 4096,
      );

      expect(updated.temperature, 0.9);
      expect(updated.maxTokens, 4096);
      expect(updated.model, 'gpt-3.5-turbo');
    });
  });
}
