// 简单的 token 计数器
// 注意: 这是一个近似计数,实际 token 数量可能会有所不同
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
}
