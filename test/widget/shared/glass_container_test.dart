/// 玻璃容器 Widget 测试

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/shared/widgets/glass_container.dart';

void main() {
  group('GlassContainer Widget 测试', () {
    testWidgets('应该能够渲染 GlassContainer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GlassContainer(child: const Text('测试文本'))),
        ),
      );

      expect(find.text('测试文本'), findsOneWidget);
    });

    testWidgets('应该能够设置自定义 blur 值', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassContainer(blur: 30.0, child: const Text('模糊测试')),
          ),
        ),
      );

      expect(find.text('模糊测试'), findsOneWidget);
    });

    testWidgets('应该能够设置自定义 opacity 值', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassContainer(opacity: 0.5, child: const Text('透明度测试')),
          ),
        ),
      );

      expect(find.text('透明度测试'), findsOneWidget);
    });
  });

  group('GlassCard Widget 测试', () {
    testWidgets('应该能够渲染 GlassCard', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GlassCard(child: const Text('卡片测试'))),
        ),
      );

      expect(find.text('卡片测试'), findsOneWidget);
    });
  });
}
