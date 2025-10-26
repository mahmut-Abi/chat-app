import 'package:flutter/material.dart';

/// 统一的对话框管理器
class DialogHelper {
  /// 显示确认对话框
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '确定',
    String cancelText = '取消',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 显示提示对话框
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = '确定',
    Widget? icon,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: icon,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// 显示加载对话框
  static Future<void> showLoadingDialog({
    required BuildContext context,
    String message = '加载中...',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// 显示选择对话框
  static Future<T?> showChoiceDialog<T>({
    required BuildContext context,
    required String title,
    required List<DialogChoice<T>> choices,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: choices
                .map((choice) => ListTile(
                      title: Text(choice.label),
                      onTap: () => Navigator.pop(context, choice.value),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// 选择项配置
class DialogChoice<T> {
  final String label;
  final T value;

  DialogChoice({required this.label, required this.value});
}
