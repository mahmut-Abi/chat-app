import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/domain/message.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';

void main() {
  group('PdfExport', () {
    late Conversation testConversation;

    setUp(() {
      testConversation = Conversation(
        id: 'test-id',
        title: '测试对话',
        messages: [
          Message(
            id: 'msg1',
            content: '你好',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
          Message(
            id: 'msg2',
            content: '你好！有什么我可以帮助你的吗？',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('应该正确创建包含消息的 Conversation', () {
      expect(testConversation.id, 'test-id');
      expect(testConversation.title, '测试对话');
      expect(testConversation.messages.length, 2);
    });

    test('应该正确识别用户和助手消息', () {
      final userMessage = testConversation.messages.first;
      final assistantMessage = testConversation.messages.last;

      expect(userMessage.role, MessageRole.user);
      expect(assistantMessage.role, MessageRole.assistant);
    });

    test('应该正确处理带有标签的对话', () {
      final conversationWithTags = testConversation.copyWith(
        tags: ['重要', '工作'],
      );

      expect(conversationWithTags.tags.length, 2);
      expect(conversationWithTags.tags, contains('重要'));
      expect(conversationWithTags.tags, contains('工作'));
    });

    test('应该正确处理系统提示词', () {
      final conversationWithSystemPrompt = testConversation.copyWith(
        systemPrompt: '你是一个有用的助手',
      );

      expect(conversationWithSystemPrompt.systemPrompt, '你是一个有用的助手');
    });
  });
}
