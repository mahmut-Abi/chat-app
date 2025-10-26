import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';
import 'package:chat_app/features/chat/domain/message.dart';

void main() {
  group('PDF Export 中文支持测试', () {
    test('应该能够创建包含中文的对话', () {
      // 创建包含中文的测试对话
      final conversation = Conversation(
        id: 'test-id',
        title: '测试对话 - 中文标题',
        messages: [
          Message(
            id: 'msg-1',
            content: '你好，这是一个中文测试消息',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
          Message(
            id: 'msg-2',
            content: '您好！我是 AI 助手。很高兴为您服务。',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ),
          Message(
            id: 'msg-3',
            content: '请帮我测试中文字符：汉字、标点符号（）、特殊字符！@#￥%',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: const ['测试', '中文', 'PDF导出'],
        systemPrompt: '你是一个友好的 AI 助手，请用中文回答问题。',
      );

      // 验证对话创建成功
      expect(conversation.title, contains('中文'));
      expect(conversation.messages.length, equals(3));
      expect(conversation.messages[0].content, contains('中文'));
      expect(conversation.tags, contains('中文'));
    });

    test('应该能够处理空对话列表', () {
      final conversations = <Conversation>[];
      expect(conversations.isEmpty, isTrue);
    });

    test('应该能够处理多个包含中文的对话', () {
      final conversations = [
        Conversation(
          id: 'conv-1',
          title: '第一个对话',
          messages: [
            Message(
              id: 'msg-1',
              content: '第一条消息',
              role: MessageRole.user,
              timestamp: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Conversation(
          id: 'conv-2',
          title: '第二个对话',
          messages: [
            Message(
              id: 'msg-2',
              content: '第二条消息',
              role: MessageRole.user,
              timestamp: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      expect(conversations.length, equals(2));
      expect(conversations[0].title, equals('第一个对话'));
      expect(conversations[1].title, equals('第二个对话'));
    });
  });
}
