import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/platform_utils.dart';
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
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPage(
            context,
            state,
            ChatScreen(
              key: ValueKey<String>(id),
              conversationId: id,
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const ModernSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/models',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const ModelsScreen(),
        ),
      ),
      GoRoute(
        path: '/mcp',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const McpScreen(),
        ),
      ),
      GoRoute(
        path: '/token-usage',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const TokenUsageScreen(),
        ),
      ),
      GoRoute(
        path: '/agent',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const AgentScreen(),
        ),
      ),
      GoRoute(
        path: '/prompts',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const PromptsScreen(),
        ),
      ),
      GoRoute(
        path: '/logs',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const LogsScreen(),
        ),
      ),
    ],
  );

  /// 构建页面 - 根据平台选择合适的转场动画
  static Page _buildPage(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    if (PlatformUtils.isIOS) {
      // iOS使用Cupertino风格的转场动画
      // 不透明背景，避免页面重叠问题
      return CupertinoPage(
        key: state.pageKey,
        child: child,
      );
    } else {
      // Android和其他平台使用Material转场
      return MaterialPage(
        key: state.pageKey,
        child: child,
      );
    }
  }
}
