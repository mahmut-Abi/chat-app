import '../../features/chat/domain/conversation.dart';
import 'pdf_export.dart';
import 'markdown_export.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 批量操作工具类
///
/// 提供对话的批量处理功能，包括删除、导出、标签管理等。
class BatchOperations {
  /// 批量删除会话
  ///
  /// [ids] 需要删除的会话 ID 列表
  /// [deleteFunc] 单个删除操作的回调函数
  static Future<void> batchDelete(
    List<String> ids,
    Future<void> Function(String) deleteFunc,
  ) async {
    for (final id in ids) {
      await deleteFunc(id);
    }
  }

  /// 批量导出为 Markdown
  ///
  /// [conversations] 需要导出的会话列表
  /// 返回生成的 Markdown 文件
  static Future<File?> batchExportMarkdown(
    List<Conversation> conversations,
  ) async {
    final content = MarkdownExport.exportConversations(conversations);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/conversations_export_${DateTime.now().millisecondsSinceEpoch}.md',
    );
    await file.writeAsString(content);
    return file;
  }

  /// 批量导出为 PDF
  ///
  /// [conversations] 需要导出的会话列表
  static Future<void> batchExportPdf(List<Conversation> conversations) async {
    await PdfExport.exportConversationsToPdf(conversations);
  }

  /// 批量添加标签
  ///
  /// [conversations] 需要添加标签的会话列表
  /// [tags] 要添加的标签列表
  /// [saveFunc] 保存会话的回调函数
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
  ///
  /// [conversations] 需要移除标签的会话列表
  /// [tags] 要移除的标签列表
  /// [saveFunc] 保存会话的回调函数
  static Future<void> batchRemoveTags(
    List<Conversation> conversations,
    List<String> tags,
    Future<void> Function(Conversation) saveFunc,
  ) async {
    for (final conversation in conversations) {
      final updatedTags = conversation.tags
          .where((t) => !tags.contains(t))
          .toList();
      final updated = conversation.copyWith(tags: updatedTags);
      await saveFunc(updated);
    }
  }

  /// 批量移动到分组
  ///
  /// [conversations] 需要移动的会话列表
  /// [groupId] 目标分组 ID，为 null 表示移出分组
  /// [saveFunc] 保存会话的回调函数
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
