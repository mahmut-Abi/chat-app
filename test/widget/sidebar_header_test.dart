import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/presentation/widgets/sidebar_header.dart';

void main() {
  group('SidebarHeader Widget 测试', () {
    testWidgets('应该正确显示所有元素', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SidebarHeader(
              onCreateConversation: () {},
              onManageGroups: () {},
              onSearch: () {},
            ),
          ),
        ),
      );

      // 验证标题文本
      expect(find.text('Chat App'), findsOneWidget);

      // 验证新建对话按钮
      expect(find.text('新建对话'), findsOneWidget);

      // 验证图标按钮
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('应该正确触发回调', (WidgetTester tester) async {
      bool createPressed = false;
      bool managePressed = false;
      bool searchPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SidebarHeader(
              onCreateConversation: () => createPressed = true,
              onManageGroups: () => managePressed = true,
              onSearch: () => searchPressed = true,
            ),
          ),
        ),
      );

      // 测试新建对话按钮
      await tester.tap(find.text('新建对话'));
      await tester.pump();
      expect(createPressed, true);

      // 测试搜索按钮
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      expect(searchPressed, true);

      // 测试管理分组按钮
      await tester.tap(find.byIcon(Icons.folder_outlined));
      await tester.pump();
      expect(managePressed, true);
    });

    testWidgets('当 onSearch 为 null 时不显示搜索按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SidebarHeader(
              onCreateConversation: () {},
              onManageGroups: () {},
              onSearch: null,
            ),
          ),
        ),
      );

      // 搜索按钮不应该显示
      expect(find.byIcon(Icons.search), findsNothing);

      // 其他元素仍然显示
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.text('新建对话'), findsOneWidget);
    });
  });
}
