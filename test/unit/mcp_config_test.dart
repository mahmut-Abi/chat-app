import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';

void main() {
  group('McpConfig', () {
    test('should create McpConfig with default values', () {
      final config = McpConfig(
        id: 'test-id',
        name: 'Test MCP',
        endpoint: 'http://localhost:3000',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(config.id, 'test-id');
      expect(config.name, 'Test MCP');
      expect(config.endpoint, 'http://localhost:3000');
      expect(config.enabled, true);
      expect(config.description, null);
    });

    test('should create McpConfig with custom values', () {
      final config = McpConfig(
        id: 'test-id',
        name: 'Test MCP',
        endpoint: 'http://localhost:3000',
        description: 'Test description',
        enabled: false,
        headers: {'Authorization': 'Bearer token'},
        metadata: {'key': 'value'},
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(config.enabled, false);
      expect(config.description, 'Test description');
      expect(config.headers, {'Authorization': 'Bearer token'});
      expect(config.metadata, {'key': 'value'});
    });

    test('should create copy with updated values', () {
      final original = McpConfig(
        id: 'test-id',
        name: 'Original',
        endpoint: 'http://localhost:3000',
        enabled: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(name: 'Updated', enabled: false);

      expect(updated.id, original.id);
      expect(updated.name, 'Updated');
      expect(updated.endpoint, original.endpoint);
      expect(updated.enabled, false);
    });

    test('should convert to and from JSON', () {
      final config = McpConfig(
        id: 'test-id',
        name: 'Test MCP',
        endpoint: 'http://localhost:3000',
        description: 'Test',
        enabled: true,
        headers: {'key': 'value'},
        metadata: {'meta': 'data'},
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = config.toJson();
      final restored = McpConfig.fromJson(json);

      expect(restored.id, config.id);
      expect(restored.name, config.name);
      expect(restored.endpoint, config.endpoint);
      expect(restored.enabled, config.enabled);
      expect(restored.description, config.description);
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
  });

  group('McpConnectionStatus', () {
    test('should have correct enum values', () {
      expect(McpConnectionStatus.disconnected, isA<McpConnectionStatus>());
      expect(McpConnectionStatus.connecting, isA<McpConnectionStatus>());
      expect(McpConnectionStatus.connected, isA<McpConnectionStatus>());
      expect(McpConnectionStatus.error, isA<McpConnectionStatus>());
    });
  });
}
