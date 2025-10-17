import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/mcp/data/mcp_client_factory.dart';
import 'package:chat_app/features/mcp/data/http_mcp_client.dart';
import 'package:chat_app/features/mcp/data/stdio_mcp_client.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';

void main() {
  group('McpClientFactory', () {
    late DateTime testTime;

    setUp(() {
      testTime = DateTime(2025, 1, 17, 12, 0);
    });

    group('HTTP 客户端创建', () {
      test('应该创建 HTTP MCP 客户端', () {
        // Arrange
        final config = McpConfig(
          id: 'http_test',
          name: 'HTTP测试服务器',
          connectionType: McpConnectionType.http,
          endpoint: 'http://localhost:8080',
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<HttpMcpClient>());
      });

      test('应该使用配置创建 HTTP 客户端', () {
        // Arrange
        final config = McpConfig(
          id: 'http_config_test',
          name: 'HTTP配置测试',
          connectionType: McpConnectionType.http,
          endpoint: 'https://api.example.com/mcp',
          description: '测试服务器',
          enabled: true,
          headers: {'Authorization': 'Bearer token123'},
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<HttpMcpClient>());
        expect(client.config.endpoint, 'https://api.example.com/mcp');
        expect(client.config.name, 'HTTP配置测试');
      });

      test('应该支持带自定义 headers 的 HTTP 配置', () {
        // Arrange
        final headers = {
          'Authorization': 'Bearer secret',
          'X-API-Key': 'key123',
          'Content-Type': 'application/json',
        };
        final config = McpConfig(
          id: 'http_headers_test',
          name: 'Headers测试',
          connectionType: McpConnectionType.http,
          endpoint: 'http://localhost:3000',
          headers: headers,
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<HttpMcpClient>());
        expect(client.config.headers, equals(headers));
      });
    });

    group('Stdio 客户端创建', () {
      test('应该创建 Stdio MCP 客户端', () {
        // Arrange
        final config = McpConfig(
          id: 'stdio_test',
          name: 'Stdio测试服务器',
          connectionType: McpConnectionType.stdio,
          endpoint: '/usr/local/bin/mcp-server',
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<StdioMcpClient>());
      });

      test('应该使用配置创建 Stdio 客户端', () {
        // Arrange
        final config = McpConfig(
          id: 'stdio_config_test',
          name: 'Stdio配置测试',
          connectionType: McpConnectionType.stdio,
          endpoint: '/bin/custom-mcp',
          args: ['--verbose', '--port', '8080'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<StdioMcpClient>());
        expect(client.config.endpoint, '/bin/custom-mcp');
        expect(client.config.args, equals(['--verbose', '--port', '8080']));
      });

      test('应该支持带命令行参数的 Stdio 配置', () {
        // Arrange
        final args = ['--config', '/path/to/config.json', '--debug'];
        final config = McpConfig(
          id: 'stdio_args_test',
          name: 'Args测试',
          connectionType: McpConnectionType.stdio,
          endpoint: '/usr/bin/mcp',
          args: args,
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<StdioMcpClient>());
        expect(client.config.args, equals(args));
      });

      test('应该支持带环境变量的 Stdio 配置', () {
        // Arrange
        final env = {
          'PATH': '/custom/path',
          'MCP_CONFIG': '/config',
          'DEBUG': 'true',
        };
        final config = McpConfig(
          id: 'stdio_env_test',
          name: 'Env测试',
          connectionType: McpConnectionType.stdio,
          endpoint: '/usr/local/bin/mcp',
          env: env,
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<StdioMcpClient>());
        expect(client.config.env, equals(env));
      });
    });

    group('配置验证', () {
      test('应该正确处理完整的 HTTP 配置', () {
        // Arrange
        final config = McpConfig(
          id: 'full_http_config',
          name: '完整HTTP配置',
          connectionType: McpConnectionType.http,
          endpoint: 'https://api.example.com:8443/mcp',
          description: '生产环境服务器',
          enabled: true,
          headers: {'X-Custom-Header': 'value'},
          metadata: {'region': 'us-west', 'version': '1.0'},
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<HttpMcpClient>());
        expect(client.config.id, 'full_http_config');
        expect(client.config.name, '完整HTTP配置');
        expect(client.config.endpoint, 'https://api.example.com:8443/mcp');
        expect(client.config.description, '生产环境服务器');
        expect(client.config.enabled, isTrue);
        expect(client.config.metadata['region'], 'us-west');
      });

      test('应该正确处理完整的 Stdio 配置', () {
        // Arrange
        final config = McpConfig(
          id: 'full_stdio_config',
          name: '完整Stdio配置',
          connectionType: McpConnectionType.stdio,
          endpoint: '/usr/local/bin/mcp-server',
          args: ['--mode', 'production', '--log-level', 'info'],
          env: {'NODE_ENV': 'production', 'PORT': '3000'},
          description: '本地开发服务器',
          enabled: true,
          metadata: {'type': 'local', 'pid': '12345'},
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<StdioMcpClient>());
        expect(client.config.id, 'full_stdio_config');
        expect(client.config.name, '完整Stdio配置');
        expect(client.config.endpoint, '/usr/local/bin/mcp-server');
        expect(client.config.args?.length, 4);
        expect(client.config.env?.length, 2);
        expect(client.config.enabled, isTrue);
      });

      test('应该正确处理禁用的配置', () {
        // Arrange
        final config = McpConfig(
          id: 'disabled_config',
          name: '禁用配置',
          connectionType: McpConnectionType.http,
          endpoint: 'http://localhost:8080',
          enabled: false,
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<HttpMcpClient>());
        expect(client.config.enabled, isFalse);
      });
    });

    group('不同端点格式', () {
      test('应该支持 HTTP 端点', () {
        // Arrange
        final config = McpConfig(
          id: 'http_endpoint',
          name: 'HTTP端点',
          connectionType: McpConnectionType.http,
          endpoint: 'http://example.com',
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<HttpMcpClient>());
        expect(client.config.endpoint, 'http://example.com');
      });

      test('应该支持 HTTPS 端点', () {
        // Arrange
        final config = McpConfig(
          id: 'https_endpoint',
          name: 'HTTPS端点',
          connectionType: McpConnectionType.http,
          endpoint: 'https://secure.example.com',
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<HttpMcpClient>());
        expect(client.config.endpoint, 'https://secure.example.com');
      });

      test('应该支持带端口的端点', () {
        // Arrange
        final config = McpConfig(
          id: 'port_endpoint',
          name: '端口端点',
          connectionType: McpConnectionType.http,
          endpoint: 'http://localhost:3000',
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<HttpMcpClient>());
        expect(client.config.endpoint, contains(':3000'));
      });

      test('应该支持带路径的端点', () {
        // Arrange
        final config = McpConfig(
          id: 'path_endpoint',
          name: '路径端点',
          connectionType: McpConnectionType.http,
          endpoint: 'http://example.com/api/v1/mcp',
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<HttpMcpClient>());
        expect(client.config.endpoint, contains('/api/v1/mcp'));
      });

      test('应该支持绝对路径作为 Stdio 端点', () {
        // Arrange
        final config = McpConfig(
          id: 'abs_path_endpoint',
          name: '绝对路径端点',
          connectionType: McpConnectionType.stdio,
          endpoint: '/usr/local/bin/mcp-server',
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<StdioMcpClient>());
        expect(client.config.endpoint, startsWith('/'));
      });

      test('应该支持相对路径作为 Stdio 端点', () {
        // Arrange
        final config = McpConfig(
          id: 'rel_path_endpoint',
          name: '相对路径端点',
          connectionType: McpConnectionType.stdio,
          endpoint: './mcp-server',
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client, isA<StdioMcpClient>());
        expect(client.config.endpoint, startsWith('./'));
      });
    });

    group('元数据处理', () {
      test('应该保留配置元数据', () {
        // Arrange
        final metadata = {
          'environment': 'production',
          'region': 'us-east-1',
          'version': '2.0.0',
        };
        final config = McpConfig(
          id: 'metadata_test',
          name: '元数据测试',
          connectionType: McpConnectionType.http,
          endpoint: 'http://api.example.com',
          metadata: metadata,
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client.config.metadata, equals(metadata));
      });

      test('应该处理空元数据', () {
        // Arrange
        final config = McpConfig(
          id: 'empty_metadata',
          name: '空元数据',
          connectionType: McpConnectionType.http,
          endpoint: 'http://localhost',
          metadata: {},
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final client = McpClientFactory.createClient(config);

        // Assert
        expect(client.config.metadata, isEmpty);
      });
    });
  });
}
