import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/utils/keyboard_utils.dart';

void main() {
  group('KeyboardUtils - Bug #3 键盘弹出修复验证', () {
    testWidgets('验证 dismissKeyboard 能移除焦点', (WidgetTester tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(focusNode: focusNode, autofocus: true),
          ),
        ),
      );

      // 等待焦点获取
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      // 调用 dismissKeyboard
      final context = tester.element(find.byType(Scaffold));
      KeyboardUtils.dismissKeyboard(context);

      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isFalse);

      focusNode.dispose();
    });

    testWidgets('验证 requestFocus 能请求焦点', (WidgetTester tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(focusNode: focusNode)),
        ),
      );

      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isFalse);

      // 调用 requestFocus
      final context = tester.element(find.byType(Scaffold));
      KeyboardUtils.requestFocus(context, focusNode);

      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
    });
  });
}
