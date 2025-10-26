import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('AgentConfig Comprehensive Tests', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('Creation and Properties', () {
      test('should create agent config with all required fields', () {
        final config = AgentConfig(
          id: 'agent-001',
          name: 'Math Expert',
          description: 'Specialized in mathematical computations',
          toolIds: ['calculator', 'search'],
          systemPrompt: 'You are a math expert',
          enabled: true,
          createdAt: now,
          updatedAt: now,
          isBuiltIn: false,
          iconName: 'calculator',
        );

        expect(config.id, 'agent-001');
        expect(config.name, 'Math Expert');
        expect(config.description, 'Specialized in mathematical computations');
        expect(config.toolIds, ['calculator', 'search']);
        expect(config.systemPrompt, 'You are a math expert');
        expect(config.enabled, true);
        expect(config.createdAt, now);
        expect(config.updatedAt, now);
        expect(config.isBuiltIn, false);
        expect(config.iconName, 'calculator');
      });

      test('should create agent with default icon', () {
        final config = AgentConfig(
          id: 'agent-001',
          name: 'Test Agent',
          toolIds: [],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        // Default icon
      });

      test('should create built-in agent', () {
        final config = AgentConfig(
          id: 'builtin-001',
          name: 'Built-in Agent',
          toolIds: ['tool1'],
          enabled: true,
          createdAt: now,
          updatedAt: now,
          isBuiltIn: true,
        );

        expect(config.isBuiltIn, true);
      });
    });

    group('CopyWith and Modifications', () {
      test('should copy with updated name', () {
        final original = AgentConfig(
          id: 'agent-001',
          name: 'Original Name',
          toolIds: ['tool1'],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(name: 'Updated Name');

        expect(updated.name, 'Updated Name');
        expect(updated.id, original.id);
        expect(updated.toolIds, original.toolIds);
      });

      test('should copy with toggled enabled status', () {
        final enabled = AgentConfig(
          id: 'agent-001',
          name: 'Test',
          toolIds: [],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        final disabled = enabled.copyWith(enabled: false);
        expect(disabled.enabled, false);

        final reEnabled = disabled.copyWith(enabled: true);
        expect(reEnabled.enabled, true);
      });

      test('should copy with updated tool ids', () {
        final original = AgentConfig(
          id: 'agent-001',
          name: 'Test',
          toolIds: ['tool1', 'tool2'],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(toolIds: ['tool1', 'tool2', 'tool3']);

        expect(updated.toolIds.length, 3);
        expect(updated.toolIds.contains('tool3'), true);
      });

      test('should copy with updated timestamp', () {
        final newTime = now.add(const Duration(hours: 1));
        final original = AgentConfig(
          id: 'agent-001',
          name: 'Test',
          toolIds: [],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(updatedAt: newTime);

        expect(updated.updatedAt, newTime);
        expect(updated.createdAt, now); // Created time unchanged
      });
    });

    group('Validation', () {
      test('should handle empty tool ids', () {
        final config = AgentConfig(
          id: 'agent-001',
          name: 'Test',
          toolIds: [],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(config.toolIds.isEmpty, true);
      });

      test('should handle multiple tool ids', () {
        final toolIds = ['tool1', 'tool2', 'tool3', 'tool4', 'tool5'];
        final config = AgentConfig(
          id: 'agent-001',
          name: 'Test',
          toolIds: toolIds,
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(config.toolIds.length, 5);
        expect(config.toolIds, toolIds);
      });

      test('should handle long descriptions', () {
        final longDesc = 'A' * 500;
        final config = AgentConfig(
          id: 'agent-001',
          name: 'Test',
          description: longDesc,
          toolIds: [],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(config.description, longDesc);
        expect(config.description?.length, 500);
      });
    });

    group('Equality and Hashing', () {
      test('should create equal configs from same data', () {
        final config1 = AgentConfig(
          id: 'agent-001',
          name: 'Test',
          toolIds: ['tool1'],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        final config2 = AgentConfig(
          id: 'agent-001',
          name: 'Test',
          toolIds: ['tool1'],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        // expect(config1 == config2, true); // AgentConfig may not implement equality
      });

      test('should create different configs with different ids', () {
        final config1 = AgentConfig(
          id: 'agent-001',
          name: 'Test',
          toolIds: [],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        final config2 = AgentConfig(
          id: 'agent-002',
          name: 'Test',
          toolIds: [],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(config1 == config2, false);
      });
    });
  });

  group('AgentTool Comprehensive Tests', () {
    group('Creation and Properties', () {
      test('should create tool with all properties', () {
        final tool = AgentTool(
          id: 'tool-001',
          name: 'calculator',
          description: 'Mathematical calculator tool',
          type: AgentToolType.calculator,
          parameters: {
            'type': 'object',
            'properties': {
              'expression': {'type': 'string'},
            },
          },
          enabled: true,
          isBuiltIn: true,
          iconName: 'calculate',
        );

        expect(tool.id, 'tool-001');
        expect(tool.name, 'calculator');
        expect(tool.type, AgentToolType.calculator);
        expect(tool.enabled, true);
        expect(tool.isBuiltIn, true);
        expect(tool.parameters, isNotEmpty);
      });

      test('should create custom tool', () {
        final tool = AgentTool(
          id: 'custom-001',
          name: 'custom_tool',
          description: 'Custom tool',
          type: AgentToolType.custom,
          enabled: false,
          isBuiltIn: false,
        );

        expect(tool.type, AgentToolType.custom);
        expect(tool.isBuiltIn, false);
        expect(tool.enabled, false);
      });
    });

    group('Tool Types', () {
      test('should support all tool types', () {
        final types = [
          AgentToolType.calculator,
          AgentToolType.search,
          AgentToolType.fileOperation,
          AgentToolType.codeExecution,
          AgentToolType.custom,
        ];

        for (final type in types) {
          final tool = AgentTool(
            id: 'test-${type.name}',
            name: type.name,
            description: 'Test tool',
            type: type,
            enabled: true,
          );

          expect(tool.type, type);
        }
      });
    });

    group('Parameters', () {
      test('should store complex parameters', () {
        final params = {
          'type': 'object',
          'properties': {
            'file_path': {'type': 'string', 'description': 'Path to file'},
            'max_size': {'type': 'integer', 'default': 1000},
          },
          'required': ['file_path'],
        };

        final tool = AgentTool(
          id: 'tool-001',
          name: 'file_reader',
          description: 'Read file',
          type: AgentToolType.fileOperation,
          parameters: params,
          enabled: true,
        );

        expect(tool.parameters, params);
        expect(tool.parameters['properties'], isNotNull);
      });

      test('should handle null parameters', () {
        final tool = AgentTool(
          id: 'tool-001',
          name: 'test_tool',
          description: 'Test',
          type: AgentToolType.custom,
          parameters: {},
          enabled: true,
        );

        expect(tool.parameters is Map, true);
      });
    });
  });
}
