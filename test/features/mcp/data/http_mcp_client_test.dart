import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:chat_app/features/mcp/data/http_mcp_client.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late McpConfig testConfig;
  late HttpMcpClient client;

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    testConfig = McpConfig(
      id: 'test-http-mcp',
      name: 'Test HTTP MCP',
      connectionType: McpConnectionType.http,
      endpoint: 'https://api.test.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    client = HttpMcpClient(config: testConfig, dio: dio);
  });

  tearDown(() {
    client.dispose();
  });

  group('Bug #001: MCP 健康检查和 SSE 支持', () {
    group('healthCheck', () {
      test('应该成功执行健康检查', () async {
        // 模拟健康检查成功响应
        dioAdapter.onGet(
          '/health',
          (server) => server.reply(200, {'status': 'healthy'}),
        );

        final result = await client.healthCheck();

        expect(result, true);
        expect(client.lastHealthCheck, isNotNull);
        expect(client.lastError, isNull);
      });

      test('应该处理健康检查失败', () async {
        // 模拟健康检查失败响应
        dioAdapter.onGet(
          '/health',
          (server) => server.reply(500, {'error': 'Server error'}),
        );

        final result = await client.healthCheck();

        expect(result, false);
        expect(client.lastError, isNotNull);
      });

      test('应该处理网络错误', () async {
        // 模拟网络错误
        dioAdapter.onGet(
          '/health',
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/health'),
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );

        final result = await client.healthCheck();

        expect(result, false);
        expect(client.lastError, isNotNull);
      });
    });

    group('connect', () {
      test('应该成功连接并启动心跳', () async {
        // 模拟健康检查成功响应
        dioAdapter.onGet(
          '/health',
          (server) => server.reply(200, {'status': 'healthy'}),
        );

        final result = await client.connect();

        expect(result, true);
        expect(client.status, McpConnectionStatus.connected);
      });

      test('连接失败时应该设置错误状态', () async {
        // 模拟健康检查失败响应
        dioAdapter.onGet(
          '/health',
          (server) => server.reply(500, {'error': 'Server error'}),
        );

        final result = await client.connect();

        expect(result, false);
        expect(client.status, McpConnectionStatus.error);
      });
    });

    group('SSE 连接', () {
      test('应该能够建立 SSE 连接', () async {
        // 模拟 SSE 响应流
        dioAdapter.onGet(
          '/events',
          (server) => server.reply(
            200,
            Stream.fromIterable(['data: test1\n\n', 'data: test2\n\n']),
            headers: {
              'content-type': ['text/event-stream'],
            },
          ),
        );

        final stream = await client.connectSSE('/events');

        expect(stream, isNotNull);
      });

      test('SSE 连接失败时应该返回 null', () async {
        // 模拟 SSE 连接失败
        dioAdapter.onGet(
          '/events',
          (server) => server.reply(500, {'error': 'Server error'}),
        );

        final stream = await client.connectSSE('/events');

        expect(stream, isNull);
      });
    });

    group('disconnect', () {
      test('应该正确断开连接并清理资源', () async {
        // 先连接
        dioAdapter.onGet(
          '/health',
          (server) => server.reply(200, {'status': 'healthy'}),
        );

        await client.connect();
        expect(client.status, McpConnectionStatus.connected);

        // 断开连接
        await client.disconnect();

        expect(client.status, McpConnectionStatus.disconnected);
      });
    });

    group('MCP 工具调用', () {
      test('应该成功调用工具', () async {
        final toolName = 'test-tool';
        final params = {'param1': 'value1'};
        final expectedResponse = {'result': 'success'};

        dioAdapter.onPost(
          '/tools/$toolName',
          (server) => server.reply(200, expectedResponse),
          data: params,
        );

        final result = await client.callTool(toolName, params);

        expect(result, expectedResponse);
      });

      test('应该获取工具列表', () async {
        final expectedTools = [
          {'name': 'tool1', 'description': 'Tool 1'},
          {'name': 'tool2', 'description': 'Tool 2'},
        ];

        dioAdapter.onGet(
          '/tools',
          (server) => server.reply(200, expectedTools),
        );

        final result = await client.listTools();

        expect(result, expectedTools);
      });
    });

    group('上下文管理', () {
      test('应该成功获取上下文', () async {
        final contextId = 'test-context';
        final expectedContext = {'data': 'test-data'};

        dioAdapter.onGet(
          '/context/$contextId',
          (server) => server.reply(200, expectedContext),
        );

        final result = await client.getContext(contextId);

        expect(result, expectedContext);
      });

      test('应该成功推送上下文', () async {
        final contextId = 'test-context';
        final context = {'data': 'test-data'};

        dioAdapter.onPost(
          '/context/$contextId',
          (server) => server.reply(200, {'success': true}),
          data: context,
        );

        final result = await client.pushContext(contextId, context);

        expect(result, true);
      });
    });
  });
}
