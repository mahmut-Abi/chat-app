import 'package:flutter/material.dart';
import '../../../shared/widgets/platform_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../domain/api_config.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/utils/data_export_import.dart';
import '../../../core/utils/pdf_export.dart';
import '../../chat/domain/conversation.dart';
import '../../../shared/themes/app_theme.dart';
import '../../../core/network/openai_api_client.dart';
import '../../../core/network/dio_client.dart';
import 'background_settings_screen.dart';
import 'package:go_router/go_router.dart';
import 'api_config_screen.dart';
import 'widgets/api_config_section.dart';
import 'widgets/theme_settings_section.dart';
import 'widgets/data_management_section.dart';
import 'widgets/advanced_settings_section.dart';
import 'widgets/about_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<ApiConfig> _apiConfigs = [];
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadApiConfigs();
  }

  Future<void> _loadApiConfigs() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final configs = await settingsRepo.getAllApiConfigs();
    setState(() {
      _apiConfigs = configs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSection(
            title: 'API 配置',
            children: [
              ApiConfigSection(
                apiConfigs: _apiConfigs,
                onAddConfig: _addApiConfig,
                onEditConfig: _editApiConfig,
                onDeleteConfig: _deleteApiConfig,
                onTestConnection: _testApiConnection,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: '外观',
            children: [
              ThemeSettingsSection(
                onShowThemeDialog: _showThemeDialog,
                onShowThemeColorDialog: _showThemeColorDialog,
                onFontSizeChange: _updateFontSize,
                onMarkdownChange: _updateMarkdownEnabled,
                onCodeHighlightChange: _updateCodeHighlightEnabled,
                onLatexChange: _updateLatexEnabled,
                onShowBackgroundDialog: _showBackgroundDialog,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: '高级功能',
            children: [const AdvancedSettingsSection()],
          ),
          const Divider(),
          _buildSection(
            title: '数据管理',
            children: [
              DataManagementSection(
                onExportData: _exportData,
                onExportPdf: _exportToPdf,
                onImportData: _importData,
                onClearData: _showClearDataDialog,
                isExporting: _isExporting,
                isImporting: _isImporting,
              ),
            ],
          ),
          const Divider(),
          _buildSection(title: '关于', children: [const AboutSection()]),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Future<void> _showThemeDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('浅色'),
              leading: const Icon(Icons.light_mode),
              onTap: () => Navigator.pop(context, 'light'),
            ),
            ListTile(
              title: const Text('深色'),
              leading: const Icon(Icons.dark_mode),
              onTap: () => Navigator.pop(context, 'dark'),
            ),
            ListTile(
              title: const Text('跟随系统'),
              leading: const Icon(Icons.brightness_auto),
              onTap: () => Navigator.pop(context, 'system'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final currentSettings = ref.read(appSettingsProvider);
      await ref
          .read(appSettingsProvider.notifier)
          .updateSettings(currentSettings.copyWith(themeMode: result));
    }
  }

  void _showBackgroundDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const BackgroundSettingsScreen(),
      ),
    );
  }

  Future<void> _showThemeColorDialog() async {
    final settings = ref.read(appSettingsProvider);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题颜色'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: AppTheme.predefinedColors.length,
            itemBuilder: (context, index) {
              final entry = AppTheme.predefinedColors.entries.elementAt(index);
              final isSelected = settings.themeColor == entry.key;
              return InkWell(
                onTap: () => Navigator.pop(context, entry.key),
                child: Container(
                  decoration: BoxDecoration(
                    color: entry.value,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (result != null) {
      _updateThemeColor(result);
    }
  }

  Future<void> _updateThemeColor(String colorKey) async {
    final currentSettings = ref.read(appSettingsProvider);
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(currentSettings.copyWith(themeColor: colorKey));
  }

  Future<void> _exportData() async {
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
            ).showSnackBar(SnackBar(content: Text('数据已导出到: $path')));
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

  Future<void> _importData() async {
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
            _loadApiConfigs();
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

  Future<void> _addApiConfig() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ApiConfigScreen()));

    if (result == true) {
      _loadApiConfigs();
    }
  }

  Future<void> _editApiConfig(ApiConfig config) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ApiConfigScreen(config: config),
      ),
    );

    if (result == true) {
      _loadApiConfigs();
    }
  }

  Future<void> _deleteApiConfig(ApiConfig config) async {
    final confirm = await _showDeleteConfirmDialog();
    if (confirm == true) {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.deleteApiConfig(config.id);
      _loadApiConfigs();
    }
  }

  Future<bool?> _showDeleteConfirmDialog() {
    return showPlatformConfirmDialog(
      context: context,
      title: '删除 API 配置',
      content: '确定要删除此配置吗？',
      confirmText: '删除',
      isDestructive: true,
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirm = await showPlatformConfirmDialog(
      context: context,
      title: '清除所有数据',
      content: '这将删除所有对话和设置。此操作无法撤销。',
      confirmText: '清除',
      isDestructive: true,
    );

    if (confirm == true) {
      final storage = ref.read(storageServiceProvider);
      if (kDebugMode) {
        print('开始清除所有数据...');
      }

      // 显示加载指示器
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await storage.clearAll();

      // 重置 Provider 状态
      ref.invalidate(appSettingsProvider);
      ref.invalidate(chatRepositoryProvider);

      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('所有数据已清除')));

        // 重新加载 API 配置
        _loadApiConfigs();

        // 返回首页并强制重载
        context.go('/');
      }
    }
  }

  Future<void> _exportToPdf() async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final conversations = chatRepo.getAllConversations();

    if (conversations.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有可导出的对话')));
      }
      return;
    }

    final selectedConversations = await _showSelectConversationsDialog(
      conversations,
    );

    if (selectedConversations != null && selectedConversations.isNotEmpty) {
      try {
        if (selectedConversations.length == 1) {
          await PdfExport.exportConversationToPdf(selectedConversations.first);
        } else {
          await PdfExport.exportConversationsToPdf(selectedConversations);
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PDF 导出成功')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF 导出失败: ${e.toString()}')));
        }
      }
    }
  }

  Future<List<Conversation>?> _showSelectConversationsDialog(
    List<Conversation> conversations,
  ) async {
    final selected = <String>{};
    return showDialog<List<Conversation>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('选择要导出的对话'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return CheckboxListTile(
                  title: Text(conv.title),
                  subtitle: Text('${conv.messages.length} 条消息'),
                  value: selected.contains(conv.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selected.add(conv.id);
                      } else {
                        selected.remove(conv.id);
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
              child: Text(
                selected.length == conversations.length ? '取消全选' : '全选',
              ),
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
        ),
      ),
    );
  }

  Future<void> _updateFontSize(double fontSize) async {
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(fontSize: fontSize),
        );
  }

  Future<void> _updateMarkdownEnabled(bool enabled) async {
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(enableMarkdown: enabled),
        );
  }

  Future<void> _updateCodeHighlightEnabled(bool enabled) async {
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(enableCodeHighlight: enabled),
        );
  }

  Future<void> _updateLatexEnabled(bool enabled) async {
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(enableLatex: enabled),
        );
  }

  // 测试 API 连接
  Future<void> _testApiConnection(ApiConfig config) async {
    showPlatformLoadingDialog(context: context, message: '正在测试连接...');

    try {
      final dioClient = DioClient(
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
        proxyUrl: config.proxyUrl,
      );
      final apiClient = OpenAIApiClient(dioClient);
      final result = await apiClient.testConnection();

      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result.success ? '连接成功' : '连接失败'),
            content: Text(result.message),
            icon: Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
              size: 48,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('连接失败'),
            content: Text('发生错误: ${e.toString()}'),
            icon: const Icon(Icons.error, color: Colors.red, size: 48),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }
}
