import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/data/agent_tool_cache.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('AgentToolCache Tests', () {
    late AgentToolCache cache;

    setUp(() {
      cache = AgentToolCache();
    });

    tearDown(() {
      cache.dispose();
    });

    group('Basic Cache Operations', () {
      test('should cache tool result', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Cached result',
        );

        final args = {'input': 'test'};
        cache.set('tool1', args, result);
        final cached = cache.get('tool1', args);

        expect(cached, isNotNull);
        expect(cached?.result, 'Cached result');
      });

      test('should return null for missing cache', () {
        final cached = cache.get('nonexistent', {});
        expect(cached, null);
      });

      test('should clear all cache', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Test',
        );

        cache.set('tool1', {'a': '1'}, result);
        cache.set('tool2', {'b': '2'}, result);
        cache.clearAll();

        expect(cache.get('tool1', {'a': '1'}), null);
        expect(cache.get('tool2', {'b': '2'}), null);
      });
    });

    group('Cache Properties', () {
      test('should track cache size', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Test',
        );

        cache.set('tool1', {'x': '1'}, result);
        cache.set('tool1', {'x': '2'}, result);
        cache.set('tool2', {'y': '1'}, result);

        expect(cache.size, greaterThanOrEqualTo(3));
      });
    });

    group('Multiple Tool Caching', () {
      test('should cache results for different tools', () {
        final result1 = ToolExecutionResult(
          success: true,
          result: 'Calculator result',
        );
        final result2 = ToolExecutionResult(
          success: true,
          result: 'Search result',
        );

        final args1 = {'expr': 'calc'};
        final args2 = {'query': 'search'};
        
        cache.set('calculator', args1, result1);
        cache.set('search', args2, result2);

        expect(cache.get('calculator', args1)?.result, 'Calculator result');
        expect(cache.get('search', args2)?.result, 'Search result');
      });
    });
  });
}
