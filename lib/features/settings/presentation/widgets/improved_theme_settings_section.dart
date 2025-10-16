import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/log_service.dart';

/// 改进的主题设置区域
class ImprovedThemeSettingsSection extends ConsumerWidget {
  final VoidCallback onShowThemeDialog;
  final VoidCallback onShowThemeColorDialog;
  final Function(double) onFontSizeChange;
  final Function(bool) onMarkdownChange;
  final Function(bool) onCodeHighlightChange;
  final Function(bool) onLatexChange;
  final VoidCallback onShowBackgroundDialog;

  const ImprovedThemeSettingsSection({
    super.key,
    required this.onShowThemeDialog,
    required this.onShowThemeColorDialog,
    required this.onFontSizeChange,
    required this.onMarkdownChange,
    required this.onCodeHighlightChange,
    required this.onLatexChange,
    required this.onShowBackgroundDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) => _buildSettings(context, settings),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildSettings(context, const AppSettings()),
    );
  }

  Widget _buildSettings(BuildContext context, AppSettings settings) {
    final colorScheme = Theme.of(context).colorScheme;
    final log = LogService();

    return Column(
      children: [
        // 主题模式
        _buildSettingTile(
          context: context,
          icon: Icons.brightness_6_outlined,
          iconColor: colorScheme.primary,
          backgroundColor: colorScheme.primaryContainer,
          title: '主题模式',
          subtitle: _getThemeModeText(settings.themeMode),
          trailing: Icon(
            _getThemeModeIcon(settings.themeMode),
            color: colorScheme.primary,
          ),
          onTap: () {
            log.debug('打开主题模式选择对话框');
            onShowThemeDialog();
          },
        ),

        // 主题颜色
        _buildSettingTile(
          context: context,
          icon: Icons.palette_outlined,
          iconColor: colorScheme.secondary,
          backgroundColor: colorScheme.secondaryContainer,
          title: '主题颜色',
          subtitle: settings.themeColor ?? '默认蓝色',
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getThemeColor(context, settings.themeColor),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outline, width: 2),
            ),
          ),
          onTap: () {
            log.debug('打开主题颜色选择对话框');
            onShowThemeColorDialog();
          },
        ),

        // 字体大小
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.tertiaryContainer,
              child: Icon(Icons.format_size, color: colorScheme.tertiary),
            ),
            title: Text(
              '字体大小',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('${settings.fontSize.toInt()} pt'),
                Slider(
                  value: settings.fontSize,
                  min: 12.0,
                  max: 20.0,
                  divisions: 8,
                  label: settings.fontSize.toInt().toString(),
                  onChanged: (value) {
                    log.debug('调整字体大小', {'fontSize': value});
                    onFontSizeChange(value);
                  },
                ),
              ],
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 24),
        ),

        // 渲染选项
        _buildSwitchTile(
          context: context,
          icon: Icons.code,
          iconColor: Colors.blue,
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          title: '启用 Markdown 渲染',
          subtitle: '支持文本格式化和代码高亮',
          value: settings.enableMarkdown,
          onChanged: (value) {
            log.info('切换Markdown渲染', {'enabled': value});
            onMarkdownChange(value);
          },
        ),

        _buildSwitchTile(
          context: context,
          icon: Icons.highlight,
          iconColor: Colors.orange,
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          title: '启用代码高亮',
          subtitle: '高亮显示代码块',
          value: settings.enableCodeHighlight,
          onChanged: (value) {
            log.info('切换代码高亮', {'enabled': value});
            onCodeHighlightChange(value);
          },
        ),

        _buildSwitchTile(
          context: context,
          icon: Icons.functions,
          iconColor: Colors.purple,
          backgroundColor: Colors.purple.withValues(alpha: 0.1),
          title: '启用 LaTeX 数学公式',
          subtitle: '渲染数学公式（实验性）',
          value: settings.enableLatex,
          onChanged: (value) {
            log.info('切换LaTeX渲染', {'enabled': value});
            onLatexChange(value);
          },
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 24),
        ),

        // 背景设置
        _buildSettingTile(
          context: context,
          icon: Icons.wallpaper,
          iconColor: Colors.green,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          title: '背景设置',
          subtitle: '自定义聊天背景',
          onTap: () {
            log.debug('打开背景设置页面');
            onShowBackgroundDialog();
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: () => onChanged(!value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getThemeModeText(String themeMode) {
    switch (themeMode) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      default:
        return '跟随系统';
    }
  }

  IconData _getThemeModeIcon(String themeMode) {
    switch (themeMode) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  Color _getThemeColor(BuildContext context, String? colorKey) {
    if (colorKey == null) {
      return Theme.of(context).colorScheme.primary;
    }
    // 这里需要从AppTheme获取实际颜色
    // 简化实现
    return Theme.of(context).colorScheme.primary;
  }
}
