import 'dart:io';
import 'package:flutter/foundation.dart';
import 'image_utils.dart';

/// 图片上传验证工具
///
/// 用于诊断和验证图片上传过程中的问题
class ImageUploadValidator {
  /// 验证图片是否适合上传
  static Future<ValidationResult> validateImage(File imageFile) async {
    final results = <String>[];
    final warnings = <String>[];
    bool isValid = true;

    try {
      // 1. 检查文件是否存在
      if (!await imageFile.exists()) {
        results.add('文件不存在');
        return ValidationResult(
          isValid: false,
          messages: results,
          warnings: warnings,
        );
      }
      results.add('文件存在: OK');

      // 2. 检查文件类型
      final isImage = ImageUtils.isImageFile(imageFile.path);
      if (!isImage) {
        results.add('不是支持的图片格式');
        isValid = false;
      } else {
        results.add('图片格式有效: OK');
      }

      // 3. 检查文件大小
      final sizeKB = await ImageUtils.getImageSize(imageFile);
      results.add('文件大小: ${sizeKB.toStringAsFixed(2)} KB');

      if (sizeKB > 10 * 1024) {
        warnings.add(
          '文件较大 (${(sizeKB / 1024).toStringAsFixed(2)} MB), 可能导致请求超时',
        );
      } else if (sizeKB > 5 * 1024) {
        warnings.add('文件偏大 (${(sizeKB / 1024).toStringAsFixed(2)} MB), 建议压缩');
      }

      // 4. 检查 MIME 类型
      final mimeType = ImageUtils.getImageMimeType(imageFile.path);
      results.add('MIME 类型: $mimeType');

      // 5. 尝试 base64 编码
      try {
        final base64Data = await ImageUtils.imageToBase64(imageFile);
        results.add('Base64 编码成功: OK');
        results.add('Base64 长度: ${base64Data.length} 字符');

        // 检查 base64 数据大小
        final base64SizeMB = (base64Data.length / 1024 / 1024);
        if (base64SizeMB > 20) {
          warnings.add(
            'Base64 数据过大 (${base64SizeMB.toStringAsFixed(2)} MB), API 可能拒绝请求',
          );
          isValid = false;
        }

        // 验证 base64 格式
        final dataUrl = 'data:$mimeType;base64,$base64Data';
        results.add('Data URL 构建成功: OK');
        results.add('Data URL 长度: ${dataUrl.length} 字符');
      } catch (e) {
        results.add('Base64 编码失败: $e');
        isValid = false;
      }

      return ValidationResult(
        isValid: isValid,
        messages: results,
        warnings: warnings,
      );
    } catch (e) {
      results.add('验证过程出错: $e');
      return ValidationResult(
        isValid: false,
        messages: results,
        warnings: warnings,
      );
    }
  }

  /// 验证消息内容结构
  static ValidationResult validateMessageContent(
    List<Map<String, dynamic>> content,
  ) {
    final results = <String>[];
    final warnings = <String>[];
    bool isValid = true;

    try {
      // 1. 检查内容是否为空
      if (content.isEmpty) {
        results.add('内容为空');
        return ValidationResult(
          isValid: false,
          messages: results,
          warnings: warnings,
        );
      }
      results.add('内容不为空: ${content.length} 个部分');

      // 2. 检查每个部分的结构
      for (var i = 0; i < content.length; i++) {
        final part = content[i];

        if (!part.containsKey('type')) {
          results.add('第 ${i + 1} 部分缺少 type 字段');
          isValid = false;
          continue;
        }

        final type = part['type'];
        results.add('第 ${i + 1} 部分: $type');

        if (type == 'text') {
          if (!part.containsKey('text')) {
            results.add('  缺少 text 字段');
            isValid = false;
          } else {
            final text = part['text'] as String;
            results.add('  text 字段存在 (${text.length} 字符)');
          }
        } else if (type == 'image_url') {
          if (!part.containsKey('image_url')) {
            results.add('  缺少 image_url 字段');
            isValid = false;
          } else {
            final imageUrl = part['image_url'];
            if (imageUrl is! Map) {
              results.add('  image_url 应该是 Map 类型');
              isValid = false;
            } else {
              if (!imageUrl.containsKey('url')) {
                results.add('  image_url 缺少 url 字段');
                isValid = false;
              } else {
                final url = imageUrl['url'] as String;
                if (url.startsWith('data:image/')) {
                  results.add('  Data URL 格式正确: OK');
                  results.add('  URL 长度: ${url.length} 字符');
                } else {
                  warnings.add('  URL 不是 data URL 格式');
                }
              }
            }
          }
        } else {
          warnings.add('  未知的 type: $type');
        }
      }

      // 3. 检查是否有文本内容
      final hasText = content.any((part) => part['type'] == 'text');
      if (!hasText) {
        warnings.add('没有文本内容,某些模型可能要求至少有一个文本部分');
      }

      // 4. 检查是否有图片
      final hasImage = content.any((part) => part['type'] == 'image_url');
      if (!hasImage) {
        warnings.add('没有图片内容');
      }

      return ValidationResult(
        isValid: isValid,
        messages: results,
        warnings: warnings,
      );
    } catch (e) {
      results.add('验证过程出错: $e');
      return ValidationResult(
        isValid: false,
        messages: results,
        warnings: warnings,
      );
    }
  }

  /// 打印验证报告
  static void printReport(ValidationResult result) {
    if (kDebugMode) {

      for (final message in result.messages) {

      }
      if (result.warnings.isNotEmpty) {

        for (final warning in result.warnings) {

        }
      }


    }
  }
}

/// 验证结果
class ValidationResult {
  final bool isValid;
  final List<String> messages;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.messages,
    required this.warnings,
  });

  /// 获取摘要信息
  String get summary {
    return '${messages.length} 条检查, ${warnings.length} 条警告, '
        '状态: ${isValid ? "有效" : "无效"}';
  }
}
