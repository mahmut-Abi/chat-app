import '../../../features/chat/domain/conversation.dart';
import '../../../features/chat/domain/message.dart';
import 'package:intl/intl.dart';

/// Markdown 导出工具类
///
/// 提供将对话导出为 Markdown 格式的功能。
class MarkdownExport {
  /// 导出单个对话为 Markdown
  ///
  /// 生成包含标题、元数据和消息内容的 Markdown 文本。
  ///
  /// [conversation] 要导出的对话
  /// 返回 Markdown 格式的字符串
  static String exportConversation(Conversation conversation) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // 添加标题
    buffer.writeln('# ${conversation.title}');
    buffer.writeln();

    // 添加元数据
    buffer.writeln('---');
    buffer.writeln('**创建时间**: ${dateFormat.format(conversation.createdAt)}');
    buffer.writeln('**更新时间**: ${dateFormat.format(conversation.updatedAt)}');
    if (conversation.tags.isNotEmpty) {
      buffer.writeln('**标签**: ${conversation.tags.join(', ')}');
    }
    if (conversation.totalTokens != null) {
      buffer.writeln('**总 Token 数**: ${conversation.totalTokens}');
    }
    buffer.writeln('---');
    buffer.writeln();

    // 添加系统提示词
    if (conversation.systemPrompt != null &&
        conversation.systemPrompt!.isNotEmpty) {
      buffer.writeln('## 系统提示词');
      buffer.writeln();
      buffer.writeln('> ${conversation.systemPrompt}');
      buffer.writeln();
    }

    // 添加消息
    buffer.writeln('## 对话内容');
    buffer.writeln();

    for (final message in conversation.messages) {
      if (message.role == MessageRole.system) continue;

      final roleLabel = message.role == MessageRole.user ? '用户' : 'AI';
      final timestamp = dateFormat.format(message.timestamp);

      buffer.writeln('### $roleLabel ($timestamp)');
      buffer.writeln();
      buffer.writeln(message.content);
      buffer.writeln();

      if (message.tokenCount != null) {
        buffer.writeln('*Token 数: ${message.tokenCount}*');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// 导出多个对话为单个 Markdown 文件
  ///
  /// 将多个对话合并为一个 Markdown 文件。
  ///
  /// [conversations] 要导出的对话列表
  /// 返回 Markdown 格式的字符串
  static String exportConversations(List<Conversation> conversations) {
    final buffer = StringBuffer();

    buffer.writeln('# 对话导出');
    buffer.writeln();
    buffer.writeln(
      '导出时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
    );
    buffer.writeln();
    buffer.writeln('总对话数: ${conversations.length}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (var i = 0; i < conversations.length; i++) {
      buffer.writeln(exportConversation(conversations[i]));
      if (i < conversations.length - 1) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
