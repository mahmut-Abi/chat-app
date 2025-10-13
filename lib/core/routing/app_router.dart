import 'package:go_router/go_router.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/home_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/models/presentation/models_screen.dart';
import '../../features/mcp/presentation/mcp_screen.dart';
import '../../features/token_usage/presentation/token_usage_screen.dart';
import '../../features/agent/presentation/agent_screen.dart';
import '../../features/prompts/presentation/prompts_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/models',
        builder: (context, state) => const ModelsScreen(),
      ),
      GoRoute(path: '/mcp', builder: (context, state) => const McpScreen()),
      GoRoute(
        path: '/token-usage',
        builder: (context, state) => const TokenUsageScreen(),
      ),
      GoRoute(path: '/agent', builder: (context, state) => const AgentScreen()),
      GoRoute(
        path: '/prompts',
        builder: (context, state) => const PromptsScreen(),
      ),
    ],
  );
}
