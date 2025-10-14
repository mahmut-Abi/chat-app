import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// 分享工具类
class ShareUtils {
  /// 分享文本 (使用 Share.share 方法)
  static Future<void> shareText(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      debugPrint('分享失败: $e');
    }
  }

  /// 分享文件 (使用 Share.shareXFiles 方法)
  static Future<void> shareFile(String filePath, {String? text}) async {
    try {
      final file = XFile(filePath);
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: text ?? '',
        ),
      );
    } catch (e) {
      debugPrint('分享文件失败: $e');
    }
  }

  /// 分享多个文件 (使用 Share.shareXFiles 方法)
  static Future<void> shareFiles(List<String> filePaths, {String? text}) async {
    try {
      final files = filePaths.map((path) => XFile(path)).toList();
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: text ?? '',
        ),
      );
    } catch (e) {
      debugPrint('分享文件失败: $e');
    }
  }

  /// 检查是否支持分享
  static bool get isShareSupported {
    return !kIsWeb;
  }
}
