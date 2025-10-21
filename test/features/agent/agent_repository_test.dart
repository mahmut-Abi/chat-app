import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chat_app/features/agent/data/agent_repository.dart';
import 'package:chat_app/features/agent/data/tool_executor.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';
import 'package:chat_app/core/storage/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}
class MockToolExecutorManager extends Mock implements ToolExecutorManager {}

void main() {
  group('AgentRepository Tests', () {
    late AgentRepository repository;
    late MockStorageService mockStorage;
    late MockToolExecutorManager mockExecutor;

    setUp(() {
      mockStorage = MockStorageService();
      mockExecutor = MockToolExecutorManager();
      repository = AgentRepository(mockStorage, mockExecutor);
    });

    test('创建 Agent 配置成功', () async {
      // Arrange
      const agentName = '测试 Agent';
      const toolIds = ['tool1', 'tool2'];

      when(mockStorage.saveSetting(any as String, any as String)).thenAnswer((_) async {});

      // Act
      final agent = await repository.createAgent(
        name: agentName,
        toolIds: toolIds,
      );

      // Assert
      expect(agent.name, equals(agentName));
      expect(agent.toolIds, equals(toolIds));
      expect(agent.id, isNotEmpty);
      verify(mockStorage.saveSetting(any as String, any as String)).called(1);
    });

    test('创建工具成功', () async {
      // Arrange
      const toolName = '计算器';
      const toolType = AgentToolType.calculator;

      when(mockStorage.saveSetting(any as String, any as String)).thenAnswer((_) async {});

      // Act
      final tool = await repository.createTool(
        name: toolName,
        type: toolType,
      );

      // Assert
      expect(tool.name, equals(toolName));
      expect(tool.type, equals(toolType));
      expect(tool.enabled, isTrue);
      verify(mockStorage.saveSetting(any as String, any as String)).called(1);
    });

    test('获取所有 Agent 配置', () async {
      // Arrange
      when(mockStorage.getAllKeys()).thenAnswer((_) async => [
        'agent_123',
        'agent_456',
        'agent_tool_789',
      ]);
      when(mockStorage.getSetting('agent_123')
      ).thenReturn('{"id":"123","name":"Agent1","toolIds":[],"createdAt":"2024-01-01T00:00:00.000Z","updatedAt":"2024-01-01T00:00:00.000Z"}');
      when(mockStorage.getSetting('agent_456')
      ).thenReturn('{"id":"456","name":"Agent2","toolIds":[],"createdAt":"2024-01-01T00:00:00.000Z","updatedAt":"2024-01-01T00:00:00.000Z"}');

      // Act
      final agents = await repository.getAllAgents();

      // Assert
      expect(agents, isNotEmpty);
      verify(mockStorage.getAllKeys()).called(1);
    });
  });
}
