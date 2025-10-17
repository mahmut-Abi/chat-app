import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/data/tools/search_tool.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('EnhancedSearchTool', () {
    late EnhancedSearchTool searchTool;
    late AgentTool tool;

    setUp(() {
      searchTool = EnhancedSearchTool();
      tool = AgentTool(
        id: 'search_1',
        name: '搜索工具',
        description: '执行网络搜索',
        type: AgentToolType.search,
      );
    });

    test('应该正确返回工具类型', () {
      // Assert
      expect(searchTool.type, AgentToolType.search);
    });

    group('参数验证', () {
      test('应该在缺少 query 参数时返回错误', () async {
        // Arrange
        final input = <String, dynamic>{};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('缺少搜索查询参数'));
        expect(result.result, isNull);
      });

      test('应该在 query 为空时返回错误', () async {
        // Arrange
        final input = {'query': ''};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('缺少搜索查询参数'));
        expect(result.result, isNull);
      });

      test('应该在 query 为 null 时返回错误', () async {
        // Arrange
        final input = {'query': null};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('缺少搜索查询参数'));
      });
    });

    group('搜索功能', () {
      test('应该成功执行搜索', () async {
        // Arrange
        final query = 'Flutter 开发';
        final input = {'query': query};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, isNotNull);
        expect(result.result, contains(query));
        expect(result.error, isNull);
      });

      test('应该在结果中包含查询关键词', () async {
        // Arrange
        final query = 'Dart 编程语言';
        final input = {'query': query};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains(query));
      });

      test('应该返回多个搜索结果', () async {
        // Arrange
        final input = {'query': '测试查询'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('相关结果 1'));
        expect(result.result, contains('相关结果 2'));
        expect(result.result, contains('相关结果 3'));
      });

      test('应该在元数据中包含查询信息', () async {
        // Arrange
        final query = '测试搜索';
        final input = {'query': query};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.metadata, isNotNull);
        expect(result.metadata!['query'], query);
        expect(result.metadata!['result_count'], isNotNull);
      });

      test('应该在元数据中包含结果数量', () async {
        // Arrange
        final input = {'query': '测试'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.metadata!['result_count'], 3);
      });

      test('应该在元数据中包含搜索时间', () async {
        // Arrange
        final input = {'query': '测试'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.metadata!['search_time_ms'], isNotNull);
        expect(result.metadata!['search_time_ms'], isA<int>());
      });
    });

    group('查询格式', () {
      test('应该支持中文查询', () async {
        // Arrange
        final input = {'query': '人工智能技术'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('人工智能技术'));
      });

      test('应该支持英文查询', () async {
        // Arrange
        final input = {'query': 'machine learning'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('machine learning'));
      });

      test('应该支持混合语言查询', () async {
        // Arrange
        final input = {'query': 'Flutter 开发 tutorial'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('Flutter 开发 tutorial'));
      });

      test('应该支持带特殊字符的查询', () async {
        // Arrange
        final input = {'query': 'C++ 编程'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('C++'));
      });

      test('应该支持长查询', () async {
        // Arrange
        final longQuery = '如何在Flutter中实现复杂的状态管理和数据持久化功能';
        final input = {'query': longQuery};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains(longQuery));
      });

      test('应该支持短查询', () async {
        // Arrange
        final input = {'query': 'AI'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('AI'));
      });

      test('应该支持数字查询', () async {
        // Arrange
        final input = {'query': '2024 技术趋势'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('2024'));
      });
    });

    group('性能测试', () {
      test('应该在合理时间内完成搜索', () async {
        // Arrange
        final input = {'query': '性能测试'};
        final stopwatch = Stopwatch()..start();

        // Act
        final result = await searchTool.execute(tool, input);
        stopwatch.stop();

        // Assert
        expect(result.success, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 应该在2秒内完成
      });

      test('应该记录搜索耗时', () async {
        // Arrange
        final input = {'query': '测试'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.metadata!['search_time_ms'], greaterThan(0));
      });
    });

    group('边界情况', () {
      test('应该处理包含引号的查询', () async {
        // Arrange
        final input = {'query': '"exact phrase" search'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, isNotNull);
      });

      test('应该处理包含换行符的查询', () async {
        // Arrange
        final input = {'query': 'line1\nline2'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, isNotNull);
      });

      test('应该处理包含空格的查询', () async {
        // Arrange
        final input = {'query': '  搜索  查询  '};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, isNotNull);
      });

      test('应该处理emoji查询', () async {
        // Arrange
        final input = {'query': '😀 emoji test'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('😀'));
      });
    });

    group('结果格式', () {
      test('应该返回格式化的搜索结果', () async {
        // Arrange
        final input = {'query': '测试'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        expect(result.result, contains('搜索结果'));
        expect(result.result, contains('1.'));
        expect(result.result, contains('2.'));
        expect(result.result, contains('3.'));
      });

      test('应该包含结果编号', () async {
        // Arrange
        final input = {'query': '格式测试'};

        // Act
        final result = await searchTool.execute(tool, input);

        // Assert
        expect(result.success, isTrue);
        final resultText = result.result!;
        expect(resultText.contains('1.'), isTrue);
        expect(resultText.contains('2.'), isTrue);
        expect(resultText.contains('3.'), isTrue);
      });
    });
  });
}
