import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// 原生菜单栏工具类
class NativeMenu {
  static const MethodChannel _channel = MethodChannel('native_menu');

  static bool get isSupported =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// 初始化原生菜单
  static Future<void> initialize() async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod('initialize');
    } catch (e) {
      debugPrint('初始化原生菜单失败: $e');
    }
  }

  /// 设置菜单项
  static Future<void> setMenu(List<MenuItem> items) async {
    if (!isSupported) return;

    try {
      final menuData = items.map((item) => item.toJson()).toList();
      await _channel.invokeMethod('setMenu', {'items': menuData});
    } catch (e) {
      debugPrint('设置菜单失败: $e');
    }
  }

  /// 注册菜单回调
  static void setMenuCallback(Function(String) callback) {
    if (!isSupported) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMenuItemSelected') {
        final id = call.arguments as String;
        callback(id);
      }
    });
  }
}

/// 菜单项
class MenuItem {
  final String id;
  final String label;
  final String? shortcut;
  final List<MenuItem>? submenu;
  final bool enabled;

  MenuItem({
    required this.id,
    required this.label,
    this.shortcut,
    this.submenu,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (shortcut != null) 'shortcut': shortcut,
    if (submenu != null)
      'submenu': submenu!.map((item) => item.toJson()).toList(),
    'enabled': enabled,
  };
}
