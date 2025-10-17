import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';
import 'package:chat_app/features/chat/domain/message.dart';

/// Bug #10: 搜索对话功能测试
void main() {
  late List<Conversation> testConversations;

  setUp(() {
    testConversations = [
      Conversation(
        id: 'conv-1',
        title: 'Flutter 开发问题',
        messages: [
          Message(
            id: 'msg-1',
            role: MessageRole.user,
            content: 'Flutter 如何处理异步？',
            timestamp: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Conversation(
        id: 'conv-2',
        title: 'Python 数据分析',
        messages: [
          Message(
            id: 'msg-2',
            role: MessageRole.user,
            content: 'Python pandas 如何读取 CSV？',
            timestamp: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Conversation(
        id: 'conv-3',
        title: 'JavaScript 前端开发',
        messages: [
          Message(
            id: 'msg-3',
            role: MessageRole.user,
            content: 'React 和 Vue 的区别？',
            timestamp: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  });

  group('Conversation Search Logic', () {
    test('should find conversations by title - exact match', () {
      final query = 'Flutter';
      final results = testConversations
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(results.length, 1);
      expect(results[0].id, 'conv-1');
      expect(results[0].title, contains('Flutter'));
    });

    test('should find conversations by title - partial match', () {
      final query = 'python';
      final results = testConversations
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(results.length, 1);
      expect(results[0].id, 'conv-2');
    });

    test('should find conversations by message content', () {
      final query = 'React';
      final results = testConversations.where((c) {
        final titleMatch = c.title.toLowerCase().contains(query.toLowerCase());
        final messageMatch = c.messages.any(
          (m) => m.content.toLowerCase().contains(query.toLowerCase()),
        );
        return titleMatch || messageMatch;
      }).toList();

      expect(results.length, 1);
      expect(results[0].id, 'conv-3');
    });

    test('should be case-insensitive', () {
      final query = 'PYTHON';
      final results = testConversations
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(results.length, 1);
      expect(results[0].id, 'conv-2');
    });

    test('should return empty list when no match found', () {
      final query = 'Rust';
      final results = testConversations
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(results, isEmpty);
    });

    test('should return all conversations when query is empty', () {
      final query = '';
      final results = testConversations
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(results.length, 3);
    });

    test('should trim whitespace from query', () {
      final query = '  Flutter  ';
      final trimmedQuery = query.trim();
      final results = testConversations
          .where(
            (c) => c.title.toLowerCase().contains(trimmedQuery.toLowerCase()),
          )
          .toList();

      expect(results.length, 1);
      expect(results[0].id, 'conv-1');
    });
  });

  group('Edge Cases', () {
    test('should handle empty conversation list', () {
      final emptyList = <Conversation>[];
      final query = 'Flutter';
      final results = emptyList
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(results, isEmpty);
    });

    test('should handle conversation with empty title', () {
      final conversationsWithEmptyTitle = [
        Conversation(
          id: 'empty',
          title: '',
          messages: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final query = 'test';
      final results = conversationsWithEmptyTitle
          .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(results, isEmpty);
    });

    test('should handle conversation with no messages', () {
      final query = 'test';
      final convWithNoMessages = Conversation(
        id: 'no-msg',
        title: 'Test Conversation',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final messageMatch = convWithNoMessages.messages.any(
        (m) => m.content.toLowerCase().contains(query.toLowerCase()),
      );

      expect(messageMatch, false);
    });
  });
}
