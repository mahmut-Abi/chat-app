import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/features/mcp/data/mcp_integration.dart';
import 'package:chat_app/features/mcp/data/mcp_repository.dart';
import 'package:chat_app/features/mcp/data/mcp_client_base.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';
import 'package:chat_app/features/chat/domain/message.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';

@GenerateMocks([McpRepository, McpClientBase])
import 'mcp_integration_test.mocks.dart';

void main() {
  group('McpIntegration', () {
    late McpIntegration integration;
    late MockMcpRepository mockRepository;
    late MockMcpClientBase mockClient;
    late DateTime testTime;

    setUp(() {
      mockRepository = MockMcpRepository();
      mockClient = MockMcpClientBase();
      integration = McpIntegration(mockRepository);
      testTime = DateTime(2025, 1, 17, 12, 0);
    });

    group('会话上下文增强', () {
      test('应该成功为会话添加 MCP 上下文', () async {
        // Arrange
        final conversation = Conversation(messages: const [], 
          id: 'conv_1',
          title: '测试会话',
          createdAt: testTime,
          updatedAt: testTime,
        );

        final mcpContext = {
          'user_info': '测试用户',
          'session_id': 'session_123',
          'environment': 'test',
        };

        when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
        when(
          mockClient.getContext('conv_1'),
        ).thenAnswer((_) async => mcpContext);

        // Act
        final result = await integration.enrichConversationWithMcp(
          conversation,
          'mcp_1',
        );

        // Assert
        expect(result.systemPrompt, isNotNull);
        expect(result.systemPrompt, contains('MCP 上下文'));
        expect(result.systemPrompt, contains('user_info: 测试用户'));
        expect(result.systemPrompt, contains('session_id: session_123'));
        verify(mockRepository.getClient('mcp_1')).called(1);
        verify(mockClient.getContext('conv_1')).called(1);
      });

      test('应该在客户端未连接时抛出异常', () async {
        // Arrange
        final conversation = Conversation(messages: const [], 
          id: 'conv_1',
          title: '测试会话',
          createdAt: testTime,
          updatedAt: testTime,
        );

        when(mockRepository.getClient('mcp_1')).thenReturn(null);

        // Act & Assert
        expect(
          () => integration.enrichConversationWithMcp(conversation, 'mcp_1'),
          throwsException,
        );
      });

      test('应该在无上下文时返回原会话', () async {
        // Arrange
        final conversation = Conversation(messages: const [], 
          id: 'conv_1',
          title: '测试会话',
          createdAt: testTime,
          updatedAt: testTime,
        );

        when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
        when(mockClient.getContext('conv_1')).thenAnswer((_) async => null);

        // Act
        final result = await integration.enrichConversationWithMcp(
          conversation,
          'mcp_1',
        );

        // Assert
        expect(result.id, conversation.id);
        expect(result.title, conversation.title);
      });

      test('应该保留原有的 system prompt', () async {
        // Arrange
        final originalPrompt = '你是一个助手';
        final conversation = Conversation(messages: const [], 
          id: 'conv_1',
          title: '测试会话',
          systemPrompt: originalPrompt,
          createdAt: testTime,
          updatedAt: testTime,
        );

        final mcpContext = {'key': 'value'};

        when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
        when(
          mockClient.getContext('conv_1'),
        ).thenAnswer((_) async => mcpContext);

        // Act
        final result = await integration.enrichConversationWithMcp(
          conversation,
          'mcp_1',
        );

        // Assert
        expect(result.systemPrompt, contains(originalPrompt));
        expect(result.systemPrompt, contains('MCP 上下文'));
      });

      test('应该正确格式化 MCP 上下文', () async {
        // Arrange
        final conversation = Conversation(messages: const [], 
          id: 'conv_1',
          title: '测试会话',
          createdAt: testTime,
          updatedAt: testTime,
        );

        final mcpContext = {
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
        };

        when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
        when(
          mockClient.getContext('conv_1'),
        ).thenAnswer((_) async => mcpContext);

        // Act
        final result = await integration.enrichConversationWithMcp(
          conversation,
          'mcp_1',
        );

        // Assert
        expect(result.systemPrompt, contains('---'));
        expect(result.systemPrompt, contains('key1: value1'));
        expect(result.systemPrompt, contains('key2: value2'));
        expect(result.systemPrompt, contains('key3: value3'));
      });
    });

    group('消息同步', () {
      test('应该成功同步消息到 MCP', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '测试消息',
          role: MessageRole.user,
          timestamp: testTime,
        );

         when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
         when(mockClient.pushContext(any, any)).thenAnswer((_) async => true);
 
         // Act
         await integration.syncMessageToMcp(message, 'conv_1', 'mcp_1');

        // Assert
        verify(mockRepository.getClient('mcp_1')).called(1);
        verify(mockClient.pushContext('conv_1', any)).called(1);
      });

      test('应该在客户端未连接时静默失败', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '测试消息',
          role: MessageRole.user,
          timestamp: testTime,
        );

        when(mockRepository.getClient('mcp_1')).thenReturn(null);

        // Act & Assert - 不应该抛出异常
        await integration.syncMessageToMcp(message, 'conv_1', 'mcp_1');
        verifyNever(mockClient.pushContext(any, any));
      });

      test('应该在推送失败时静默失败', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '测试消息',
          role: MessageRole.user,
          timestamp: testTime,
        );

        when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
        when(mockClient.pushContext(any, any)).thenThrow(Exception('推送失败'));

        // Act & Assert - 不应该抛出异常
        await integration.syncMessageToMcp(message, 'conv_1', 'mcp_1');
      });

      test('应该正确传递消息数据', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '测试内容',
          role: MessageRole.assistant,
          timestamp: testTime,
        );

        when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
        when(mockClient.pushContext(any, any)).thenAnswer((_) async => true);

        // Act
        await integration.syncMessageToMcp(message, 'conv_1', 'mcp_1');

        // Assert
        final captured = verify(
          mockClient.pushContext('conv_1', captureAny),
        ).captured;

        expect(captured.length, 1);
        final data = captured[0] as Map<String, dynamic>;
        expect(data['type'], 'message');
        expect(data['content'], '测试内容');
        expect(data['role'], contains('assistant'));
      });

      test('应该包含时间戳信息', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '测试',
          role: MessageRole.user,
          timestamp: testTime,
        );

        when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
        when(mockClient.pushContext(any, any)).thenAnswer((_) async => true);

        // Act
        await integration.syncMessageToMcp(message, 'conv_1', 'mcp_1');

        // Assert
        final captured = verify(
          mockClient.pushContext(any, captureAny),
        ).captured;

        final data = captured[0] as Map<String, dynamic>;
        expect(data['timestamp'], isNotNull);
        expect(data['timestamp'], contains('2025'));
      });
    });

    group('配置管理', () {
      test('应该获取所有已启用的 MCP 配置', () async {
        // Arrange
        final configs = [
          McpConfig(
            id: 'mcp_1',
            name: '配置1',
            endpoint: 'http://localhost:8080',
            enabled: true,
            createdAt: testTime,
            updatedAt: testTime,
          ),
          McpConfig(
            id: 'mcp_2',
            name: '配置2',
            endpoint: 'http://localhost:8081',
            enabled: false,
            createdAt: testTime,
            updatedAt: testTime,
          ),
          McpConfig(
            id: 'mcp_3',
            name: '配置3',
            endpoint: 'http://localhost:8082',
            enabled: true,
            createdAt: testTime,
            updatedAt: testTime,
          ),
        ];

        when(mockRepository.getAllConfigs()).thenAnswer((_) async => configs);

        // Act
        final result = await integration.getAvailableMcpConfigs();

        // Assert
        expect(result.length, 2);
        expect(result.every((c) => c.enabled), isTrue);
        expect(result.map((c) => c.id), containsAll(['mcp_1', 'mcp_3']));
      });

      test('应该在没有启用配置时返回空列表', () async {
        // Arrange
        final configs = [
          McpConfig(
            id: 'mcp_1',
            name: '配置1',
            endpoint: 'http://localhost:8080',
            enabled: false,
            createdAt: testTime,
            updatedAt: testTime,
          ),
        ];

        when(mockRepository.getAllConfigs()).thenAnswer((_) async => configs);

        // Act
        final result = await integration.getAvailableMcpConfigs();

        // Assert
        expect(result, isEmpty);
      });

      test('应该处理空配置列表', () async {
        // Arrange
        when(mockRepository.getAllConfigs()).thenAnswer((_) async => []);

        // Act
        final result = await integration.getAvailableMcpConfigs();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('连接状态检查', () {
      test('应该正确返回连接状态', () {
        // Arrange
        when(
          mockRepository.getConnectionStatus('mcp_1'),
        ).thenReturn(McpConnectionStatus.connected);

        // Act
        final status = integration.checkConnectionStatus('mcp_1');

        // Assert
        expect(status, McpConnectionStatus.connected);
        verify(mockRepository.getConnectionStatus('mcp_1')).called(1);
      });

      test('应该处理未找到的配置', () {
        // Arrange
        when(
          mockRepository.getConnectionStatus('nonexistent'),
        ).thenReturn(null);

        // Act
        final status = integration.checkConnectionStatus('nonexistent');

        // Assert
        expect(status, isNull);
      });

      test('应该区分不同的连接状态', () {
        // Arrange
        when(
          mockRepository.getConnectionStatus('mcp_1'),
        ).thenReturn(McpConnectionStatus.connected);
        when(
          mockRepository.getConnectionStatus('mcp_2'),
        ).thenReturn(McpConnectionStatus.disconnected);
        when(
          mockRepository.getConnectionStatus('mcp_3'),
        ).thenReturn(McpConnectionStatus.connecting);

        // Act
        final status1 = integration.checkConnectionStatus('mcp_1');
        final status2 = integration.checkConnectionStatus('mcp_2');
        final status3 = integration.checkConnectionStatus('mcp_3');

        // Assert
        expect(status1, McpConnectionStatus.connected);
        expect(status2, McpConnectionStatus.disconnected);
        expect(status3, McpConnectionStatus.connecting);
      });
    });

    group('边界情况', () {
      test('应该处理空的 MCP 上下文', () async {
        // Arrange
        final conversation = Conversation(messages: const [], 
          id: 'conv_1',
          title: '测试会话',
          createdAt: testTime,
          updatedAt: testTime,
        );

        when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
        when(mockClient.getContext('conv_1')).thenAnswer((_) async => {});

        // Act
        final result = await integration.enrichConversationWithMcp(
          conversation,
          'mcp_1',
        );

        // Assert
        expect(result.systemPrompt, contains('MCP 上下文'));
      });

      test('应该处理包含特殊字符的上下文', () async {
        // Arrange
        final conversation = Conversation(messages: const [], 
          id: 'conv_1',
          title: '测试会话',
          createdAt: testTime,
          updatedAt: testTime,
        );

        final mcpContext = {
          'special': '特殊字符: @#\$%^&*()',
          'emoji': '😀🎉',
          'newline': 'line1\nline2',
        };

        when(mockRepository.getClient('mcp_1')).thenReturn(mockClient);
        when(
          mockClient.getContext('conv_1'),
        ).thenAnswer((_) async => mcpContext);

        // Act
        final result = await integration.enrichConversationWithMcp(
          conversation,
          'mcp_1',
        );

        // Assert
        expect(result.systemPrompt, contains('@#\$%^&*()'));
        expect(result.systemPrompt, isNotEmpty);
      });
    });
  });
}
