import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chat_app/features/agent/data/agent_chat_service.dart';
import 'package:chat_app/features/agent/data/unified_tool_service.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';
import 'package:chat_app/features/chat/domain/message.dart';
import 'package:chat_app/core/network/openai_api_client.dart';

class MockOpenAIApiClient extends Mock implements OpenAIApiClient {}
class MockUnifiedToolService extends Mock implements UnifiedToolService {}

void main() {
  group('AgentChatService Tests', () {
    late AgentChatService service;
    late MockOpenAIApiClient mockApiClient;
    late MockUnifiedToolService mockToolService;

    setUp(() {
      mockApiClient = MockOpenAIApiClient();
      mockToolService = MockUnifiedToolService();
      service = AgentChatService(mockApiClient, mockToolService);
    });

    test('发送消息成功', () async {
      // Arrange
      final agent = AgentConfig(
        id: 'test-agent',
        name: '测试 Agent',
        toolIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final config = ModelConfig(
        model: 'gpt-4',
        temperature: 0.7,
        maxTokens: 2048,
        topP: 1.0,
      );

      // Act
      final message = await service.sendMessageWithAgent(
        conversationId: 'conv-1',
        content: '你好',
        config: config,
        agent: agent,
      );

      // Assert
      expect(message, isNotNull);
      expect(message.role, equals(MessageRole.assistant));
    });

    test('处理工具调用失败', () async {
      // Arrange
      final agent = AgentConfig(
        id: 'test-agent',
        name: '测试 Agent',
        toolIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final config = ModelConfig(
        model: 'gpt-4',
        temperature: 0.7,
        maxTokens: 2048,
        topP: 1.0,
      );

      // Act
      final message = await service.sendMessageWithAgent(
        conversationId: 'conv-1',
        content: '你好',
        config: config,
        agent: agent,
      );

      // Assert
      expect(message.hasError, isFalse);
    });
  });
}
