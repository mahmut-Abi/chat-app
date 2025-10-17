 import 'platform_utils.dart';
 import 'package:flutter/material.dart';

/// 键盘管理工具类
class KeyboardUtils {
  /// 关闭键盘
  static void dismissKeyboard(BuildContext context) {
    // 移除当前焦点
    FocusScope.of(context).unfocus();

    // iOS 特定处理，确保键盘完全关闭
    if (PlatformUtils.isIOS) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  /// 请求焦点
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  /// 延迟关闭键盘（用于页面初始化）
  static void dismissKeyboardDelayed(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dismissKeyboard(context);
    });
  }
}
