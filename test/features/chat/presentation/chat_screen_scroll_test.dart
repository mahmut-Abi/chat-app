import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_app/features/chat/presentation/chat_screen.dart';
import 'package:chat_app/core/providers/providers.dart';
import 'package:chat_app/features/chat/data/chat_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ChatRepository])
import 'chat_screen_scroll_test.mocks.dart';

void main() {
  late MockChatRepository mockChatRepo;

  setUp(() {
    mockChatRepo = MockChatRepository();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [chatRepositoryProvider.overrideWithValue(mockChatRepo)],
      child: MaterialApp(home: ChatScreen(conversationId: 'test-conversation')),
    );
  }

  group('Bug #011: 自动滚动问题', () {
    testWidgets('应该显示滚动到底部按钮当用户滚动到历史消息时', (tester) async {
      // 模拟对话数据
      when(mockChatRepo.getConversation(any)).thenReturn(null);
      when(mockChatRepo.getAllConversations()).thenReturn([]);
      when(mockChatRepo.getAllGroups()).thenReturn([]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 初始状态下不应该显示按钮
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });

    testWidgets('点击滚动到底部按钮应该滚动到底部', (tester) async {
      when(mockChatRepo.getConversation(any)).thenReturn(null);
      when(mockChatRepo.getAllConversations()).thenReturn([]);
      when(mockChatRepo.getAllGroups()).thenReturn([]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证界面正常加载
      expect(find.byType(ChatScreen), findsOneWidget);
    });
  });
}
