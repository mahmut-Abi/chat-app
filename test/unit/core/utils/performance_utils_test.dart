import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/utils/performance_utils.dart';

void main() {
  group('PerformanceUtils', () {
    setUp(() {
      PerformanceUtils.clearCache();
    });

    group('缓存管理', () {
      test('应该能够缓存数据', () {
        // Arrange
        const key = 'test_key';
        const value = 'test_value';

        // Act
        PerformanceUtils.cache(key, value);
        final result = PerformanceUtils.getCache<String>(key);

        // Assert
        expect(result, equals(value));
      });

      test('应该支持不同类型的缓存', () {
        // Arrange & Act
        PerformanceUtils.cache('string', 'text');
        PerformanceUtils.cache('int', 123);
        PerformanceUtils.cache('bool', true);
        PerformanceUtils.cache('list', [1, 2, 3]);
        PerformanceUtils.cache('map', {'key': 'value'});

        // Assert
        expect(PerformanceUtils.getCache<String>('string'), 'text');
        expect(PerformanceUtils.getCache<int>('int'), 123);
        expect(PerformanceUtils.getCache<bool>('bool'), true);
        expect(PerformanceUtils.getCache<List>('list'), [1, 2, 3]);
        expect(PerformanceUtils.getCache<Map>('map'), {'key': 'value'});
      });

      test('应该在缓存不存在时返回 null', () {
        // Act
        final result = PerformanceUtils.getCache<String>('nonexistent');

        // Assert
        expect(result, isNull);
      });

      test('应该清除所有缓存', () {
        // Arrange
        PerformanceUtils.cache('key1', 'value1');
        PerformanceUtils.cache('key2', 'value2');

        // Act
        PerformanceUtils.clearCache();

        // Assert
        expect(PerformanceUtils.getCache<String>('key1'), isNull);
        expect(PerformanceUtils.getCache<String>('key2'), isNull);
      });
    });

    group('性能监控', () {
      test('应该成功测量异步任务性能', () async {
        // Arrange
        Future<int> task() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 42;
        }

        // Act
        final result = await PerformanceUtils.measurePerformance(
          label: '测试任务',
          task: task,
        );

        // Assert
        expect(result, 42);
      });

      test('应该在任务失败时抛出异常', () async {
        // Arrange
        Future<int> task() async {
          throw Exception('任务失败');
        }

        // Act & Assert
        expect(
          () => PerformanceUtils.measurePerformance(label: '失败任务', task: task),
          throwsException,
        );
      });
    });

    group('防抖动', () {
      test('应该延迟执行函数', () async {
        // Arrange
        int counter = 0;
        void incrementCounter() {
          counter++;
        }

        final debouncedFunc = PerformanceUtils.debounce(
          incrementCounter,
          delay: const Duration(milliseconds: 100),
        );

        // Act
        debouncedFunc();
        debouncedFunc();

        // Assert
        expect(counter, 0);
        await Future.delayed(const Duration(milliseconds: 150));
        expect(counter, 1);
      });
    });

    group('节流', () {
      test('应该限制函数执行频率', () async {
        // Arrange
        int counter = 0;
        void incrementCounter() {
          counter++;
        }

        final throttledFunc = PerformanceUtils.throttle(
          incrementCounter,
          duration: const Duration(milliseconds: 100),
        );

        // Act
        throttledFunc();
        throttledFunc();

        // Assert
        expect(counter, 1);

        await Future.delayed(const Duration(milliseconds: 150));
        throttledFunc();
        expect(counter, 2);
      });
    });
  });
}
