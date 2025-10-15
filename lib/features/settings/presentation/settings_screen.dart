import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../domain/api_config.dart';
import 'widgets/api_config_section.dart';
import 'widgets/theme_settings_section.dart';
import 'widgets/data_management_section.dart';
import 'widgets/advanced_settings_section.dart';
import 'widgets/about_section.dart';
import 'mixins/settings_theme_mixin.dart';
import 'mixins/settings_api_config_mixin.dart';
import 'mixins/settings_data_mixin.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SettingsThemeMixin, SettingsApiConfigMixin, SettingsDataMixin {
  List<ApiConfig> _apiConfigs = [];

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
                onAddConfig: () => addApiConfig(_loadApiConfigs),
                onEditConfig: (config) =>
                    editApiConfig(config, _loadApiConfigs),
                onDeleteConfig: (config) =>
                    deleteApiConfig(config, _loadApiConfigs),
                onTestConnection: testApiConnection,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: '外观',
            children: [
              ThemeSettingsSection(
                onShowThemeDialog: showThemeDialog,
                onShowThemeColorDialog: showThemeColorDialog,
                onFontSizeChange: updateFontSize,
                onMarkdownChange: updateMarkdownEnabled,
                onCodeHighlightChange: updateCodeHighlightEnabled,
                onLatexChange: updateLatexEnabled,
                onShowBackgroundDialog: showBackgroundDialog,
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
                onExportData: exportData,
                onExportPdf: exportToPdf,
                onImportData: importData,
                onClearData: showClearDataDialog,
                isExporting: isExporting,
                isImporting: isImporting,
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
}
