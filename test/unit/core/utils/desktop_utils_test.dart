/// 桌面工具测试
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/utils/desktop_utils.dart';

void main() {
  group('DesktopUtils', () {
    test('应该能够检测当前平台是否为桌面端', () {
      expect(DesktopUtils.isDesktop, isA<bool>());
    });
  });
}
