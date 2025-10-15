import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/themes/app_theme.dart';
import '../background_settings_screen.dart';

mixin SettingsThemeMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Future<void> showThemeDialog() async {
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

  void showBackgroundDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const BackgroundSettingsScreen(),
      ),
    );
  }

  Future<void> showThemeColorDialog() async {
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
      updateThemeColor(result);
    }
  }

  Future<void> updateThemeColor(String colorKey) async {
    final currentSettings = ref.read(appSettingsProvider);
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(currentSettings.copyWith(themeColor: colorKey));
  }

  Future<void> updateFontSize(double fontSize) async {
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(fontSize: fontSize),
        );
  }

  Future<void> updateMarkdownEnabled(bool enabled) async {
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(enableMarkdown: enabled),
        );
  }

  Future<void> updateCodeHighlightEnabled(bool enabled) async {
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(enableCodeHighlight: enabled),
        );
  }

  Future<void> updateLatexEnabled(bool enabled) async {
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(enableLatex: enabled),
        );
  }
}
