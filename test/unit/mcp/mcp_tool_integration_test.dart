import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/features/mcp/data/mcp_tool_integration.dart';
import 'package:chat_app/features/mcp/data/mcp_repository.dart';
import 'package:chat_app/features/mcp/data/mcp_client_base.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

import 'mcp_tool_integration_test.mocks.dart';

@GenerateMocks([McpRepository, McpClientBase])
void main() {
  late MockMcpRepository mockRepository;
  late MockMcpClientBase mockClient;
  late McpToolIntegration integration;

  setUp(() {
    mockRepository = MockMcpRepository();
    mockClient = MockMcpClientBase();
    integration = McpToolIntegration(mockRepository);
  });

  group('MCP Tool Integration Tests', () {
    test('should get MCP tool definitions', () async {
      // Arrange
      final mcpConfigId = 'test-mcp-1';
      final mcpTools = [
        {
          'name': 'weather',
          'description': '获取天气信息',
          'parameters': {
            'type': 'object',
            'properties': {
              'location': {'type': 'string'},
            },
          },
        },
        {
          'name': 'translate',
          'description': '翻译文本',
          'parameters': {
            'type': 'object',
            'properties': {
              'text': {'type': 'string'},
              'targetLang': {'type': 'string'},
            },
          },
        },
      ];

      when(mockRepository.getClient(mcpConfigId)).thenReturn(mockClient);
      when(mockClient.listTools()).thenAnswer((_) async => mcpTools);

      // Act
      final definitions = await integration.getMcpToolDefinitions(mcpConfigId);

      // Assert
      expect(definitions.length, equals(2));
      expect(definitions[0].function.name, equals('weather'));
      expect(definitions[0].function.description, equals('获取天气信息'));
      expect(definitions[1].function.name, equals('translate'));
    });

    test('should return empty list when client not connected', () async {
      // Arrange
      final mcpConfigId = 'test-mcp-1';
      when(mockRepository.getClient(mcpConfigId)).thenReturn(null);

      // Act
      final definitions = await integration.getMcpToolDefinitions(mcpConfigId);

      // Assert
      expect(definitions, isEmpty);
    });

    test('should execute MCP tool successfully', () async {
      // Arrange
      final mcpConfigId = 'test-mcp-1';
      final toolName = 'weather';
      final parameters = {'location': 'Beijing'};
      final mockResult = {
        'content': 'Beijing: Sunny, 25°C',
        'temperature': 25,
        'condition': 'sunny',
      };

      when(mockRepository.getClient(mcpConfigId)).thenReturn(mockClient);
      when(mockClient.callTool(toolName, parameters))
          .thenAnswer((_) async => mockResult);

      // Act
      final result = await integration.executeMcpTool(
        mcpConfigId,
        toolName,
        parameters,
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.result, contains('Beijing'));
      expect(result.metadata, equals(mockResult));
    });

    test('should handle MCP tool execution failure', () async {
      // Arrange
      final mcpConfigId = 'test-mcp-1';
      final toolName = 'weather';
      final parameters = {'location': 'Invalid'};

      when(mockRepository.getClient(mcpConfigId)).thenReturn(mockClient);
      when(mockClient.callTool(toolName, parameters))
          .thenThrow(Exception('API 错误'));

      // Act
      final result = await integration.executeMcpTool(
        mcpConfigId,
        toolName,
        parameters,
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.error, contains('执行失败'));
    });

    test('should get all MCP tool definitions from multiple configs', () async {
      // Arrange
      final config1 = McpConfig(
        id: 'mcp-1',
        name: 'MCP Server 1',
        endpoint: 'http://localhost:3000',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final config2 = McpConfig(
        id: 'mcp-2',
        name: 'MCP Server 2',
        endpoint: 'http://localhost:3001',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tools1 = [
        {'name': 'tool1', 'description': 'Tool 1', 'parameters': {}},
      ];

      final tools2 = [
        {'name': 'tool2', 'description': 'Tool 2', 'parameters': {}},
      ];

      when(mockRepository.getAllConfigs())
          .thenAnswer((_) async => [config1, config2]);
      when(mockRepository.getClient('mcp-1')).thenReturn(mockClient);
      when(mockRepository.getClient('mcp-2')).thenReturn(mockClient);
      when(mockClient.listTools())
          .thenAnswer((_) async => tools1)
          .thenAnswer((_) async => tools2);

      // Act
      final definitions = await integration.getAllMcpToolDefinitions();

      // Assert
      expect(definitions.length, greaterThanOrEqualTo(1));
    });

    test('should find MCP config for specific tool', () async {
      // Arrange
      final config = McpConfig(
        id: 'mcp-1',
        name: 'MCP Server',
        endpoint: 'http://localhost:3000',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tools = [
        {'name': 'weather', 'description': '天气工具', 'parameters': {}},
      ];

      when(mockRepository.getAllConfigs()).thenAnswer((_) async => [config]);
      when(mockRepository.getClient('mcp-1')).thenReturn(mockClient);
      when(mockClient.listTools()).thenAnswer((_) async => tools);

      // Act
      final foundConfigId = await integration.findMcpConfigForTool('weather');

      // Assert
      expect(foundConfigId, equals('mcp-1'));
    });

    test('should return null when tool not found in any MCP server', () async {
      // Arrange
      final config = McpConfig(
        id: 'mcp-1',
        name: 'MCP Server',
        endpoint: 'http://localhost:3000',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tools = [
        {'name': 'weather', 'description': '天气工具', 'parameters': {}},
      ];

      when(mockRepository.getAllConfigs()).thenAnswer((_) async => [config]);
      when(mockRepository.getClient('mcp-1')).thenReturn(mockClient);
      when(mockClient.listTools()).thenAnswer((_) async => tools);

      // Act
      final foundConfigId =
          await integration.findMcpConfigForTool('nonexistent');

      // Assert
      expect(foundConfigId, isNull);
    });

    test('should filter disabled MCP configs', () async {
      // Arrange
      final config1 = McpConfig(
        id: 'mcp-1',
        name: 'Enabled Server',
        endpoint: 'http://localhost:3000',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final config2 = McpConfig(
        id: 'mcp-2',
        name: 'Disabled Server',
        endpoint: 'http://localhost:3001',
        enabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.getAllConfigs())
          .thenAnswer((_) async => [config1, config2]);

      // Act
      final enabledConfigs = await integration.getEnabledMcpConfigs();

      // Assert
      expect(enabledConfigs.length, equals(1));
      expect(enabledConfigs.first.id, equals('mcp-1'));
    });
  });
}
