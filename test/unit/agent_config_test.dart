import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('AgentConfig', () {
    test('should create AgentConfig with default values', () {
      final config = AgentConfig(
        id: 'test-id',
        name: 'Test Agent',
        toolIds: ['tool1', 'tool2'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(config.id, 'test-id');
      expect(config.name, 'Test Agent');
      expect(config.toolIds, ['tool1', 'tool2']);
      expect(config.enabled, true);
      expect(config.description, null);
      expect(config.systemPrompt, null);
    });

    test('should create AgentConfig with custom values', () {
      final config = AgentConfig(
        id: 'test-id',
        name: 'Test Agent',
        description: 'Test description',
        toolIds: ['tool1'],
        systemPrompt: 'You are a helpful assistant',
        enabled: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(config.enabled, false);
      expect(config.description, 'Test description');
      expect(config.systemPrompt, 'You are a helpful assistant');
    });

    test('should create copy with updated values', () {
      final original = AgentConfig(
        id: 'test-id',
        name: 'Original',
        toolIds: ['tool1'],
        enabled: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Updated',
        enabled: false,
        toolIds: ['tool1', 'tool2'],
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Updated');
      expect(updated.enabled, false);
      expect(updated.toolIds, ['tool1', 'tool2']);
    });

    test('should convert to and from JSON', () {
      final config = AgentConfig(
        id: 'test-id',
        name: 'Test Agent',
        description: 'Test',
        toolIds: ['tool1', 'tool2'],
        systemPrompt: 'System prompt',
        enabled: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = config.toJson();
      final restored = AgentConfig.fromJson(json);

      expect(restored.id, config.id);
      expect(restored.name, config.name);
      expect(restored.enabled, config.enabled);
      expect(restored.toolIds, config.toolIds);
    });

    test('should toggle enabled status', () {
      final config = AgentConfig(
        id: 'test-id',
        name: 'Test',
        toolIds: [],
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final disabled = config.copyWith(enabled: false);
      expect(disabled.enabled, false);

      final enabled = disabled.copyWith(enabled: true);
      expect(enabled.enabled, true);
    });
  });

  group('AgentTool', () {
    test('should create AgentTool with default values', () {
      final tool = AgentTool(
        id: 'test-id',
        name: 'Test Tool',
        description: 'Test description',
        type: AgentToolType.search,
      );

      expect(tool.id, 'test-id');
      expect(tool.name, 'Test Tool');
      expect(tool.description, 'Test description');
      expect(tool.type, AgentToolType.search);
      expect(tool.enabled, true);
      expect(tool.parameters, {});
    });

    test('should create AgentTool with custom values', () {
      final tool = AgentTool(
        id: 'test-id',
        name: 'Test Tool',
        description: 'Test description',
        type: AgentToolType.custom,
        enabled: false,
        parameters: {'param1': 'value1'},
        iconName: 'custom_icon',
      );

      expect(tool.enabled, false);
      expect(tool.parameters, {'param1': 'value1'});
      expect(tool.iconName, 'custom_icon');
    });

    test('should convert to and from JSON', () {
      final tool = AgentTool(
        id: 'test-id',
        name: 'Test Tool',
        description: 'Test',
        type: AgentToolType.calculator,
        enabled: true,
        parameters: {'key': 'value'},
      );

      final json = tool.toJson();
      final restored = AgentTool.fromJson(json);

      expect(restored.id, tool.id);
      expect(restored.name, tool.name);
      expect(restored.type, tool.type);
      expect(restored.enabled, tool.enabled);
    });
  });

  group('AgentToolType', () {
    test('should have all tool types', () {
      expect(AgentToolType.search, isA<AgentToolType>());
      expect(AgentToolType.codeExecution, isA<AgentToolType>());
      expect(AgentToolType.fileOperation, isA<AgentToolType>());
      expect(AgentToolType.calculator, isA<AgentToolType>());
      expect(AgentToolType.custom, isA<AgentToolType>());
    });
  });

  group('ToolExecutionResult', () {
    test('should create successful result', () {
      final result = ToolExecutionResult(
        success: true,
        result: 'Execution successful',
      );

      expect(result.success, true);
      expect(result.result, 'Execution successful');
      expect(result.error, null);
    });

    test('should create error result', () {
      final result = ToolExecutionResult(
        success: false,
        error: 'Execution failed',
      );

      expect(result.success, false);
      expect(result.error, 'Execution failed');
      expect(result.result, null);
    });

    test('should convert to and from JSON', () {
      final result = ToolExecutionResult(
        success: true,
        result: 'Success',
        metadata: {'duration': 100},
      );

      final json = result.toJson();
      final restored = ToolExecutionResult.fromJson(json);

      expect(restored.success, result.success);
      expect(restored.result, result.result);
    });
  });
}
