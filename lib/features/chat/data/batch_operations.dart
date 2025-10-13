import '../domain/conversation.dart';
import '../../../core/utils/pdf_export.dart';
import '../../../core/utils/markdown_export.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 批量操作工具类
class BatchOperations {
  /// 批量删除会话
  static Future<void> batchDelete(
    List<String> ids,
    Future<void> Function(String) deleteFunc,
  ) async {
    for (final id in ids) {
      await deleteFunc(id);
    }
  }

  /// 批量导出为 Markdown
  static Future<File?> batchExportMarkdown(
    List<Conversation> conversations,
  ) async {
    final content = MarkdownExport.exportConversations(conversations);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/conversations_export_${DateTime.now().millisecondsSinceEpoch}.md');
    await file.writeAsString(content);
    return file;
  }

  /// 批量导出为 PDF
  static Future<void> batchExportPdf(
    List<Conversation> conversations,
  ) async {
    await PdfExport.exportConversationsToPdf(conversations);
  }

  /// 批量添加标签
  static Future<void> batchAddTags(
    List<Conversation> conversations,
    List<String> tags,
    Future<void> Function(Conversation) saveFunc,
  ) async {
    for (final conversation in conversations) {
      final updatedTags = {...conversation.tags, ...tags}.toList();
      final updated = conversation.copyWith(tags: updatedTags);
      await saveFunc(updated);
    }
  }

  /// 批量移除标签
  static Future<void> batchRemoveTags(
    List<Conversation> conversations,
    List<String> tags,
    Future<void> Function(Conversation) saveFunc,
  ) async {
    for (final conversation in conversations) {
      final updatedTags = conversation.tags.where((t) => !tags.contains(t)).toList();
      final updated = conversation.copyWith(tags: updatedTags);
      await saveFunc(updated);
    }
  }

  /// 批量移动到分组
  static Future<void> batchMoveToGroup(
    List<Conversation> conversations,
    String? groupId,
    Future<void> Function(Conversation) saveFunc,
  ) async {
    for (final conversation in conversations) {
      final updated = conversation.copyWith(groupId: groupId);
      await saveFunc(updated);
    }
  }
}
