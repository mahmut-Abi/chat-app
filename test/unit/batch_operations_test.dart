import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';
import 'package:chat_app/features/chat/domain/message.dart';

void main() {
  group('BatchOperations', () {
    late List<Conversation> testConversations;

    setUp(() {
      testConversations = [
        Conversation(
          id: 'conv1',
          title: '对话1',
          messages: [
            Message(
              id: 'msg1',
              content: '消息1',
              role: MessageRole.user,
              timestamp: DateTime(2024, 1, 1),
            ),
          ],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          tags: ['重要'],
        ),
        Conversation(
          id: 'conv2',
          title: '对话2',
          messages: [],
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
          tags: ['工作'],
        ),
      ];
    });

    test('应该正确过滤空对话', () {
      final empty = testConversations.where((c) => c.messages.isEmpty).toList();

      expect(empty.length, 1);
      expect(empty.first.id, 'conv2');
    });

    test('应该正确过滤包含标签的对话', () {
      final tagged = testConversations
          .where((c) => c.tags.contains('重要'))
          .toList();

      expect(tagged.length, 1);
      expect(tagged.first.id, 'conv1');
    });

    test('应该正确按日期排序', () {
      final sorted = List<Conversation>.from(testConversations)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(sorted.first.id, 'conv2');
      expect(sorted.last.id, 'conv1');
    });

    test('应该正确计算包含 token 信息的消息', () {
      final convWithTokens = testConversations[0].copyWith(
        messages: [
          Message(
            id: 'msg1',
            content: '测试',
            role: MessageRole.user,
            timestamp: DateTime.now(),
            tokenCount: 10,
          ),
          Message(
            id: 'msg2',
            content: '回复',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            tokenCount: 20,
          ),
        ],
      );

      final totalTokens = convWithTokens.messages.fold<int>(
        0,
        (sum, msg) => sum + (msg.tokenCount ?? 0),
      );

      expect(totalTokens, 30);
    });
  });
}
