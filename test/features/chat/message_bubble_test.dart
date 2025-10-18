import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:chat_app/features/chat/domain/message.dart';

void main() {
  group('MessageBubble Widget Tests', () {
    testWidgets('渲染用户消息', (WidgetTester tester) async {
      // Arrange
      final message = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: '测试消息',
        timestamp: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MessageBubble(
                  message: message,
                  modelName: 'GPT-4',
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('测试消息'), findsOneWidget);
      expect(find.text('用户'), findsOneWidget);
    });

    testWidgets('渲染 AI 助手消息', (WidgetTester tester) async {
      // Arrange
      final message = Message(
        id: 'msg-2',
        role: MessageRole.assistant,
        content: 'AI 响应',
        timestamp: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MessageBubble(
                  message: message,
                  modelName: 'GPT-4',
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('AI 响应'), findsOneWidget);
      expect(find.text('GPT-4'), findsOneWidget);
    });

    testWidgets('渲染错误消息', (WidgetTester tester) async {
      // Arrange
      final message = Message(
        id: 'msg-3',
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        hasError: true,
        errorMessage: '发送失败',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MessageBubble(
                  message: message,
                  modelName: 'GPT-4',
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('发送失败'), findsOneWidget);
    });
  });
}
