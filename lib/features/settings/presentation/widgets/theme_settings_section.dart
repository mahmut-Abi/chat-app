import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';

/// 主题设置区域
class ThemeSettingsSection extends ConsumerWidget {
  final VoidCallback onShowThemeDialog;
  final VoidCallback onShowThemeColorDialog;
  final Function(double) onFontSizeChange;
  final Function(bool) onMarkdownChange;
  final Function(bool) onCodeHighlightChange;
  final Function(bool) onLatexChange;
  final VoidCallback onShowBackgroundDialog;

  const ThemeSettingsSection({
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
    final settings = ref.watch(appSettingsProvider);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('主题模式'),
          subtitle: Text(_getThemeModeText(settings.themeMode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onShowThemeDialog,
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: const Text('主题颜色'),
          subtitle: Text(settings.themeColor ?? '默认'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onShowThemeColorDialog,
        ),
        ListTile(
          leading: const Icon(Icons.format_size),
          title: const Text('字体大小'),
          subtitle: Text('${settings.fontSize.toInt()}'),
          trailing: SizedBox(
            width: 150,
            child: Slider(
              value: settings.fontSize,
              min: 12.0,
              max: 20.0,
              divisions: 8,
              label: settings.fontSize.toInt().toString(),
              onChanged: onFontSizeChange,
            ),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.code),
          title: const Text('启用 Markdown 渲染'),
          subtitle: const Text('支持文本格式化和代码高亮'),
          value: settings.enableMarkdown,
          onChanged: onMarkdownChange,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.highlight),
          title: const Text('启用代码高亮'),
          subtitle: const Text('高亮显示代码块'),
          value: settings.enableCodeHighlight,
          onChanged: onCodeHighlightChange,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.functions),
          title: const Text('启用 LaTeX 数学公式'),
          subtitle: const Text('渲染数学公式（实验性）'),
          value: settings.enableLatex,
          onChanged: onLatexChange,
        ),
        ListTile(
          leading: const Icon(Icons.wallpaper),
          title: const Text('背景设置'),
          subtitle: const Text('自定义聊天背景'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onShowBackgroundDialog,
        ),
      ],
    );
  }

  String _getThemeModeText(String themeMode) {
    switch (themeMode) {
      case 'light':
        return '浅色';
      case 'dark':
        return '深色';
      default:
        return '跟随系统';
    }
  }
}
