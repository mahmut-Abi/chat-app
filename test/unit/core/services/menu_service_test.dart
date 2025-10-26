/// 菜单服务测试
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/services/menu_service.dart';

void main() {
  group('MenuService', () {
    late MenuService service;

    setUp(() {
      service = MenuService();
    });

    test('应该能够创建实例', () {
      expect(service, isNotNull);
    });

    test('应该能够设置回调函数', () {
      service.onNewConversation = () {};
      service.onOpenSettings = () {};
      service.onAbout = () {};
      service.onQuit = () {};

      expect(service.onNewConversation, isNotNull);
      expect(service.onOpenSettings, isNotNull);
      expect(service.onAbout, isNotNull);
      expect(service.onQuit, isNotNull);
    });

    test('应该能够更新菜单状态', () {
      expect(
        () => service.updateMenuState(
          canUndo: true,
          canRedo: false,
          hasSelection: true,
        ),
        returnsNormally,
      );
    });

    test('应该能够初始化', () async {
      await expectLater(service.init(), completes);
    });
  });
}
