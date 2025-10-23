import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/utils/data_export_import.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/utils/message_utils.dart';
import '../../../../core/utils/pdf_export.dart';
import '../../../../shared/widgets/platform_dialog.dart';
import 'dart:io';

mixin SettingsDataMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final LogService _log = LogService();
  bool _isExporting = false;
  bool _isImporting = false;

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;

  Future<void> exportData() async {
    _log.info('Open export');
    if (_isExporting) return;
    try {
      if (mounted) setState(() => _isExporting = true);
      final storageService = ref.read(storageServiceProvider);
      final exportImport = DataExportImport(storageService);
      final jsonData = await exportImport.exportAllData();
      if (!mounted) return;
      if (PlatformUtils.isIOS) {
        await _shareFileOnIOS(jsonData);
      } else if (PlatformUtils.isAndroid) {
        await _shareFileOnAndroid(jsonData);
      } else {
        await _saveFileOnDesktop(jsonData);
      }
    } catch (e, stack) {
      _log.error('Export failed', e, stack);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareFileOnIOS(String jsonData) async {
    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_export_$timestamp.json';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonData);

      // iOS 需要提供 sharePositionOrigin 以支持 iPad
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Chat Export',
        sharePositionOrigin: sharePositionOrigin,
      );

      if (mounted) {
        MessageUtils.showSuccess(context, 'Export successful');
      }
    } catch (e, stack) {
      _log.error('iOS share failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _shareFileOnAndroid(String jsonData) async {
    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_export_$timestamp.json';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonData);

      await Share.shareXFiles([XFile(filePath)], subject: 'Chat Export');

      if (mounted) {
        MessageUtils.showSuccess(context, 'Export successful');
      }
    } catch (e, stack) {
      _log.error('Android share failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveFileOnDesktop(String jsonData) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Data',
        fileName: 'chat_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export successful'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stack) {
      _log.error('Desktop save failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> exportToPdf() async {
    _log.info('Export to PDF');
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final conversations = chatRepo.getAllConversations();

      if (conversations.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('没有对话可导出'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 导出所有对话为 PDF
      await PdfExport.exportConversationsToPdf(conversations);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF 导出成功'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      _log.error('PDF export failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 导出失败: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> importData() async {
    _log.info('Start import');
    if (_isImporting) return;
    try {
      if (mounted) setState(() => _isImporting = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select import file',
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) throw Exception('No file path');
      final file = File(filePath);
      final jsonData = await file.readAsString();
      final storageService = ref.read(storageServiceProvider);
      final exportImport = DataExportImport(storageService);
      final importResult = await exportImport.importData(jsonData);
      if (!mounted) return;
      if (importResult['success'] == true) {
        _log.info('Import successful', importResult);

        // 刷新所有相关的 provider 以立即生效
        ref.invalidate(appSettingsProvider);
        ref.invalidate(activeApiConfigProvider);
        ref.invalidate(agentConfigsProvider);
        ref.invalidate(agentToolsProvider);
        ref.invalidate(mcpConfigsProvider);
        ref.invalidate(promptTemplatesProvider);
        ref.invalidate(conversationsProvider);
        print('🔄 Settings: 已刷新 conversationsProvider');
        ref.invalidate(conversationGroupsProvider);
        print('🔄 Settings: 已刷新 conversationGroupsProvider');

        // 强制刷新设置
        final settingsRepo = ref.read(settingsRepositoryProvider);
        final settings = await settingsRepo.getSettings();
        await ref.read(appSettingsProvider.notifier).updateSettings(settings);

        // 等待 conversations 提供程序完成重建，确保导入的数据立即可用
        try {
          await ref.read(conversationsProvider.future);
          await ref.read(conversationGroupsProvider.future);
          print('✅ Settings: 对话列表已重新加载完成');
        } catch (e) {
          _log.error('Failed to reload conversations after import', e);
        }

        // 🔑 关键修复：强制刷新 Chat 相关的 providers 和 UI
        // 这确保即使用户还在 Chat 页面，也能立即看到新导入的数据
        if (mounted) {
          // 延迟以确保 providers 完全重建
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (mounted) {
            // 额外刷新 Chat 相关的 providers
            ref.invalidate(chatRepositoryProvider);
            ref.invalidate(modelsRepositoryProvider);
            ref.invalidate(dioClientProvider);
            ref.invalidate(openAIApiClientProvider);
            print('🔄 Settings: 已刷新 ChatRepository 相关 providers');
            
            // 强制重建整个 widget 树
            WidgetsBinding.instance.scheduleFrame();
            print('✅ Settings: 已触发 UI 重建');
          }
        }

        if (mounted) {
          final msg = '导入成功：';
          final counts = [];
          if (importResult['conversationsCount'] ?? 0 > 0)
            counts.add('${importResult['conversationsCount']} 对话');
          if (importResult['apiConfigsCount'] ?? 0 > 0)
            counts.add('${importResult['apiConfigsCount']} API');
          if (importResult['mcpConfigsCount'] ?? 0 > 0)
            counts.add('${importResult['mcpConfigsCount']} MCP');
          if (importResult['agentConfigsCount'] ?? 0 > 0)
            counts.add('${importResult['agentConfigsCount']} Agent');
          if (importResult['groupsCount'] ?? 0 > 0)
            counts.add('${importResult['groupsCount']} 分组');
          if (importResult['promptTemplatesCount'] ?? 0 > 0)
            counts.add('${importResult['promptTemplatesCount']} 模板');
          final message = msg + counts.join(', ');
          MessageUtils.showSuccess(
            context,
            message,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e, stack) {
      _log.error('Import failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> showClearDataDialog() async {
    final confirm = await showPlatformConfirmDialog(
      context: context,
      title: 'Clear all data',
      content: 'This action will delete all conversations and configurations.',
      confirmText: 'Clear',
      cancelText: 'Cancel',
      isDestructive: true,
    );
    if (confirm == true) await clearAllData();
  }

  Future<void> clearAllData() async {
    try {
      final storageService = ref.read(storageServiceProvider);
      await storageService.clearAll();
      _log.info('Data cleared');

      // 清空数据后也需要刷新 provider
      ref.invalidate(appSettingsProvider);
      ref.invalidate(activeApiConfigProvider);
      ref.invalidate(agentConfigsProvider);
      ref.invalidate(agentToolsProvider);
      ref.invalidate(mcpConfigsProvider);
      ref.invalidate(promptTemplatesProvider);
      ref.invalidate(conversationsProvider);
      ref.invalidate(conversationGroupsProvider);

      // 等待 providers 重建完成
      try {
        await ref.read(conversationsProvider.future);
        await ref.read(conversationGroupsProvider.future);
      } catch (e) {
        _log.error('Failed to reload after clear', e);
      }

      if (mounted) {
        MessageUtils.showSuccess(context, 'Data cleared');
      }
    } catch (e, stack) {
      _log.error('Clear failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clear failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
