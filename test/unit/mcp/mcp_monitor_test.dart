import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/mcp/data/mcp_monitor.dart';
import 'package:chat_app/features/mcp/data/mcp_health_check_strategy.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';

void main() {
  group('McpMonitor Tests', () {
    late McpConfig config;
    late McpMonitor monitor;

    setUp(() {
      config = McpConfig(
        id: 'test-1',
        name: 'Test MCP',
        endpoint: 'http://localhost:8000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      monitor = McpMonitor(
        config: config,
        strategy: HealthCheckStrategy.networkOnly,
        healthCheckInterval: const Duration(seconds: 5),
        maxRetries: 2,
        retryDelay: const Duration(milliseconds: 100),
      );
    });

    tearDown(() {
      monitor.dispose();
    });

    test('Monitor should initialize with correct config', () {
      expect(monitor.config.id, 'test-1');
      expect(monitor.strategy, HealthCheckStrategy.networkOnly);
      expect(monitor.maxRetries, 2);
    });

    test('Monitor should track health check history', () async {
      final result = await monitor.performHealthCheck();
      
      final history = monitor.getHealthCheckHistory();
      expect(history.length, greaterThan(0));
      expect(history.last.strategy, HealthCheckStrategy.networkOnly);
    });

    test('Monitor should calculate success rate correctly', () async {
      await monitor.performHealthCheck();
      await monitor.performHealthCheck();
      
      final rate = monitor.getSuccessRate();
      expect(rate, greaterThanOrEqualTo(0.0));
      expect(rate, lessThanOrEqualTo(1.0));
    });

    test('Monitor should get latest health check result', () async {
      await monitor.performHealthCheck();
      
      final latest = monitor.getLatestHealthCheck();
      expect(latest, isNotNull);
      expect(latest!.timestamp, isNotNull);
    });

    test('Monitor should switch strategies', () async {
      expect(monitor.strategy, HealthCheckStrategy.networkOnly);
      
      await monitor.switchStrategy(HealthCheckStrategy.probe);
      expect(monitor.strategy, HealthCheckStrategy.probe);
    });

    test('Monitor should emit events', (WidgetTester tester) async {
      final events = <McpMonitorEvent>[];
      
      monitor.events.listen((event) {
        events.add(event);
      });

      await monitor.start();
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(events, isNotEmpty);
      await monitor.stop();
    });

    test('Monitor should keep history limited to 100', () async {
      for (int i = 0; i < 150; i++) {
        await monitor.performHealthCheck();
      }
      
      final history = monitor.getHealthCheckHistory();
      expect(history.length, lessThanOrEqualTo(100));
    });
  });
}
