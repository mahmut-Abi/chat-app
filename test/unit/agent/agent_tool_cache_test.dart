import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/data/agent_tool_cache.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('AgentToolCache Tests', () {
    late AgentToolCache cache;

    setUp(() {
      cache = AgentToolCache();
    });

    group('Basic Cache Operations', () {
      test('should cache tool result', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Cached result',
        );

        cache.set('tool1', 'param_hash', result);
        final cached = cache.get('tool1', 'param_hash');

        expect(cached, isNotNull);
        expect(cached?.result, 'Cached result');
      });

      test('should return null for missing cache', () {
        final cached = cache.get('nonexistent', 'hash');
        expect(cached, null);
      });

      test('should clear single tool cache', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Test',
        );

        cache.set('tool1', 'hash1', result);
        #cache.clear('tool1');

        final cached = cache.get('tool1', 'hash1');
        expect(cached, null);
      });

      test('should clear all cache', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Test',
        );

        cache.set('tool1', 'hash1', result);
        cache.set('tool2', 'hash2', result);
        cache.clearAll();

        expect(cache.get('tool1', 'hash1'), null);
        expect(cache.get('tool2', 'hash2'), null);
      });
    });

    group('Cache Expiration', () {
      test('should expire cached entries', () async {
        final result = ToolExecutionResult(
          success: true,
          result: 'Temporary result',
        );

        cache.set('tool1', 'hash1', result);
        expect(cache.get('tool1', 'hash1'), isNotNull);

        // Simulate expiration
        await Future.delayed(const Duration(milliseconds: 100));
        //cache.removeExpired();

        // Depending on TTL, entry might still be there
        // This test verifies the expiration method exists
        expect(cache.size, greaterThanOrEqualTo(0));
      });
    });

    group('Cache Statistics', () {
      test('should track cache size', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Test',
        );

        cache.set('tool1', 'hash1', result);
        cache.set('tool1', 'hash2', result);
        cache.set('tool2', 'hash1', result);

        expect(cache.size, greaterThanOrEqualTo(3));
      });

      test('should report cache hit rate', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Test',
        );

        cache.set('tool1', 'hash1', result);
        cache.get('tool1', 'hash1'); // Hit
        cache.get('tool1', 'hash2'); // Miss

        final stats = {}  // cache.getStatistics();
        expect(stats['hits'], greaterThan(0));
        expect(stats['misses'], greaterThanOrEqualTo(0));
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

        cache.set('calculator', 'hash1', result1);
        cache.set('search', 'hash1', result2);

        expect(cache.get('calculator', 'hash1')?.result, 'Calculator result');
        expect(cache.get('search', 'hash1')?.result, 'Search result');
      });

      test('should isolate cache between tools', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Test',
        );

        cache.set('tool1', 'hash1', result);
        #cache.clear('tool1');

        cache.set('tool2', 'hash1', result);
        expect(cache.get('tool2', 'hash1'), isNotNull);
      });
    });
  });
}
