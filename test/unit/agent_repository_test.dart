import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('AgentConfig Unit Tests', () {
    test('should create agent config', () {
      final config = AgentConfig(
        id: 'test-id',
        name: 'Test Agent',
        toolIds: ['tool1'],
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(config.name, 'Test Agent');
      expect(config.enabled, true);
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

  group('AgentTool Unit Tests', () {
    test('should create tool with enabled status', () {
      final tool = AgentTool(
        id: 'test-id',
        name: 'Test Tool',
        description: 'Test',
        type: AgentToolType.search,
        enabled: true,
      );

      expect(tool.enabled, true);
    });

    test('should create tool with disabled status', () {
      final tool = AgentTool(
        id: 'test-id',
        name: 'Test Tool',
        description: 'Test',
        type: AgentToolType.search,
        enabled: false,
      );

      expect(tool.enabled, false);
    });
  });
}
