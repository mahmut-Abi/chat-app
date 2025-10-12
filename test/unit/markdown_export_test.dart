import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/utils/markdown_export.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';
import 'package:chat_app/features/chat/domain/message.dart';

void main() {
  group('MarkdownExport', () {
    test('应该正确导出单个对话', () {
      final conversation = Conversation(
        id: '123',
        title: '测试对话',
        messages: [
          Message(
            id: 'm1',
            role: MessageRole.user,
            content: '你好',
            timestamp: DateTime(2024, 1, 1),
          ),
          Message(
            id: 'm2',
            role: MessageRole.assistant,
            content: '你好!',
            timestamp: DateTime(2024, 1, 1),
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final markdown = MarkdownExport.exportConversation(conversation);

      expect(markdown, contains('测试对话'));
      expect(markdown, contains('你好'));
      expect(markdown, contains('你好!'));
    });

    test('应该导出带标签的对话', () {
      final conversation = Conversation(
        id: '123',
        title: '测试对话',
        messages: [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        tags: ['标签1', '标签2'],
      );

      final markdown = MarkdownExport.exportConversation(conversation);

      expect(markdown, contains('标签1'));
      expect(markdown, contains('标签2'));
    });
  });
}
