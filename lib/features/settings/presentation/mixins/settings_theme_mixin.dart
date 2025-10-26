import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/themes/app_theme.dart';
import '../../../../shared/utils/dialog_helper.dart';
import '../services/settings_service.dart';

/// 简化后的主题设置 Mixin - 现在委托给 SettingsService
mixin SettingsThemeMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late SettingsService _settingsService;

  @override
  void didChangeDependencies() {
    _settingsService = SettingsService(ref, context);
    super.didChangeDependencies();
  }

  Future<void> showThemeDialog() async {
    final result = await DialogHelper.showChoiceDialog<String>(
      context: context,
      title: '选择主题',
      choices: [
        DialogChoice(label: '浅色', value: 'light'),
        DialogChoice(label: '深色', value: 'dark'),
        DialogChoice(label: '跟随系统', value: 'system'),
      ],
    );

    if (result != null) {
      await _settingsService.updateAppSettings(
        (settings) => settings.copyWith(themeMode: result),
      );
    }
  }

  Future<void> showThemeColorDialog() async {
    final settings = await ref.read(appSettingsProvider.future);
    if (!context.mounted) return;

    final choices = AppTheme.predefinedColors.entries
        .map((e) => DialogChoice(label: e.key, value: e.key))
        .toList();

    final result = await DialogHelper.showChoiceDialog<String>(
      context: context,
      title: '选择主题颜色',
      choices: choices,
    );

    if (result != null) {
      await _settingsService.updateAppSettings(
        (settings) => settings.copyWith(themeColor: result),
      );
    }
  }

  Future<void> updateFontSize(double fontSize) =>
      _settingsService.updateAppSettings(
        (s) => s.copyWith(fontSize: fontSize),
      );

  Future<void> updateMarkdownEnabled(bool enabled) =>
      _settingsService.updateAppSettings(
        (s) => s.copyWith(enableMarkdown: enabled),
      );

  Future<void> updateCodeHighlightEnabled(bool enabled) =>
      _settingsService.updateAppSettings(
        (s) => s.copyWith(enableCodeHighlight: enabled),
      );

  Future<void> updateLatexEnabled(bool enabled) =>
      _settingsService.updateAppSettings(
        (s) => s.copyWith(enableLatex: enabled),
      );

  Future<void> showBackgroundDialog() async {
    // TODO: 实现背景设置对话框
  }
}
