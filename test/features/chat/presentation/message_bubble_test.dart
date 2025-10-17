import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:chat_app/features/chat/domain/message.dart';

void main() {
  group('Bug #012-014: 头像位置和模型名称显示', () {
    testWidgets('应该显示用户消息气泡', (tester) async {
      final userMessage = Message(
        id: '1',
        content: '用户消息测试',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                message: userMessage,
                onDelete: () {},
                onRegenerate: () {},
                onEdit: (content) {},
              ),
            ),
          ),
        ),
      );

      // 验证用户消息显示
      expect(find.text('用户'), findsOneWidget);
    });

    testWidgets('应该显示 AI 消息气泡和模型名称', (tester) async {
      final assistantMessage = Message(
        id: '2',
        content: 'AI 回复测试',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                message: assistantMessage,
                modelName: 'GPT-4',
                onDelete: () {},
                onRegenerate: () {},
                onEdit: (content) {},
              ),
            ),
          ),
        ),
      );

      // 验证 AI 消息和模型名称显示
      expect(find.text('GPT-4'), findsOneWidget);
    });

    testWidgets('如果没有模型名称应该显示默认名称', (tester) async {
      final assistantMessage = Message(
        id: '3',
        content: 'AI 回复',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                message: assistantMessage,
                onDelete: () {},
                onRegenerate: () {},
                onEdit: (content) {},
              ),
            ),
          ),
        ),
      );

      // 验证默认名称显示
      expect(find.text('AI 助手'), findsOneWidget);
    });
  });
}
