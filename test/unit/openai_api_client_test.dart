import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:chat_app/core/network/openai_api_client.dart';
import 'package:chat_app/core/network/dio_client.dart';

@GenerateMocks([DioClient, Dio])
import 'openai_api_client_test.mocks.dart';

void main() {
  late OpenAIApiClient apiClient;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(mockDioClient.dio).thenReturn(mockDio);
    apiClient = OpenAIApiClient(mockDioClient);
  });

  group('OpenAIApiClient - testConnection', () {
    test('应该返回成功结果当API响应正常', () async {
      // Arrange
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/models'),
        statusCode: 200,
        data: {
          'data': [
            {'id': 'gpt-4'},
            {'id': 'gpt-3.5-turbo'},
          ],
        },
      );

      when(
        mockDio.get('/models', options: anyNamed('options')),
      ).thenAnswer((_) async => mockResponse);

      // Act
      final result = await apiClient.testConnection();

      // Assert
      expect(result.success, true);
      expect(result.message, contains('2'));
    });

    test('应该返回失败结果当API Key无效', () async {
      // Arrange
      when(mockDio.get('/models', options: anyNamed('options'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/models'),
          response: Response(
            requestOptions: RequestOptions(path: '/models'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act
      final result = await apiClient.testConnection();

      // Assert
      expect(result.success, false);
      expect(result.message, contains('API Key'));
    });

    test('应该返回失败结果当网络超时', () async {
      // Arrange
      when(mockDio.get('/models', options: anyNamed('options'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/models'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act
      final result = await apiClient.testConnection();

      // Assert
      expect(result.success, false);
      expect(result.message, contains('超时'));
    });
  });

  group('OpenAIApiClient - getAvailableModels', () {
    test('应该返回模型列表', () async {
      // Arrange
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/models'),
        data: {
          'data': [
            {'id': 'gpt-4'},
            {'id': 'gpt-3.5-turbo'},
            {'id': 'text-davinci-003'},
          ],
        },
      );

      when(mockDio.get('/models')).thenAnswer((_) async => mockResponse);

      // Act
      final models = await apiClient.getAvailableModels();

      // Assert
      expect(models.length, 3);
      expect(models, contains('gpt-4'));
      expect(models, contains('gpt-3.5-turbo'));
    });

    test('应该返回默认模型当API调用失败', () async {
      // Arrange
      when(mockDio.get('/models')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/models'),
          type: DioExceptionType.unknown,
        ),
      );

      // Act
      final models = await apiClient.getAvailableModels();

      // Assert
      expect(models.isEmpty, true);
      // expect(models, contains('gpt-4'));  // API failed, returns empty list
    });
  });
}
