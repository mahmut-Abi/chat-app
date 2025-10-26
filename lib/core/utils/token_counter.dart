// 简单的 token 计数器
// 注意: 这是一个近似计数,实际 token 数量可能会有所不同
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Token 计数器
///
/// 提供 Token 数量的估算功能。
/// 注意：这是近似值，实际 Token 数量可能有差异。
class TokenCounter {
  /// 估算文本的 Token 数量
  ///
  /// 使用启发式规则：
  /// - 中文字符：每个约 1.5 个 Token
  /// - 英文单词：平均每个单词约 1.3 个 Token
  ///
  /// [text] 需要计数的文本
  /// 返回估算的 Token 数量
  static int estimate(String text) {
    if (text.isEmpty) return 0;

    int count = 0;

    // 分离中文字符和英文单词
    final chineseCharacters = RegExp(r'[\u4e00-\u9fa5]');
    final words = text.split(RegExp(r'\s+'));

    for (final word in words) {
      final chineseMatches = chineseCharacters.allMatches(word);
      final chineseCount = chineseMatches.length;

      if (chineseCount > 0) {
        // 中文字符
        count += (chineseCount * 1.5).ceil();
        // 非中文部分
        final nonChinese = word.replaceAll(chineseCharacters, '');
        if (nonChinese.isNotEmpty) {
          count += (nonChinese.length / 4 * 1.3).ceil();
        }
      } else if (word.isNotEmpty) {
        // 纯英文单词
        count += (word.length / 4 * 1.3).ceil();
      }
    }

    return count;
  }

  /// 估算消息列表的总 Token 数
  ///
  /// 包含消息内容、角色和固定开销。
  ///
  /// [messages] 消息列表，每个消息包含 'content' 和 'role' 字段
  /// 返回估算的总 Token 数量
  static int estimateMessages(List<Map<String, String>> messages) {
    int total = 0;
    for (final message in messages) {
      final content = message['content'] ?? '';
      final role = message['role'] ?? '';
      total += estimate(content);
      total += 4; // 每条消息的固定开销
      total += estimate(role);
    }
    total += 3; // 回复的固定开销
    return total;
  }

  /// 估算图片的 Token 数量
  ///
  /// 根据 OpenAI 的规则:
  /// - detail=low: 固定 85 tokens
  /// - detail=high: 85 + (tiles * 170) tokens
  ///   其中 tiles = ceil(width/512) * ceil(height/512)
  ///
  /// [imagePath] 图片文件路径
  /// [detail] 详细程度，默认 'auto'
  /// 返回估算的 Token 数量
  static int estimateImage(String imagePath, {String detail = 'auto'}) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        if (kDebugMode) {

        }
        return 85; // 默认使用 low detail
      }

      // 如果是 low detail，直接返回 85
      if (detail == 'low') {
        if (kDebugMode) {

        }
        return 85;
      }

      // 对于 auto 和 high，需要计算图片尺寸
      // 注意: 这里我们使用一个简化的估算
      // 实际应该读取图片的真实尺寸
      final fileSize = file.lengthSync();

      // 根据文件大小估算：
      // < 100KB: 假设是小图，1 tile
      // < 500KB: 中等，2-4 tiles
      // >= 500KB: 大图，4-6 tiles
      int tiles;
      if (fileSize < 100 * 1024) {
        tiles = 1;
      } else if (fileSize < 500 * 1024) {
        tiles = 3;
      } else {
        tiles = 5;
      }

      final totalTokens = 85 + (tiles * 170);
      if (kDebugMode) {




      }
      return totalTokens;
    } catch (e) {
      // 如果出错，返回默认值
      if (kDebugMode) {

      }
      return 85;
    }
  }

  /// 估算多个图片的总 Token 数量
  ///
  /// [imagePaths] 图片文件路径列表
  /// [detail] 详细程度，默认 'auto'
  /// 返回总 Token 数量
  static int estimateImages(List<String> imagePaths, {String detail = 'auto'}) {
    if (kDebugMode) {

    }
    int total = 0;
    for (final path in imagePaths) {
      total += estimateImage(path, detail: detail);
    }
    if (kDebugMode) {

    }
    return total;
  }
}
