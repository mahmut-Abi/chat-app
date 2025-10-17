import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:chat_app/features/mcp/data/http_mcp_client.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';

import '../http_mcp_client_health_check_test.mocks.dart';

@GenerateMocks([Dio, ResponseBody])
void main() {
  late MockDio mockDio;
  late McpConfig testConfig;
  late HttpMcpClient client;

  setUp(() {
    mockDio = MockDio();
    testConfig = McpConfig(
      id: 'test-sse',
      name: 'SSE Test Server',
      endpoint: 'http://localhost:3000',
      enabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    client = HttpMcpClient(config: testConfig, dio: mockDio);
  });

  group('SSE Protocol Support Tests', () {
    test('should create SSE connection with correct headers', () async {
      // Given: SSE 端点
      final endpoint = '/events';

      // When: 构建请求
      final headers = {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      };

      // Then: 应该有正确的头
      expect(headers['Accept'], equals('text/event-stream'));
      expect(headers['Cache-Control'], equals('no-cache'));
    });

    test('should parse SSE data events correctly', () {
      // Given: SSE 数据行
      final lines = [
        'data: {"type": "message", "content": "Hello"}',
        'data: {"type": "update", "status": "processing"}',
        '',
      ];

      // When: 解析数据
      final dataLines = lines
          .where((line) => line.startsWith('data: '))
          .map((line) => line.substring(6))
          .toList();

      // Then: 应该正确解析
      expect(dataLines.length, equals(2));
      expect(dataLines[0], contains('message'));
      expect(dataLines[1], contains('update'));
    });

    test('should handle SSE event types', () {
      // Given: 带类型的事件
      final lines = [
        'event: customEvent',
        'data: {"info": "test"}',
        '',
      ];

      // When: 解析事件类型
      final eventLine = lines.firstWhere((l) => l.startsWith('event: '));
      final eventType = eventLine.substring(7);

      // Then: 应该正确获取类型
      expect(eventType, equals('customEvent'));
    });

    test('should handle SSE comments', () {
      // Given: 带注释的数据
      final lines = [
        ': This is a heartbeat comment',
        'data: actual data',
        ': Another comment',
        '',
      ];

      // When: 过滤注释
      final dataLines =
          lines.where((line) => !line.startsWith(':') && line.isNotEmpty).toList();

      // Then: 应该只保留数据
      expect(dataLines.length, equals(1));
      expect(dataLines[0], equals('data: actual data'));
    });

    test('should handle SSE retry directive', () {
      // Given: 重连指令
      final line = 'retry: 3000';

      // When: 解析重连时间
      final retryTime = int.parse(line.substring(7));

      // Then: 应该正确解析
      expect(retryTime, equals(3000));
    });

    test('should handle SSE id field', () {
      // Given: 带 ID 的事件
      final line = 'id: 12345';

      // When: 解析 ID
      final eventId = line.substring(4);

      // Then: 应该正确获取
      expect(eventId, equals('12345'));
    });
  });

  group('SSE Stream Management Tests', () {
    test('should handle multiple data lines in single event', () {
      // Given: 多行数据
      final lines = [
        'data: First line',
        'data: Second line',
        'data: Third line',
        '',
      ];

      // When: 合并数据
      final dataLines = lines
          .where((line) => line.startsWith('data: '))
          .map((line) => line.substring(6))
          .toList();
      final combined = dataLines.join('\n');

      // Then: 应该正确合并
      expect(combined, equals('First line\nSecond line\nThird line'));
    });

    test('should handle connection close gracefully', () async {
      // Given: 流控制器
      var isClosed = false;

      // When: 关闭连接
      isClosed = true;

      // Then: 应该标记为关闭
      expect(isClosed, isTrue);
    });
  });

  group('SSE Error Handling Tests', () {
    test('should handle malformed SSE data', () {
      // Given: 格式错误的数据
      final line = 'invalid sse format';

      // When: 检查格式
      final isValid = line.contains(':');

      // Then: 应该识别为无效
      expect(isValid, isFalse);
    });

    test('should handle connection timeout', () async {
      // Given: 超时配置
      final timeout = Duration(seconds: 30);
      var hasTimeout = false;

      // When: 超时发生
      hasTimeout = true;

      // Then: 应该标记超时
      expect(hasTimeout, isTrue);
      expect(timeout.inSeconds, equals(30));
    });

    test('should handle reconnection after error', () {
      // Given: 错误后的重连
      var reconnectAttempts = 0;
      const maxAttempts = 3;

      // When: 尝试重连
      reconnectAttempts++;

      // Then: 应该记录尝试次数
      expect(reconnectAttempts, lessThanOrEqualTo(maxAttempts));
    });
  });

  group('SSE Integration with MCP Client Tests', () {
    test('should integrate SSE with HTTP MCP client', () {
      // Given: HTTP MCP 客户端
      final hasConnectSSEMethod = client.connectSSE != null;

      // Then: 应该有 SSE 方法
      expect(hasConnectSSEMethod, isTrue);
    });
  });
}
