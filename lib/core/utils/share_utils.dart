import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

/// 分享工具类
class ShareUtils {
  /// 分享文本
 static Future<void> shareText(String text) async {
   try {
      await Share.share(text);
   } catch (e) {
      debugPrint('分享失败: $e');
    }
  }

  /// 分享文件
  static Future<void> shareFile(String filePath, {String? text}) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles([file], text: text ?? '');
    } catch (e) {
      debugPrint('分享文件失败: $e');
    }
  }

  /// 分享多个文件
  static Future<void> shareFiles(
    List<String> filePaths, {
    String? text,
  }) async {
    try {
      final files = filePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(files, text: text ?? '');
    } catch (e) {
      debugPrint('分享文件失败: $e');
    }
  }

  /// 检查是否支持分享
  static bool get isShareSupported {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
}
