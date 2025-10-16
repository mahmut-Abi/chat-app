import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/log_service.dart';
import '../domain/api_config.dart';
import 'widgets/api_config_section.dart';
import 'widgets/theme_settings_section.dart';
import 'widgets/data_management_section.dart';
import 'widgets/advanced_settings_section.dart';
import 'widgets/about_section.dart';
import 'mixins/settings_theme_mixin.dart';
import 'mixins/settings_api_config_mixin.dart';
import 'mixins/settings_data_mixin.dart';

/// 改进的设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with
        SettingsThemeMixin,
        SettingsApiConfigMixin,
        SettingsDataMixin,
        SingleTickerProviderStateMixin {
  final LogService _log = LogService();
  List<ApiConfig> _apiConfigs = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _log.info('初始化设置页面');
    _tabController = TabController(length: 5, vsync: this);
    _loadApiConfigs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApiConfigs() async {
    _log.debug('开始加载 API 配置');
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final settingsRepo = ref.read(settingsRepositoryProvider);
      final configs = await settingsRepo.getAllApiConfigs();

      if (mounted) {
        setState(() {
          _apiConfigs = configs;
          _isLoading = false;
        });
        _log.info('API 配置加载成功', {'count': configs.length});
      }
    } catch (e, stack) {
      _log.error('加载 API 配置失败', e, stack);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载配置失败：${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.api), text: 'API'),
            Tab(icon: Icon(Icons.palette), text: '外观'),
            Tab(icon: Icon(Icons.extension), text: '高级'),
            Tab(icon: Icon(Icons.storage), text: '数据'),
            Tab(icon: Icon(Icons.info), text: '关于'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _errorMessage != null
          ? _buildErrorWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildApiTab(),
                _buildThemeTab(),
                _buildAdvancedTab(),
                _buildDataTab(),
                _buildAboutTab(),
              ],
            ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载中...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadApiConfigs,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'API 配置',
          icon: Icons.api,
          child: ApiConfigSection(
            apiConfigs: _apiConfigs,
            onAddConfig: () => addApiConfig(_loadApiConfigs),
            onEditConfig: (config) => editApiConfig(config, _loadApiConfigs),
            onDeleteConfig: (config) =>
                deleteApiConfig(config, _loadApiConfigs),
            onTestConnection: testApiConnection,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: '外观设置',
          icon: Icons.palette,
          child: ThemeSettingsSection(
            onShowThemeDialog: showThemeDialog,
            onShowThemeColorDialog: showThemeColorDialog,
            onFontSizeChange: updateFontSize,
            onMarkdownChange: updateMarkdownEnabled,
            onCodeHighlightChange: updateCodeHighlightEnabled,
            onLatexChange: updateLatexEnabled,
            onShowBackgroundDialog: showBackgroundDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: '高级功能',
          icon: Icons.extension,
          child: const AdvancedSettingsSection(),
        ),
      ],
    );
  }

  Widget _buildDataTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: '数据管理',
          icon: Icons.storage,
          child: DataManagementSection(
            onExportData: exportData,
            onExportPdf: exportToPdf,
            onImportData: importData,
            onClearData: showClearDataDialog,
            isExporting: isExporting,
            isImporting: isImporting,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: '关于',
          icon: Icons.info,
          child: const AboutSection(),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}
