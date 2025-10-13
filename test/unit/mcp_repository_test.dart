import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';

void main() {
  group('McpConfig Unit Tests', () {
    test('should create MCP config with enabled status', () {
      final config = McpConfig(
        id: 'test-id',
        name: 'Test MCP',
        endpoint: 'http://localhost:3000',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(config.name, 'Test MCP');
      expect(config.enabled, true);
    });

    test('should toggle enabled status', () {
      final config = McpConfig(
        id: 'test-id',
        name: 'Test',
        endpoint: 'http://localhost:3000',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final disabled = config.copyWith(enabled: false);
      expect(disabled.enabled, false);

      final enabled = disabled.copyWith(enabled: true);
      expect(enabled.enabled, true);
    });

    test('should maintain other properties when toggling', () {
      final original = McpConfig(
        id: 'test-id',
        name: 'Test MCP',
        endpoint: 'http://localhost:3000',
        description: 'Test',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final toggled = original.copyWith(enabled: false);

      expect(toggled.id, original.id);
      expect(toggled.name, original.name);
      expect(toggled.endpoint, original.endpoint);
      expect(toggled.description, original.description);
      expect(toggled.enabled, false);
    });
  });

  group('McpConnectionStatus Tests', () {
    test('should have all connection status values', () {
      expect(McpConnectionStatus.disconnected, isNotNull);
      expect(McpConnectionStatus.connecting, isNotNull);
      expect(McpConnectionStatus.connected, isNotNull);
      expect(McpConnectionStatus.error, isNotNull);
    });
  });
}
