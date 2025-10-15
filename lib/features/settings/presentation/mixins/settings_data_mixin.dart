import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/data_export_import.dart';
import '../../../../core/utils/pdf_export.dart';
import '../../../chat/domain/conversation.dart';
import '../../../../shared/widgets/platform_dialog.dart';

/// 数据管理相关的 Mixin
mixin SettingsDataMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _isExporting = false;
  bool _isImporting = false;

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;

  Future<void> exportData() async {
    setState(() => _isExporting = true);

    try {
      final storage = ref.read(storageServiceProvider);
      final exporter = DataExportImport(storage);
      final jsonData = await exporter.exportAllData();

      final fileName =
          'chat_app_export_${DateTime.now().toIso8601String().split('T')[0]}.json';

      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: '保存导出文件',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsString(jsonData);

          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('导出成功')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('当前平台暂不支持导出功能')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> importData() async {
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonData = await file.readAsString();

        final storage = ref.read(storageServiceProvider);
        final importer = DataExportImport(storage);
        final importResult = await importer.importData(jsonData);

        if (mounted) {
          if (importResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '成功导入 ${importResult['conversationsCount']} 个对话和 ${importResult['apiConfigsCount']} 个配置',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('导入失败: ${importResult['error']}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> exportToPdf() async {
    final conversations = await showDialog<List<Conversation>>(
      context: context,
      builder: (context) => _ConversationSelectionDialog(),
    );

    if (conversations != null && conversations.isNotEmpty) {
      try {
        await PdfExport.exportConversationsToPdf(conversations);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF 导出失败: ${e.toString()}')));
        }
      }
    }
  }

  Future<void> showClearDataDialog() async {
    final confirm = await showPlatformConfirmDialog(
      context: context,
      title: '清除所有数据',
      content: '这将删除所有对话和设置。此操作无法撤销。',
      confirmText: '清除',
      isDestructive: true,
    );

    if (confirm == true) {
      final storage = ref.read(storageServiceProvider);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await storage.clearAll();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('所有数据已清除')));
      }
    }
  }
}

class _ConversationSelectionDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ConversationSelectionDialog> createState() =>
      _ConversationSelectionDialogState();
}

class _ConversationSelectionDialogState
    extends ConsumerState<_ConversationSelectionDialog> {
  final Set<String> selected = {};

  @override
  Widget build(BuildContext context) {
    final chatRepo = ref.read(chatRepositoryProvider);
    final conversations = chatRepo.getAllConversations();

    return AlertDialog(
      title: const Text('选择要导出的对话'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return CheckboxListTile(
              title: Text(conversation.title),
              subtitle: Text('${conversation.messages.length} 条消息'),
              value: selected.contains(conversation.id),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    selected.add(conversation.id);
                  } else {
                    selected.remove(conversation.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              if (selected.length == conversations.length) {
                selected.clear();
              } else {
                selected.addAll(conversations.map((c) => c.id));
              }
            });
          },
          child: Text(selected.length == conversations.length ? '取消全选' : '全选'),
        ),
        FilledButton(
          onPressed: selected.isEmpty
              ? null
              : () {
                  final result = conversations
                      .where((c) => selected.contains(c.id))
                      .toList();
                  Navigator.pop(context, result);
                },
          child: const Text('导出'),
        ),
      ],
    );
  }
}
