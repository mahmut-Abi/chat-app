import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/features/agent/data/agent_integration.dart';
import 'package:chat_app/features/agent/data/agent_repository.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';
import 'package:chat_app/features/chat/domain/message.dart';

@GenerateMocks([AgentRepository])
import 'agent_integration_test.mocks.dart';

void main() {
  group('AgentIntegration', () {
    late AgentIntegration integration;
    late MockAgentRepository mockRepository;
    late DateTime testTime;

    setUp(() {
      mockRepository = MockAgentRepository();
      integration = AgentIntegration(mockRepository);
      testTime = DateTime(2025, 1, 17, 12, 0);
    });

    group('工具调用提取', () {
      test('应该识别计算器工具调用', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '@calculator 1+1',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['calculator_tool'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        final calculatorTool = AgentTool(
          id: 'calculator_tool',
          name: 'calculator',
          description: '计算器',
          type: AgentToolType.calculator,
        );

        when(
          mockRepository.getAllTools(),
        ).thenAnswer((_) async => [calculatorTool]);

        when(mockRepository.executeTool(any, any)).thenAnswer(
          (_) async => ToolExecutionResult(success: true, result: '2'),
        );

        // Act
        final result = await integration.processMessageWithAgent(
          message,
          agent,
        );

        // Assert
        expect(result.content, contains('工具执行结果'));
        expect(result.content, contains('执行成功'));
        verify(mockRepository.getAllTools()).called(1);
        verify(mockRepository.executeTool(any, any)).called(1);
      });

      test('应该在没有工具调用时返回原消息', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '普通消息内容',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: [],
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final result = await integration.processMessageWithAgent(
          message,
          agent,
        );

        // Assert
        expect(result.id, message.id);
        expect(result.content, message.content);
        verifyNever(mockRepository.getAllTools());
        verifyNever(mockRepository.executeTool(any, any));
      });
    });

    group('工具执行', () {
      test('应该成功执行工具并返回结果', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '@calculator 5+3',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['calculator_tool'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        final calculatorTool = AgentTool(
          id: 'calculator_tool',
          name: 'calculator',
          description: '计算器',
          type: AgentToolType.calculator,
        );

        when(
          mockRepository.getAllTools(),
        ).thenAnswer((_) async => [calculatorTool]);

        when(mockRepository.executeTool(any, any)).thenAnswer(
          (_) async => ToolExecutionResult(
            success: true,
            result: '8',
            metadata: {'expression': '5+3'},
          ),
        );

        // Act
        final result = await integration.processMessageWithAgent(
          message,
          agent,
        );

        // Assert
        expect(result.content, contains('8'));
        expect(result.content, contains('✅'));
        expect(result.content, contains('执行成功'));
      });

      test('应该处理工具执行失败', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '@calculator invalid',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['calculator_tool'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        final calculatorTool = AgentTool(
          id: 'calculator_tool',
          name: 'calculator',
          description: '计算器',
          type: AgentToolType.calculator,
        );

        when(
          mockRepository.getAllTools(),
        ).thenAnswer((_) async => [calculatorTool]);

        when(mockRepository.executeTool(any, any)).thenAnswer(
          (_) async => ToolExecutionResult(success: false, error: '无效的表达式'),
        );

        // Act
        final result = await integration.processMessageWithAgent(
          message,
          agent,
        );

        // Assert
        expect(result.content, contains('❌'));
        expect(result.content, contains('执行失败'));
        expect(result.content, contains('无效的表达式'));
      });

      test('应该正确传递工具参数', () async {
        // Arrange
        final expression = '10 * 5';
        final message = Message(
          id: 'msg_1',
          content: '@calculator $expression',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['calculator_tool'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        final calculatorTool = AgentTool(
          id: 'calculator_tool',
          name: 'calculator',
          description: '计算器',
          type: AgentToolType.calculator,
        );

        when(
          mockRepository.getAllTools(),
        ).thenAnswer((_) async => [calculatorTool]);

        when(mockRepository.executeTool(any, any)).thenAnswer(
          (_) async => ToolExecutionResult(success: true, result: '50'),
        );

        // Act
        await integration.processMessageWithAgent(message, agent);

        // Assert
        final captured = verify(
          mockRepository.executeTool(any, captureAny),
        ).captured;

        expect(captured.length, 1);
        final input = captured[0] as Map<String, dynamic>;
        expect(input['expression'], expression);
      });
    });

    group('工具过滤', () {
      test('应该只使用 Agent 配置的工具', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '@calculator 1+1',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['calculator_tool'], // 只配置了计算器
          createdAt: testTime,
          updatedAt: testTime,
        );

        final allTools = [
          AgentTool(
            id: 'calculator_tool',
            name: 'calculator',
            description: '计算器',
            type: AgentToolType.calculator,
          ),
          AgentTool(
            id: 'search_tool',
            name: 'search',
            description: '搜索',
            type: AgentToolType.search,
          ),
          AgentTool(
            id: 'file_tool',
            name: 'file',
            description: '文件操作',
            type: AgentToolType.fileOperation,
          ),
        ];

        when(mockRepository.getAllTools()).thenAnswer((_) async => allTools);

        when(mockRepository.executeTool(any, any)).thenAnswer(
          (_) async => ToolExecutionResult(success: true, result: '2'),
        );

        // Act
        await integration.processMessageWithAgent(message, agent);

        // Assert
        final captured = verify(
          mockRepository.executeTool(captureAny, any),
        ).captured;

        expect(captured.length, 1);
        final tool = captured[0] as AgentTool;
        expect(tool.id, 'calculator_tool');
      });

      test('应该处理 Agent 配置了多个工具的情况', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '@calculator 1+1',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['calculator_tool', 'search_tool', 'file_tool'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        final allTools = [
          AgentTool(
            id: 'calculator_tool',
            name: 'calculator',
            description: '计算器',
            type: AgentToolType.calculator,
          ),
          AgentTool(
            id: 'search_tool',
            name: 'search',
            description: '搜索',
            type: AgentToolType.search,
          ),
        ];

        when(mockRepository.getAllTools()).thenAnswer((_) async => allTools);

        when(mockRepository.executeTool(any, any)).thenAnswer(
          (_) async => ToolExecutionResult(success: true, result: '2'),
        );

        // Act
        await integration.processMessageWithAgent(message, agent);

        // Assert
        verify(mockRepository.getAllTools()).called(1);
      });
    });

    group('消息内容构建', () {
      test('应该保留原始消息内容', () async {
        // Arrange
        final originalContent = '请帮我计算 @calculator 2+2';
        final message = Message(
          id: 'msg_1',
          content: originalContent,
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['calculator_tool'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        final calculatorTool = AgentTool(
          id: 'calculator_tool',
          name: 'calculator',
          description: '计算器',
          type: AgentToolType.calculator,
        );

        when(
          mockRepository.getAllTools(),
        ).thenAnswer((_) async => [calculatorTool]);

        when(mockRepository.executeTool(any, any)).thenAnswer(
          (_) async => ToolExecutionResult(success: true, result: '4'),
        );

        // Act
        final result = await integration.processMessageWithAgent(
          message,
          agent,
        );

        // Assert
        expect(result.content, contains(originalContent));
        expect(result.content, contains('工具执行结果'));
      });

      test('应该格式化工具执行结果', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '@calculator 10+20',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['calculator_tool'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        final calculatorTool = AgentTool(
          id: 'calculator_tool',
          name: 'calculator',
          description: '计算器',
          type: AgentToolType.calculator,
        );

        when(
          mockRepository.getAllTools(),
        ).thenAnswer((_) async => [calculatorTool]);

        when(mockRepository.executeTool(any, any)).thenAnswer(
          (_) async => ToolExecutionResult(success: true, result: '30'),
        );

        // Act
        final result = await integration.processMessageWithAgent(
          message,
          agent,
        );

        // Assert
        expect(result.content, contains('---'));
        expect(result.content, contains('1.'));
        expect(result.content, contains('✅'));
        expect(result.content, contains('30'));
      });

      test('应该使用代码块格式化结果', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '@calculator 100/5',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['calculator_tool'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        final calculatorTool = AgentTool(
          id: 'calculator_tool',
          name: 'calculator',
          description: '计算器',
          type: AgentToolType.calculator,
        );

        when(
          mockRepository.getAllTools(),
        ).thenAnswer((_) async => [calculatorTool]);

        when(mockRepository.executeTool(any, any)).thenAnswer(
          (_) async => ToolExecutionResult(success: true, result: '20'),
        );

        // Act
        final result = await integration.processMessageWithAgent(
          message,
          agent,
        );

        // Assert
        expect(result.content, contains('```'));
        expect(result.content, contains('20'));
      });
    });

    group('边界情况', () {
      test('应该处理空工具列表', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '@calculator 1+1',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: [],
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final result = await integration.processMessageWithAgent(
          message,
          agent,
        );

        // Assert
        expect(result.id, message.id);
        expect(result.content, message.content);
      });

      test('应该处理工具未找到的情况', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '@calculator 1+1',
          role: MessageRole.user,
          timestamp: testTime,
        );

        final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: ['nonexistent_tool'],
          createdAt: testTime,
          updatedAt: testTime,
        );

        when(mockRepository.getAllTools()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => integration.processMessageWithAgent(message, agent),
          throwsException,
        );
      });

      test('应该保持消息的其他属性不变', () async {
        // Arrange
        final message = Message(
          id: 'msg_1',
          content: '普通消息',
           role: MessageRole.user,
           timestamp: testTime,
         );
 
         final agent = AgentConfig(
          id: 'agent_1',
          name: '测试Agent',
          toolIds: [],
          createdAt: testTime,
          updatedAt: testTime,
        );

        // Act
        final result = await integration.processMessageWithAgent(
          message,
          agent,
        );

        // Assert
        expect(result.id, message.id);
        expect(result.role, message.role);
         expect(result.timestamp, message.timestamp);
       });
     });
   });
}
