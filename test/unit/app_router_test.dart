import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/routing/app_router.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AppRouter', () {
    late GoRouter router;

    setUp(() {
      router = AppRouter.router;
    });

    test('应该包含所有必要的路由', () {
      final routes = router.configuration.routes;
      final routePaths = routes.map((r) => (r as GoRoute).path).toList();

      expect(routePaths, contains('/'));
      expect(routePaths, contains('/chat/:id'));
      expect(routePaths, contains('/settings'));
      expect(routePaths, contains('/models'));
      expect(routePaths, contains('/mcp'));
      expect(routePaths, contains('/token-usage'));
      expect(routePaths, contains('/agent'));
      expect(routePaths, contains('/prompts'));
      expect(routePaths, contains('/logs'));
    });

    test('应该有 9 个路由', () {
      expect(router.configuration.routes.length, 9);
    });

    test('聊天路由应该支持参数', () {
      final chatRoute =
          router.configuration.routes.firstWhere(
                (r) => (r as GoRoute).path == '/chat/:id',
              )
              as GoRoute;

      expect(chatRoute.path, '/chat/:id');
    });
  });
}
