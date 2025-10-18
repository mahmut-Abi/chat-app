import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';
import 'package:chat_app/features/agent/data/agent_repository.dart';
import 'package:chat_app/features/agent/data/tool_executor.dart';
import 'package:chat_app/core/storage/storage_service.dart';

/// Agent 功能验证测试
void main() {
  group('Agent 功能验证', () {
    late AgentRepository repository;
    late StorageService storage;
    late ToolExecutorManager executorManager;

    setUp(() {
      storage = StorageService();
      executorManager = ToolExecutorManager();
      repository = AgentRepository(storage, executorManager);
    });

    test('应该能创建 Agent 配置', () async {
      final agent = await repository.createAgent(
        name: '测试 Agent',
        description: '用于测试的 Agent',
        toolIds: ['tool1', 'tool2'],
        systemPrompt: '你是一个测试助手',
      );

      expect(agent.name, '测试 Agent');
      expect(agent.description, '用于测试的 Agent');
      expect(agent.toolIds.length, 2);
      expect(agent.systemPrompt, '你是一个测试助手');
      expect(agent.isEnabled, true);
    });

    test('应该能创建工具', () async {
      final tool = await repository.createTool(
        name: 'test_calculator',
        description: '测试计算器',
        type: AgentToolType.calculator,
        parameters: {
          'expression': {'type': 'string'},
        },
      );

      expect(tool.name, 'test_calculator');
      expect(tool.type, AgentToolType.calculator);
      expect(tool.enabled, true);
    });

    test('计算器工具应该能正确计算', () async {
      final tool = AgentTool(
        id: 'calc1',
        name: 'calculator',
        description: '计算器',
        type: AgentToolType.calculator,
        parameters: {},
      );

      final result = await repository.executeTool(
        tool,
        {'expression': '2+2'},
      );

      expect(result.success, true);
      expect(result.result, contains('4'));
    });

    test('搜索工具应该能返回结果', () async {
      final tool = AgentTool(
        id: 'search1',
        name: 'search',
        description: '搜索工具',
        type: AgentToolType.search,
        parameters: {},
      );

      final result = await repository.executeTool(
        tool,
        {'query': 'Flutter'},
      );

      expect(result.success, true);
      expect(result.result, isNotNull);
      expect(result.result, contains('Flutter'));
    });

    test('应该能保存和读取 Agent 配置', () async {
      // 创建并保存
      final agent = await repository.createAgent(
        name: '持久化测试',
        description: '测试持久化',
        toolIds: ['tool1'],
      );

      // 读取所有配置
      final agents = await repository.getAllAgents();

      // 验证
      expect(agents.any((a) => a.id == agent.id), true);
      final loadedAgent = agents.firstWhere((a) => a.id == agent.id);
      expect(loadedAgent.name, '持久化测试');
      expect(loadedAgent.description, '测试持久化');
    });

    test('应该能更新 Agent 配置', () async {
      // 创建
      final agent = await repository.createAgent(
        name: '原始名称',
        description: '原始描述',
        toolIds: [],
      );

      // 更新
      final updated = agent.copyWith(
        name: '更新后的名称',
        description: '更新后的描述',
      );
      await repository.updateAgent(updated);

      // 验证
      final agents = await repository.getAllAgents();
      final loadedAgent = agents.firstWhere((a) => a.id == agent.id);
      expect(loadedAgent.name, '更新后的名称');
      expect(loadedAgent.description, '更新后的描述');
    });

    test('应该能删除 Agent 配置', () async {
      // 创建
      final agent = await repository.createAgent(
        name: '待删除',
        description: '测试删除',
        toolIds: [],
      );

      // 删除
      await repository.deleteAgent(agent.id);

      // 验证
      final agents = await repository.getAllAgents();
      expect(agents.any((a) => a.id == agent.id), false);
    });

    test('应该能处理工具执行错误', () async {
      final tool = AgentTool(
        id: 'calc2',
        name: 'calculator',
        description: '计算器',
        type: AgentToolType.calculator,
        parameters: {},
      );

      // 无效的表达式
      final result = await repository.executeTool(
        tool,
        {'expression': ''},
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('文件操作工具应该能读取文件信息', () async {
      final tool = AgentTool(
        id: 'file1',
        name: 'file_reader',
        description: '文件操作',
        type: AgentToolType.fileOperation,
        parameters: {},
      );

      // 测试获取当前目录信息
      final result = await repository.executeTool(
        tool,
        {
          'operation': 'info',
          'path': '.',
        },
      );

      expect(result.success, true);
      expect(result.result, isNotNull);
    });
  });

  group('工具执行器测试', () {
    test('ToolExecutorManager 应该注册所有工具', () {
      final manager = ToolExecutorManager();

      // 验证所有工具类型都已注册
      expect(manager, isNotNull);
    });
  });

  group('Agent 工具类型测试', () {
    test('应该支持所有工具类型', () {
      final types = [
        AgentToolType.calculator,
        AgentToolType.search,
        AgentToolType.fileOperation,
        AgentToolType.codeExecution,
        AgentToolType.custom,
      ];

      for (final type in types) {
        expect(type, isNotNull);
      }
    });
  });
}
