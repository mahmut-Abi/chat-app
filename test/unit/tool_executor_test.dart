import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/data/tool_executor.dart';
import 'package:chat_app/features/agent/data/tools/calculator_tool.dart';
import 'package:chat_app/features/agent/data/tools/search_tool.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('CalculatorTool', () {
    late EnhancedCalculatorTool calculator;

    setUp(() {
      calculator = EnhancedCalculatorTool();
    });

    test('应该正确执行加法运算', () async {
      final tool = AgentTool(
        id: 'calc-1',
        name: 'Calculator',
        description: 'Test calculator',
        type: AgentToolType.calculator,
      );

      final result = await calculator.execute(
        tool,
        {'expression': '1+1'},
      );

      expect(result.success, true);
      expect(result.result, contains('2'));
    });

    test('应该正确执行乘法运算', () async {
      final tool = AgentTool(
        id: 'calc-2',
        name: 'Calculator',
        description: 'Test calculator',
        type: AgentToolType.calculator,
      );

      final result = await calculator.execute(
        tool,
        {'expression': '5*3'},
      );

      expect(result.success, true);
      expect(result.result, contains('15'));
    });

    test('应该处理缺少表达式的情况', () async {
      final tool = AgentTool(
        id: 'calc-3',
        name: 'Calculator',
        description: 'Test calculator',
        type: AgentToolType.calculator,
      );

      final result = await calculator.execute(tool, {});

      expect(result.success, false);
      expect(result.error, contains('缺少表达式参数'));
    });
  });

  group('SearchTool', () {
    late EnhancedSearchTool searchTool;

    setUp(() {
      searchTool = EnhancedSearchTool();
    });

    test('应该成功执行搜索', () async {
      final tool = AgentTool(
        id: 'search-1',
        name: 'Search',
        description: 'Test search',
        type: AgentToolType.search,
      );

      final result = await searchTool.execute(
        tool,
        {'query': 'Flutter'},
      );

      expect(result.success, true);
      expect(result.result, contains('Flutter'));
      expect(result.metadata?['query'], 'Flutter');
    });

    test('应该处理空查询', () async {
      final tool = AgentTool(
        id: 'search-2',
        name: 'Search',
        description: 'Test search',
        type: AgentToolType.search,
      );

      final result = await searchTool.execute(tool, {'query': ''});

      expect(result.success, false);
      expect(result.error, contains('缺少搜索查询参数'));
    });
  });

  group('ToolExecutorManager', () {
    late ToolExecutorManager manager;

    setUp(() {
      manager = ToolExecutorManager();
    });

    test('应该成功注册和执行工具', () async {
      final tool = AgentTool(
        id: 'calc-test',
        name: 'Calculator',
        description: 'Test',
        type: AgentToolType.calculator,
      );

      final result = await manager.execute(
        tool,
        {'expression': '10+5'},
      );

      expect(result.success, true);
    });

    test('应该处理未注册的工具类型', () async {
      final tool = AgentTool(
        id: 'unknown-tool',
        name: 'Unknown',
        description: 'Test',
        type: AgentToolType.custom,
      );

      final result = await manager.execute(tool, {});

      expect(result.success, false);
      expect(result.error, contains('未找到工具执行器'));
    });
  });
}
