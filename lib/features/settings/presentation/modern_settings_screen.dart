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
import 'package:go_router/go_router.dart';

/// 现代化设置页面
class ModernSettingsScreen extends ConsumerStatefulWidget {
  const ModernSettingsScreen({super.key});

  @override
  ConsumerState<ModernSettingsScreen> createState() =>
      _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends ConsumerState<ModernSettingsScreen>
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
  int _selectedIndex = 0;

  static const List<_SettingsTab> _tabs = [
    _SettingsTab(icon: Icons.api, label: 'API', title: 'API 配置'),
    _SettingsTab(icon: Icons.palette_outlined, label: '外观', title: '外观设置'),
    _SettingsTab(icon: Icons.extension_outlined, label: '高级', title: '高级功能'),
    _SettingsTab(icon: Icons.storage_outlined, label: '数据', title: '数据管理'),
    _SettingsTab(icon: Icons.info_outline, label: '关于', title: '关于应用'),
  ];

  @override
  void initState() {
    super.initState();
    _log.info('初始化现代化设置页面');
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadApiConfigs();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApiConfigs() async {
    _log.debug('开始加载 API 配置');
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

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
          _errorMessage = '加载配置失败：\${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          _buildSideNav(context),
          Expanded(
            child: _isLoading
                ? _buildLoadingWidget()
                : _errorMessage != null
                ? _buildErrorWidget()
                : _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          _buildSideNavHeader(context, colorScheme),
          const Divider(height: 1),
          Expanded(child: _buildNavList(context, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildSideNavHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            tooltip: '返回',
          ),
          const SizedBox(width: 12),
          Icon(Icons.settings_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            '设置',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNavList(BuildContext context, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _tabs.length,
      itemBuilder: (context, index) {
        return _buildNavItem(context, colorScheme, index);
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    ColorScheme colorScheme,
    int index,
  ) {
    final tab = _tabs[index];
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          tab.icon,
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          tab.label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
        onTap: () => _tabController.animateTo(index),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        _buildContentHeader(context),
        const Divider(height: 1),
        Expanded(child: _buildTabView()),
      ],
    );
  }

  Widget _buildContentHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentTab = _tabs[_selectedIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Row(
        children: [
          Icon(currentTab.icon, color: colorScheme.primary, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentTab.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getTabDescription(_selectedIndex),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildApiTab(),
        _buildThemeTab(),
        _buildAdvancedTab(),
        _buildDataTab(),
        _buildAboutTab(),
      ],
    );
  }

  String _getTabDescription(int index) {
    switch (index) {
      case 0:
        return '配置 API 端点和密钥';
      case 1:
        return '自定义应用外观和主题';
      case 2:
        return '高级功能和实验性特性';
      case 3:
        return '管理和备份应用数据';
      case 4:
        return '应用信息和版本';
      default:
        return '';
    }
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '加载失败',
            style: TextStyle(color: colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadApiConfigs,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildApiTab() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        _buildCard(
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
      padding: const EdgeInsets.all(32),
      children: [
        _buildCard(
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
      padding: const EdgeInsets.all(32),
      children: [_buildCard(child: const AdvancedSettingsSection())],
    );
  }

  Widget _buildDataTab() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        _buildCard(
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
      padding: const EdgeInsets.all(32),
      children: [_buildCard(child: const AboutSection())],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

class _SettingsTab {
  final IconData icon;
  final String label;
  final String title;

  const _SettingsTab({
    required this.icon,
    required this.label,
    required this.title,
  });
}
