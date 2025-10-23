import 'package:flutter/material.dart';
import '../../../core/utils/platform_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/page_background.dart';
import '../../../core/services/log_service.dart';
import '../domain/api_config.dart';
import 'widgets/api_config_section.dart';
import 'widgets/theme_settings_section.dart';
import 'widgets/data_management_section.dart';
import 'widgets/about_section.dart';
import 'mixins/settings_theme_mixin.dart';
import 'mixins/settings_api_config_mixin.dart';
import 'mixins/settings_data_mixin.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/keyboard_utils.dart';

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

  bool get _isMobile => PlatformUtils.isIOS || PlatformUtils.isAndroid;

  @override
  void initState() {
    super.initState();
    _log.info('初始化现代化设置页面');
    // 确保进入设置页面时没有焦点，避免 iOS 上弹出键盘
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        KeyboardUtils.dismissKeyboard(context);
      }
    });
    _tabController = TabController(length: _tabs.length, vsync: this);
    // 监听 animation 而不是 index，这样可以在滑动过程中实时响应
    _tabController.animation?.addListener(_handleTabAnimation);
    _loadApiConfigs();
  }

  void _handleTabAnimation() {
    // 在滑动过程中，当滑动超过 50% 时立即更新 tab 选中状态
    if (mounted && _tabController.animation != null) {
      final newIndex = _tabController.animation!.value.round();
      if (_selectedIndex != newIndex) {
        setState(() {
          _selectedIndex = newIndex;
        });
      }
    }
  }

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      // 点击 tab 时，立即更新状态并切换页面
      setState(() {
        _selectedIndex = index;
      });
      _tabController.animateTo(index);
    }
  }

  @override
  void dispose() {
    _tabController.animation?.removeListener(_handleTabAnimation);
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
          _errorMessage = '加载配置失败：${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isMobile) {
      return PageBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(_tabs[_selectedIndex].title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildMobileTabBar(context),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingWidget()
                      : _errorMessage != null
                      ? _buildErrorWidget()
                      : _buildTabView(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
      ),
    );
  }

  Widget _buildMobileTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = _selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Material(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _onTabSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 20,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
        onTap: () => _onTabSelected(index),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildApiTab(),
        _buildThemeTab(),
        _buildAdvancedTab(),
        _buildDataTab(),
        _buildAboutTab(),
      ],
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
          child: ImprovedApiConfigSection(
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
          child: ImprovedThemeSettingsSection(
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

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, color: colorScheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [_buildCard(child: _buildAdvancedContent())],
    );
  }

  Widget _buildAdvancedContent() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '工具与功能',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '快速访问应用的各项功能',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _buildToolCard(
          icon: Icons.lightbulb_outline,
          title: '提示词模板',
          description: '管理和使用提示词模板',
          onTap: () => context.push('/prompts'),
        ),
        _buildToolCard(
          icon: Icons.memory_outlined,
          title: '模型管理',
          description: '查看和管理 AI 模型',
          onTap: () => context.push('/models'),
        ),
        _buildToolCard(
          icon: Icons.cloud_outlined,
          title: 'MCP 配置',
          description: '配置 Model Context Protocol 服务器',
          onTap: () => context.push('/mcp'),
        ),
        _buildToolCard(
          icon: Icons.smart_toy_outlined,
          title: 'Agent 管理',
          description: '配置和管理 AI Agent 代理',
          onTap: () => context.push('/agent'),
        ),
        _buildToolCard(
          icon: Icons.bar_chart_outlined,
          title: 'Token 统计',
          description: '查看 Token 使用情况',
          onTap: () => context.push('/token-usage'),
        ),
        _buildToolCard(
          icon: Icons.description_outlined,
          title: '日志查看',
          description: '查看应用运行日志',
          onTap: () => context.push('/logs'),
        ),
      ],
    );
  }

  Widget _buildDataTab() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        _buildCard(
          child: ImprovedDataManagementSection(
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
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200), // 增加宽度限制
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
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
