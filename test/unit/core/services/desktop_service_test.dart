/// 桌面端服务测试

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/services/desktop_service.dart';

void main() {
  group('DesktopService', () {
    late DesktopService service;

    setUp(() {
      service = DesktopService();
    });

    tearDown(() {
      service.dispose();
    });

    test('应该能够创建实例', () {
      expect(service, isNotNull);
    });

    test('应该能够设置回调函数', () {
      var newConversationCalled = false;
      var showWindowCalled = false;
      var quitCalled = false;

      service.onNewConversation = () => newConversationCalled = true;
      service.onShowWindow = () => showWindowCalled = true;
      service.onQuit = () => quitCalled = true;

      expect(service.onNewConversation, isNotNull);
      expect(service.onShowWindow, isNotNull);
      expect(service.onQuit, isNotNull);
    });

    test('应该在 dispose 后清理资源', () {
      service.dispose();
      // 验证没有抛出异常
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
