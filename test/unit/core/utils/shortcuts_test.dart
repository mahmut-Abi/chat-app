/// 快捷键测试

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/utils/shortcuts.dart';

void main() {
  group('AppShortcuts', () {
    test('应该能够创建快捷键配置', () {
      final shortcuts = AppShortcuts.shortcuts;
      expect(shortcuts, isNotNull);
      expect(shortcuts, isA<Map<ShortcutActivator, Intent>>());
      expect(shortcuts.isNotEmpty, isTrue);
    });

    test('应该包含新建对话快捷键', () {
      final shortcuts = AppShortcuts.shortcuts;
      expect(
        shortcuts.values.any((intent) => intent is NewConversationIntent),
        isTrue,
      );
    });

    test('应该能够创建 Action 配置', () {
      final actions = AppShortcuts.actions;
      expect(actions, isNotNull);
      expect(actions, isA<Map<Type, Action<Intent>>>());
      expect(actions.isNotEmpty, isTrue);
    });

    test('应该包含发送消息快捷键', () {
      final shortcuts = AppShortcuts.shortcuts;
      expect(
        shortcuts.values.any((intent) => intent is SendMessageIntent),
        isTrue,
      );
    });
  });
}
