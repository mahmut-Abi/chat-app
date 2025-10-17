import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:chat_app/features/mcp/data/http_mcp_client.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';

import 'http_mcp_client_health_check_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late McpConfig testConfig;
  late HttpMcpClient client;

  setUp(() {
    mockDio = MockDio();
    testConfig = McpConfig(
      id: 'test-mcp-1',
      name: 'Test MCP Server',
      endpoint: 'http://localhost:3000',
      enabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    client = HttpMcpClient(config: testConfig, dio: mockDio);
  });

  group('HTTP MCP Client Health Check', () {
    test('should return true when health check is successful', () async {
      when(mockDio.get('/health', options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/health'),
        ),
      );

      final result = await client.healthCheck();

      expect(result, true);
      expect(client.lastHealthCheck, isNotNull);
      expect(client.lastError, isNull);
      verify(mockDio.get('/health', options: anyNamed('options'))).called(1);
    });

    test('should return false on non-200 status', () async {
      when(mockDio.get('/health', options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/health'),
        ),
      );

      final result = await client.healthCheck();

      expect(result, false);
      expect(client.lastError, 'HTTP 500');
    });

    test('should return false when exception occurs', () async {
      when(mockDio.get('/health', options: anyNamed('options'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/health'),
          error: 'Network error',
        ),
      );

      final result = await client.healthCheck();

      expect(result, false);
      expect(client.lastError, isNotNull);
    });

    test('should update lastHealthCheck timestamp on success', () async {
      final beforeCheck = DateTime.now();
      when(mockDio.get('/health', options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/health'),
        ),
      );

      await client.healthCheck();
      final afterCheck = DateTime.now();

      expect(client.lastHealthCheck, isNotNull);
      expect(
        client.lastHealthCheck!.isAfter(
          beforeCheck.subtract(const Duration(seconds: 1)),
        ),
        true,
      );
      expect(
        client.lastHealthCheck!.isBefore(
          afterCheck.add(const Duration(seconds: 1)),
        ),
        true,
      );
    });

    test('should clear lastError on successful health check', () async {
      client.lastError = 'Previous error';
      when(mockDio.get('/health', options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/health'),
        ),
      );

      await client.healthCheck();

      expect(client.lastError, isNull);
    });
  });

  group('HTTP MCP Client Connection', () {
    test('should set status to connected on successful connection', () async {
      when(mockDio.get('/health', options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/health'),
        ),
      );

      final result = await client.connect();

      expect(result, true);
      expect(client.status, McpConnectionStatus.connected);
    });

    test('should set status to error on failed connection', () async {
      when(mockDio.get('/health', options: anyNamed('options'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/health'),
          error: 'Connection failed',
        ),
      );

      final result = await client.connect();

      expect(result, false);
      expect(client.status, McpConnectionStatus.error);
    });

    test(
      'should set status to disconnected when disconnect is called',
      () async {
        when(mockDio.get('/health', options: anyNamed('options'))).thenAnswer(
          (_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: '/health'),
          ),
        );
        await client.connect();

        await client.disconnect();

        expect(client.status, McpConnectionStatus.disconnected);
      },
    );
  });
}
