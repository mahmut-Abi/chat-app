import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/utils/data_export_import.dart';
import '../../../../core/utils/platform_utils.dart';
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
      final fileName = 'chat_export_' + timestamp.toString() + '.json';
      final filePath = tempDir.path + '/' + fileName;
      final file = File(filePath);
      await file.writeAsString(jsonData);
      await Share.shareXFiles([XFile(filePath)], subject: 'Chat Export');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export successful'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e, stack) {
      _log.error('iOS share failed', e, stack);
    }
  }

  Future<void> _shareFileOnAndroid(String jsonData) async {
    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_export_' + timestamp.toString() + '.json';
      final filePath = tempDir.path + '/' + fileName;
      final file = File(filePath);
      await file.writeAsString(jsonData);
      await Share.shareXFiles([XFile(filePath)], subject: 'Chat Export');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export successful'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e, stack) {
      _log.error('Android share failed', e, stack);
    }
  }

  Future<void> _saveFileOnDesktop(String jsonData) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Data',
        fileName: 'chat_export_' + DateTime.now().millisecondsSinceEpoch.toString() + '.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonData);
      }
    } catch (e, stack) {
      _log.error('Desktop save failed', e, stack);
    }
  }

  Future<void> exportToPdf() async {
    _log.info('Export to PDF');
    try {
      final storageService = ref.read(storageServiceProvider);
      final conversations = storageService.getAllConversations();
      if (conversations.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No conversations to export')),
          );
        }
      }
    } catch (e, stack) {
      _log.error('PDF export failed', e, stack);
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
      }
    } catch (e, stack) {
      _log.error('Import failed', e, stack);
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
    } catch (e, stack) {
      _log.error('Clear failed', e, stack);
    }
  }
}
