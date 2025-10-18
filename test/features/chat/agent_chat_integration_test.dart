import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/data/agent_chat_integration.dart';
import 'package:chat_app/features/chat/data/chat_repository.dart';
import 'package:chat_app/features/agent/data/agent_chat_service.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';
import 'package:chat_app/features/chat/domain/message.dart';
import 'package:mockito/mockito.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockAgentChatService extends Mock implements AgentChatService {}

void main() {
  group('AgentChatIntegration Tests', () {
    late AgentChatIntegration integration;
    late MockChatRepository mockChatRepository;
    late MockAgentChatService mockAgentChatService;

    setUp(() {
      mockChatRepository = MockChatRepository();
      mockAgentChatService = MockAgentChatService();
      integration = AgentChatIntegration(
        mockChatRepository,
        mockAgentChatService,
      );
    });

    test('使用 Agent 发送消息成功', () async {
      // Arrange
      final agent = AgentConfig(
        id: 'agent-1',
        name: '测试Agent',
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

      final mockMessage = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: '测试响应',
        timestamp: DateTime.now(),
      );

      when(mockChatRepository.getConversation('conv-1')).thenReturn(
        Conversation(
          id: 'conv-1',
          title: '测试对话',
          messages: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      when(mockAgentChatService.sendMessageWithAgent(
        conversationId: 'conv-1',
        content: '你好',
        config: config,
        agent: agent,
        conversationHistory: [],
      )).thenAnswer((_) async => mockMessage);

      // Act
      final result = await integration.sendMessageWithAgent(
        conversationId: 'conv-1',
        content: '你好',
        config: config,
        agent: agent,
      );

      // Assert
      expect(result.id, equals('msg-1'));
      expect(result.content, equals('测试响应'));
      verify(mockChatRepository.getConversation('conv-1')).called(1);
    });

    test('保存对话和消息成功', () async {
      // Arrange
      final conversation = Conversation(
        id: 'conv-1',
        title: '测试对话',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userMessage = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: '你好',
        timestamp: DateTime.now(),
      );

      final assistantMessage = Message(
        id: 'msg-2',
        role: MessageRole.assistant,
        content: '你好',
        timestamp: DateTime.now(),
      );

      when(mockChatRepository.saveConversation(any)).thenAnswer((_) async {});

      // Act
      await integration.saveConversationWithMessage(
        conversation,
        userMessage,
        assistantMessage,
      );

      // Assert
      verify(mockChatRepository.saveConversation(any)).called(1);
    });
  });
}
