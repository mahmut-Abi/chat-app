import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_app/features/settings/presentation/modern_settings_screen.dart';
import 'package:chat_app/core/providers/providers.dart';
import 'package:chat_app/features/settings/data/settings_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_screen_tab_sync_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  group('ModernSettingsScreen Tab 同步测试', () {
    late MockSettingsRepository mockSettingsRepo;

    setUp(() {
      mockSettingsRepo = MockSettingsRepository();
      // Mock getAllApiConfigs 返回空列表
      when(mockSettingsRepo.getAllApiConfigs()).thenAnswer((_) async => []);
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
        child: const MaterialApp(home: ModernSettingsScreen()),
      );
    }

    testWidgets('点击 Tab 时标题应该立即更新', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证初始状态 - 应该显示 'API 配置'
      expect(find.text('API 配置'), findsWidgets);

      // 点击 '外观' Tab
      await tester.tap(find.text('外观'));
      await tester.pump(); // 只 pump 一帧，不等待动画完成

      // 验证标题立即更新
      expect(find.text('外观设置'), findsOneWidget);

      // 点击 '高级' Tab
      await tester.tap(find.text('高级'));
      await tester.pump();

      // 验证标题立即更新
      expect(find.text('高级功能'), findsOneWidget);
    });

    testWidgets('滑动切换页面时标题应该跟随更新', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证初始标题
      expect(find.text('API 配置'), findsWidgets);

      // 模拟滑动到下一个页面
      final gesture = await tester.startGesture(const Offset(400, 300));
      await gesture.moveBy(const Offset(-400, 0));
      await tester.pump();

      // 滑动过程中或完成后，标题应该更新为 '外观设置'
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('外观设置'), findsOneWidget);
    });

    testWidgets('快速连续点击多个 Tab 应该正确处理', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 快速点击多个 Tab
      await tester.tap(find.text('外观'));
      await tester.pump();

      await tester.tap(find.text('高级'));
      await tester.pump();

      await tester.tap(find.text('数据'));
      await tester.pump();

      // 验证最终标题
      expect(find.text('数据管理'), findsOneWidget);
    });

    testWidgets('Tab 索引不变时不应该触发不必要的更新', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 点击当前 Tab（不应该触发更新）
      await tester.tap(find.text('API'));
      await tester.pump();

      // 验证标题仍然是 'API 配置'
      expect(find.text('API 配置'), findsWidgets);
    });
  });
}
