import 'package:flutter/material.dart';
import '../network/api_exception.dart';

/// 统一错误处理类
///
/// 提供一致的错误消息处理和展示功能。
class ErrorHandler {
  /// 获取用户友好的错误消息
  static String getErrorMessage(Object error) {
    if (error is NetworkException) {
      return '网络连接失败，请检查网络设置';
    } else if (error is TimeoutException) {
      return '请求超时，请稍后重试';
    } else if (error is UnauthorizedException) {
      return 'API Key 无效或已过期';
    } else if (error is RateLimitException) {
      return '请求频率过高，请稍后重试';
    } else if (error is ApiException) {
      return error.message;
    } else if (error is Exception) {
      return '发生错误: ${error.toString()}';
    } else {
      return '未知错误: ${error.toString()}';
    }
  }

  static void showErrorSnackBar(
    BuildContext context,
    Object error, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 显示错误对话框
  static Future<void> showErrorDialog(
    BuildContext context,
    Object error, {
    String? title,
  }) async {
    final message = getErrorMessage(error);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? '错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
