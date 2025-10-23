import 'package:flutter/material.dart';

/// 统一的消息提示工具类
class MessageUtils {
  /// 显示成功消息
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(context, message, _MessageType.success, duration);
  }

  /// 显示错误消息
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(context, message, _MessageType.error, duration);
  }

  /// 显示信息消息
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(context, message, _MessageType.info, duration);
  }

  /// 显示警告消息
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(context, message, _MessageType.warning, duration);
  }

  /// 显示复制成功提示
  static void showCopied(BuildContext context) {
    _showSnackBar(
      context,
      '已复制到剪贴板',
      _MessageType.info,
      const Duration(seconds: 1),
    );
  }

  /// 内部方法：显示 SnackBar
  static void _showSnackBar(
    BuildContext context,
    String message,
    _MessageType type,
    Duration duration,
  ) {
    final colors = _getColors(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(colors.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: colors.background,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// 获取颜色配置
  static _MessageColors _getColors(_MessageType type) {
    switch (type) {
      case _MessageType.success:
        return _MessageColors(
          background: Colors.green.shade600,
          icon: Icons.check_circle,
        );
      case _MessageType.error:
        return _MessageColors(
          background: Colors.red.shade600,
          icon: Icons.error_outline,
        );
      case _MessageType.info:
        return _MessageColors(
          background: Colors.blue.shade600,
          icon: Icons.info_outline,
        );
      case _MessageType.warning:
        return _MessageColors(
          background: Colors.orange.shade600,
          icon: Icons.warning_amber,
        );
    }
  }
}

enum _MessageType { success, error, info, warning }

class _MessageColors {
  final Color background;
  final IconData icon;

  _MessageColors({required this.background, required this.icon});
}
