import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/features/agent/data/agent_repository.dart';
import 'package:chat_app/features/agent/data/tool_executor.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';
import 'package:chat_app/core/storage/storage_service.dart';

@GenerateMocks([StorageService, ToolExecutorManager])
import 'agent_repository_test.mocks.dart';

void main() {
  late MockStorageService mockStorage;
  late MockToolExecutorManager mockExecutorManager;
  late AgentRepository repository;

  setUp(() {
    mockStorage = MockStorageService();
    mockExecutorManager = MockToolExecutorManager();
    repository = AgentRepository(mockStorage, mockExecutorManager);
  });

  group('AgentRepository', () {
    test('应该成功创建 Agent 配置', () async {
      when(mockStorage.saveSetting(any, any))
          .thenAnswer((_) async => {});

      final agent = await repository.createAgent(
        name: 'Test Agent',
        description: 'Test Description',
        toolIds: ['tool1', 'tool2'],
        systemPrompt: 'Test Prompt',
      );

      expect(agent.name, 'Test Agent');
      expect(agent.description, 'Test Description');
      expect(agent.toolIds, ['tool1', 'tool2']);
      expect(agent.systemPrompt, 'Test Prompt');
      verify(mockStorage.saveSetting(any, any)).called(1);
    });

    test('应该成功创建工具', () async {
      when(mockStorage.saveSetting(any, any))
          .thenAnswer((_) async => {});

      final tool = await repository.createTool(
        name: 'Test Tool',
        description: 'Test Tool Description',
        type: AgentToolType.calculator,
      );

      expect(tool.name, 'Test Tool');
      expect(tool.description, 'Test Tool Description');
      expect(tool.type, AgentToolType.calculator);
      verify(mockStorage.saveSetting(any, any)).called(1);
    });

    test('应该成功执行工具', () async {
      final tool = AgentTool(
        id: 'test-tool',
        name: 'Calculator',
        description: 'Test calculator',
        type: AgentToolType.calculator,
      );

      final result = ToolExecutionResult(
        success: true,
        result: '42',
      );

      when(mockExecutorManager.execute(any, any))
          .thenAnswer((_) async => result);

      final executionResult = await repository.executeTool(
        tool,
        {'expression': '21+21'},
      );

      expect(executionResult.success, true);
      expect(executionResult.result, '42');
    });

    test('应该成功删除 Agent', () async {
      when(mockStorage.deleteSetting(any))
          .thenAnswer((_) async => {});

      await repository.deleteAgent('test-agent-id');

      verify(mockStorage.deleteSetting('agent_test-agent-id')).called(1);
    });

    test('应该成功删除工具', () async {
      when(mockStorage.deleteSetting(any))
          .thenAnswer((_) async => {});

      await repository.deleteTool('test-tool-id');

      verify(mockStorage.deleteSetting('agent_tool_test-tool-id')).called(1);
    });
  });
}
