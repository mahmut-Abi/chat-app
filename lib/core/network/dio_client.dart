import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_exception.dart';

class DioClient {
  late final Dio _dio;

  DioClient({
    required String baseUrl,
    required String apiKey,
    int connectTimeout = 30000,
    int receiveTimeout = 30000,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$apiKey',
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final apiException = _handleError(error);
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: apiException,
            ),
          );
        },
      ),
    );
  }

  Dio get dio => _dio;

  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();

      case DioExceptionType.connectionError:
        return NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return UnauthorizedException();
        } else if (statusCode == 429) {
          return RateLimitException();
        }
        return ApiException(
          message: error.response?.data?['error']?['message'] ??
              'Server error occurred',
          statusCode: statusCode,
        );

      default:
        return ApiException(
          message: error.message ?? 'Unknown error occurred',
        );
    }
  }
}
