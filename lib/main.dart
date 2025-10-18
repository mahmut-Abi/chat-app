import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'core/routing/app_router.dart';
import 'core/utils/platform_utils.dart';
import 'shared/themes/app_theme.dart';
import 'core/storage/storage_service.dart';
import 'core/providers/providers.dart';
import 'features/settings/domain/api_config.dart';
import 'core/utils/desktop_utils.dart';
import 'core/services/permission_service.dart';
import 'core/services/log_service.dart';
import 'core/services/network_service.dart';
import 'core/services/app_initialization_service.dart';
import 'shared/widgets/background_container.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 检查和请求权限（仅移动端）
      if (!kIsWeb && (PlatformUtils.isIOS || PlatformUtils.isAndroid)) {
        final permissionService = PermissionService();
        final log = LogService();
        try {
          await permissionService.checkAndRequestPermissions();
          log.info('权限检查完成');
        } catch (e) {
          log.error('权限检查失败', {'error': e.toString()});
        }

        // 检查网络连接状态
        final networkService = NetworkService();
        try {
          final hasNetwork = await networkService.checkNetworkConnection();
          final networkType = await networkService.getConnectionType();
          log.info('网络状态检查完成', {
            'hasConnection': hasNetwork,
            'type': networkType,
          });

          if (!hasNetwork) {
            log.warning('应用启动时无网络连接');
          }
        } catch (e) {
          log.error('网络检查失败', {'error': e.toString()});
        }
      }

      // Initialize desktop features
      if (!kIsWeb && DesktopUtils.isDesktop) {
        await DesktopUtils.initWindowManager();
        await DesktopUtils.initSystemTray();
      }

      // Initialize storage
      final storage = StorageService();
      await storage.init();

      // Initialize app data (tools, agents, etc.)
      final log = LogService();
      try {
        final initService = AppInitializationService(storage);
        await initService.initialize();
        log.info('应用数据初始化完成');
      } catch (e) {
        log.error('应用数据初始化失败，将继续启动', {'error': e.toString()});
      }

      runApp(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('应用错误: $error');
      debugPrint('堆栈信息: $stack');
    },
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) => _buildApp(settings),
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) => _buildApp(const AppSettings()),
    );
  }

  Widget _buildApp(AppSettings settings) {
    final themeColor = _getThemeColor(settings);
    final fontSize = settings.fontSize;

    return BackgroundContainer(
      child: MaterialApp.router(
        title: 'Chat App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getLightTheme(themeColor, fontSize),
        darkTheme: AppTheme.getDarkTheme(themeColor, fontSize),
        themeMode: _getThemeMode(settings.themeMode),
        routerConfig: AppRouter.router,
      ),
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
