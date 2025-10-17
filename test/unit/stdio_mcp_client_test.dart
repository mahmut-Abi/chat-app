import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/mcp/data/stdio_mcp_client.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';

/// Bug #1: Stdio MCP Client 健康检查测试
void main() {
  group('Stdio MCP Client Tests', () {
    late McpConfig testConfig;

    setUp(() {
      testConfig = McpConfig(
        id: 'stdio-test-1',
        name: 'Test Stdio MCP',
        endpoint: '/usr/bin/node',
        args: ['server.js'],
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('should create stdio client with config', () {
      // Act
      final client = StdioMcpClient(config: testConfig);

      // Assert
      expect(client.config.id, 'stdio-test-1');
      expect(client.config.endpoint, '/usr/bin/node');
      expect(client.status, McpConnectionStatus.disconnected);
    });

    test('should initialize with disconnected status', () {
      // Act
      final client = StdioMcpClient(config: testConfig);

      // Assert
      expect(client.status, McpConnectionStatus.disconnected);
      expect(client.lastHealthCheck, isNull);
      expect(client.lastError, isNull);
    });

    test('should have correct command and args from config', () {
      // Act
      final client = StdioMcpClient(config: testConfig);

      // Assert
      expect(client.config.endpoint, '/usr/bin/node');
      expect(client.config.args, ['server.js']);
    });
  });

  group('Stdio Connection Status', () {
    test('should track connection status changes', () {
      // Arrange
      final config = McpConfig(
        id: 'test',
        name: 'Test',
        endpoint: '/usr/bin/node',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final client = StdioMcpClient(config: config);

      // Assert initial state
      expect(client.status, McpConnectionStatus.disconnected);

      // Manually set status for testing
      client.status = McpConnectionStatus.connecting;
      expect(client.status, McpConnectionStatus.connecting);

      client.status = McpConnectionStatus.connected;
      expect(client.status, McpConnectionStatus.connected);

      client.status = McpConnectionStatus.error;
      expect(client.status, McpConnectionStatus.error);
    });

    test('should track health check timestamp', () {
      // Arrange
      final config = McpConfig(
        id: 'test',
        name: 'Test',
        endpoint: '/usr/bin/node',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final client = StdioMcpClient(config: config);

      // Assert initial state
      expect(client.lastHealthCheck, isNull);

      // Set health check time
      final now = DateTime.now();
      client.lastHealthCheck = now;

      // Assert
      expect(client.lastHealthCheck, now);
    });

    test('should track last error', () {
      // Arrange
      final config = McpConfig(
        id: 'test',
        name: 'Test',
        endpoint: '/usr/bin/node',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final client = StdioMcpClient(config: config);

      // Assert initial state
      expect(client.lastError, isNull);

      // Set error
      client.lastError = 'Connection failed';

      // Assert
      expect(client.lastError, 'Connection failed');
    });
  });

  group('Stdio Configuration Validation', () {
    test('should accept valid command path', () {
      // Arrange
      final config = McpConfig(
        id: 'test',
        name: 'Test',
        endpoint: '/usr/bin/python3',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final client = StdioMcpClient(config: config);

      // Assert
      expect(client.config.endpoint, '/usr/bin/python3');
    });

    test('should accept command with arguments', () {
      // Arrange
      final config = McpConfig(
        id: 'test',
        name: 'Test',
        endpoint: '/usr/bin/node',
        args: ['script.js', '--port', '3000'],
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final client = StdioMcpClient(config: config);

      // Assert
      expect(client.config.endpoint, '/usr/bin/node');
      expect(client.config.args, ['script.js', '--port', '3000']);
    });

    test('should handle config without args', () {
      // Arrange
      final config = McpConfig(
        id: 'test',
        name: 'Test',
        endpoint: '/usr/bin/python3',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final client = StdioMcpClient(config: config);

      // Assert
      expect(client.config.args, isNull);
    });
  });
}
