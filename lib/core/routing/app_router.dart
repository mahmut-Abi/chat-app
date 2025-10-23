import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';
import '../services/log_service.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/home_screen.dart';
import '../../features/settings/presentation/modern_settings_screen.dart';
import '../../features/models/presentation/models_screen.dart';
import '../../features/mcp/presentation/mcp_screen.dart';
import '../../features/token_usage/presentation/token_usage_screen.dart';
import '../../features/agent/presentation/agent_screen.dart';
import '../../features/prompts/presentation/prompts_screen.dart';
import '../../features/logs/presentation/logs_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const HomeScreen()),
      ),
      GoRoute(
        path: '/chat/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPage(
            context,
            state,
            ChatScreen(key: ValueKey<String>(id), conversationId: id),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const ModernSettingsScreen()),
      ),
      GoRoute(
        path: '/models',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const ModelsScreen()),
      ),
      GoRoute(
        path: '/mcp',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const McpScreen()),
      ),
      GoRoute(
        path: '/token-usage',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const TokenUsageScreen()),
      ),
      GoRoute(
        path: '/agent',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const AgentScreen()),
      ),
      GoRoute(
        path: '/prompts',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const PromptsScreen()),
      ),
      GoRoute(
        path: '/logs',
        pageBuilder: (context, state) =>
            _buildPage(context, state, const LogsScreen()),
      ),
    ],
  );

  /// 构建页面 - 根据平台选择合适的转场动画
  static Page _buildPage(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    // 调试日志
    LogService().debug('Building page', {
      'path': state.path,
      'platform': _getPlatformName(),
      'pageKey': state.pageKey.toString(),
    });

    // 所有平台统一使用 MaterialPage
    // 通过 Theme 的 pageTransitionsTheme 控制不同平台的转场效果
    return MaterialPage(key: state.pageKey, child: child);
  }

  /// 获取平台名称（用于日志）
  static String _getPlatformName() {
    if (PlatformUtils.isIOS) return 'iOS';
    if (PlatformUtils.isAndroid) return 'Android';
    if (PlatformUtils.isMacOS) return 'macOS';
    if (PlatformUtils.isWindows) return 'Windows';
    if (PlatformUtils.isLinux) return 'Linux';
    if (PlatformUtils.isWeb) return 'Web';
    return 'Unknown';
  }
}
