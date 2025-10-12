import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// 图片工具类
class ImageUtils {
  /// 选择图片文件
  static Future<List<File>?> pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        compressionQuality: 80,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('选择图片失败: $e');
      return null;
    }
  }

  /// 将图片转换为 base64
  static Future<String> imageToBase64(File image) async {
    try {
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('转换图片失败: $e');
      rethrow;
    }
  }

  /// 获取图片的 MIME 类型
  static String getImageMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// 验证文件是否是图片
  static bool isImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// 获取图片大小（KB）
  static Future<double> getImageSize(File image) async {
    try {
      final bytes = await image.length();
      return bytes / 1024;
    } catch (e) {
      debugPrint('获取图片大小失败: $e');
      return 0;
    }
  }
}
