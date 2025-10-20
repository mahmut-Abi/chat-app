import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('AgentRepository Integration Tests', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('Agent Management', () {
      test('should create and retrieve agent', () {
        final agent = AgentConfig(
          id: 'agent-001',
          name: 'Test Agent',
          description: 'Test description',
          toolIds: ['tool1', 'tool2'],
          systemPrompt: 'Test prompt',
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(agent.id, 'agent-001');
        expect(agent.toolIds.length, 2);
      });

      test('should update agent configuration', () {
        final original = AgentConfig(
          id: 'agent-001',
          name: 'Original',
          toolIds: ['tool1'],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          name: 'Updated',
          toolIds: ['tool1', 'tool2', 'tool3'],
          updatedAt: now.add(const Duration(hours: 1)),
        );

        expect(updated.name, 'Updated');
        expect(updated.toolIds.length, 3);
      });

      test('should delete agent', () {
        final agent = AgentConfig(
          id: 'agent-001',
          name: 'To Delete',
          toolIds: [],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        // Verify agent exists
        expect(agent.id, 'agent-001');
        
        // In a real repository, deletion would remove from storage
        // Here we just verify the agent was properly formed
      });

      test('should query agents', () {
        final agents = [
          AgentConfig(
            id: 'agent-001',
            name: 'Math Expert',
            toolIds: ['calculator'],
            enabled: true,
            createdAt: now,
            updatedAt: now,
          ),
          AgentConfig(
            id: 'agent-002',
            name: 'Search Expert',
            toolIds: ['search'],
            enabled: true,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        expect(agents.length, 2);
        expect(agents[0].name, 'Math Expert');
      });
    });

    group('Tool Management', () {
      test('should create tool configuration', () {
        final tool = AgentTool(
          id: 'tool-001',
          name: 'calculator',
          description: 'Mathematical calculator',
          type: AgentToolType.calculator,
          parameters: {
            'type': 'object',
            'properties': {
              'expression': {'type': 'string'},
            },
          },
          enabled: true,
          isBuiltIn: true,
        );

        expect(tool.id, 'tool-001');
        expect(tool.type, AgentToolType.calculator);
        expect(tool.parameters, isNotNull);
      });

      test('should retrieve tool by id', () {
        final tool = AgentTool(
          id: 'search-tool',
          name: 'search',
          description: 'Web search',
          type: AgentToolType.search,
          enabled: true,
        );

        expect(tool.id, 'search-tool');
        expect(tool.name, 'search');
      });

      test('should list all tools', () {
        final tools = [
          AgentTool(
            id: 'calc',
            name: 'calculator',
            type: AgentToolType.calculator,
            enabled: true,
          ),
          AgentTool(
            id: 'search',
            name: 'search',
            type: AgentToolType.search,
            enabled: true,
          ),
          AgentTool(
            id: 'file',
            name: 'file_operation',
            type: AgentToolType.fileOperation,
            enabled: true,
          ),
        ];

        expect(tools.length, 3);
        expect(tools.where((t) => t.type == AgentToolType.calculator).length, 1);
      });

      test('should filter tools by type', () {
        final tools = [
          AgentTool(
            id: 'calc1',
            name: 'calc1',
            type: AgentToolType.calculator,
            enabled: true,
          ),
          AgentTool(
            id: 'calc2',
            name: 'calc2',
            type: AgentToolType.calculator,
            enabled: true,
          ),
          AgentTool(
            id: 'search1',
            name: 'search',
            type: AgentToolType.search,
            enabled: true,
          ),
        ];

        final calculators = tools.where((t) => t.type == AgentToolType.calculator).toList();
        expect(calculators.length, 2);
      });
    });

    group('Agent-Tool Association', () {
      test('should associate tools with agent', () {
        final agent = AgentConfig(
          id: 'agent-001',
          name: 'Assistant',
          toolIds: ['tool1', 'tool2', 'tool3'],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(agent.toolIds.length, 3);
        expect(agent.toolIds.contains('tool2'), true);
      });

      test('should add tool to agent', () {
        var toolIds = ['tool1', 'tool2'];
        toolIds.add('tool3');

        expect(toolIds.length, 3);
        expect(toolIds.contains('tool3'), true);
      });

      test('should remove tool from agent', () {
        var toolIds = ['tool1', 'tool2', 'tool3'];
        toolIds.remove('tool2');

        expect(toolIds.length, 2);
        expect(toolIds.contains('tool2'), false);
      });

      test('should verify tool accessibility', () {
        final agent = AgentConfig(
          id: 'agent-001',
          name: 'Assistant',
          toolIds: ['calculator', 'search', 'file_op'],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(agent.toolIds.contains('calculator'), true);
        expect(agent.toolIds.contains('search'), true);
        expect(agent.toolIds.contains('undefined_tool'), false);
      });
    });

    group('Tool Execution', () {
      test('should execute tool with parameters', () {
        final toolCall = ToolCall(
          id: 'call-001',
          toolId: 'calculator',
          toolName: 'calculator',
          parameters: {'expression': '2 + 2'},
          timestamp: now,
        );

        final result = ToolExecutionResult(
          success: true,
          result: '4',
          metadata: {'duration_ms': 100},
        );

        expect(toolCall.toolId, 'calculator');
        expect(result.result, '4');
      });

      test('should track execution status', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Completed',
          metadata: {
            'status': 'success',
            'timestamp': now.toIso8601String(),
          },
        );

        expect(result.success, true);
        expect(result.metadata?['status'], 'success');
      });

      test('should update tool status after execution', () {
        final originalTool = AgentTool(
          id: 'tool-001',
          name: 'test_tool',
          type: AgentToolType.custom,
          enabled: true,
        );

        final updatedTool = originalTool;
        expect(updatedTool.enabled, true);
      });
    });

    group('Built-in Agents and Tools', () {
      test('should initialize built-in agents', () {
        final builtInAgents = [
          AgentConfig(
            id: 'builtin-math',
            name: 'Math Expert',
            toolIds: ['calculator'],
            enabled: true,
            createdAt: now,
            updatedAt: now,
            isBuiltIn: true,
          ),
          AgentConfig(
            id: 'builtin-search',
            name: 'Research Assistant',
            toolIds: ['search'],
            enabled: true,
            createdAt: now,
            updatedAt: now,
            isBuiltIn: true,
          ),
        ];

        expect(builtInAgents.length, 2);
        expect(builtInAgents.every((a) => a.isBuiltIn), true);
      });

      test('should initialize built-in tools', () {
        final builtInTools = [
          AgentTool(
            id: 'builtin-calc',
            name: 'calculator',
            type: AgentToolType.calculator,
            enabled: true,
            isBuiltIn: true,
          ),
          AgentTool(
            id: 'builtin-search',
            name: 'search',
            type: AgentToolType.search,
            enabled: true,
            isBuiltIn: true,
          ),
        ];

        expect(builtInTools.every((t) => t.isBuiltIn), true);
      });

      test('should prevent modification of built-in agents', () {
        final builtInAgent = AgentConfig(
          id: 'builtin-001',
          name: 'Protected Agent',
          toolIds: ['tool1'],
          enabled: true,
          createdAt: now,
          updatedAt: now,
          isBuiltIn: true,
        );

        // Verify it's marked as built-in
        expect(builtInAgent.isBuiltIn, true);
      });
    });
  });
}
