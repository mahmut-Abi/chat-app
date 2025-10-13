import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'shared/themes/app_theme.dart';
import 'core/storage/storage_service.dart';
import 'core/providers/providers.dart';
import 'features/settings/domain/api_config.dart';
import 'core/utils/desktop_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop features
  if (DesktopUtils.isDesktop) {
    await DesktopUtils.initWindowManager();
    await DesktopUtils.initSystemTray();
  }

  // Initialize storage
  final storage = StorageService();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final themeColor = _getThemeColor(settings);

    return MaterialApp.router(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(themeColor),
      darkTheme: AppTheme.getDarkTheme(themeColor),
      themeMode: _getThemeMode(settings.themeMode),
      routerConfig: AppRouter.router,
  );
}

  Color? _getThemeColor(AppSettings settings) {
    if (settings.customThemeColor != null) {
      return Color(settings.customThemeColor!);
    }
    if (settings.themeColor != null) {
      return AppTheme.predefinedColors[settings.themeColor];
    }
    return null;
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
