import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:chat_app/features/mcp/data/mcp_health_check_strategy.dart';

// Mock Dio
class MockDio extends Mock implements Dio {}

void main() {
  group('HealthCheckStrategy Tests', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    test('StandardHealthCheckExecutor should succeed on 200 status', () async {
      final executor = StandardHealthCheckExecutor(dio: mockDio);

      when(mockDio.get(any, options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'status': 'ok'},
        ),
      );

      final result = await executor.execute('http://localhost:8000', null);

      expect(result.success, true);
      expect(result.strategy, HealthCheckStrategy.standard);
      expect(result.detectedEndpoint, '/health');
    });

    test('StandardHealthCheckExecutor should fail on non-200 status', () async {
      final executor = StandardHealthCheckExecutor(dio: mockDio);

      when(mockDio.get(any, options: anyNamed('options'))).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: ''), statusCode: 503),
      );

      final result = await executor.execute('http://localhost:8000', null);

      expect(result.success, false);
      expect(result.strategy, HealthCheckStrategy.standard);
    });

    test('ProbeHealthCheckExecutor should find valid endpoint', () async {
      final executor = ProbeHealthCheckExecutor(dio: mockDio);

      when(mockDio.get(any, options: anyNamed('options'))).thenAnswer((
        invocation,
      ) async {
        final url = invocation.positionalArguments[0] as String;
        if (url.endsWith('/health')) {
          return Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          );
        }
        throw DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Not found',
        );
      });

      final result = await executor.execute('http://localhost:8000', null);

      expect(result.success, true);
      expect(result.strategy, HealthCheckStrategy.probe);
      expect(result.detectedEndpoint, '/health');
    });

    test(
      'ToolsListingHealthCheckExecutor should parse tools correctly',
      () async {
        final executor = ToolsListingHealthCheckExecutor(dio: mockDio);

        when(mockDio.get(any, options: anyNamed('options'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: [
              {'name': 'tool1', 'description': 'Tool 1'},
              {'name': 'tool2', 'description': 'Tool 2'},
            ],
          ),
        );

        final result = await executor.execute('http://localhost:8000', null);

        expect(result.success, true);
        expect(result.strategy, HealthCheckStrategy.toolsListing);
        expect(result.details?['toolCount'], 2);
      },
    );
  });
}
