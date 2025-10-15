import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/data/message_pagination_manager.dart';
import 'package:chat_app/features/chat/domain/message.dart';

void main() {
  group('MessagePaginationManager', () {
    late MessagePaginationManager manager;
    late List<Message> testMessages;

    setUp(() {
      manager = MessagePaginationManager(pageSize: 10);
      testMessages = List.generate(
        25,
        (index) => Message(
          id: 'msg$index',
          content: '消息 $index',
          role: MessageRole.user,
          timestamp: DateTime(2024, 1, 1).add(Duration(minutes: index)),
        ),
      );
    });

    test('应该正确初始化第一页', () {
      final displayed = manager.initialize(testMessages);

      expect(displayed.length, 10);
      expect(displayed.first.id, 'msg0');
      expect(displayed.last.id, 'msg9');
    });

    test('应该正确加载更多消息', () {
      manager.initialize(testMessages);
      final displayed = manager.loadMore(testMessages);

      expect(displayed.length, 20);
      expect(displayed.first.id, 'msg10');
      expect(displayed[10].id, 'msg0');
    });

    test('应该正确检测是否还有更多消息', () {
      manager.initialize(testMessages);
      expect(manager.hasMore(testMessages), true);

      manager.loadMore(testMessages);
      expect(manager.hasMore(testMessages), true);

      manager.loadMore(testMessages);
      expect(manager.hasMore(testMessages), false);
    });

    test('应该正确添加新消息', () {
      manager.initialize(testMessages);
      final newMessage = Message(
        id: 'new-msg',
        content: '新消息',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      final displayed = manager.addMessage(newMessage);

      expect(displayed.length, 11);
      expect(displayed.last.id, 'new-msg');
    });

    test('应该正确重置分页状态', () {
      manager.initialize(testMessages);
      manager.loadMore(testMessages);

      expect(manager.displayedMessages.length, 20);

      manager.reset();
      expect(manager.displayedMessages.length, 0);
    });

    test('应该正确处理小于一页的消息列表', () {
      final smallList = testMessages.sublist(0, 5);
      final displayed = manager.initialize(smallList);

      expect(displayed.length, 5);
      expect(manager.hasMore(smallList), false);
    });
  });
}
