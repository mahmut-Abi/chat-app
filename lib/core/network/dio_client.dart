import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_exception.dart';
import '../services/log_service.dart';

class DioClient {
  late final Dio _dio;
  final LogService _log = LogService();

  DioClient({
    required String baseUrl,
    required String apiKey,
    String? proxyUrl,
    String? proxyUsername,
    String? proxyPassword,
    int connectTimeout = 30000,
    int receiveTimeout = 30000,
  }) {
    _log.debug('初始化 DioClient', {
      'baseUrl': baseUrl,
      'hasProxy': proxyUrl != null && proxyUrl.isNotEmpty,
      'connectTimeout': connectTimeout,
      'receiveTimeout': receiveTimeout,
    });

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      _log.info('配置代理服务器', {
        'proxyUrl': proxyUrl,
        'hasAuth': proxyUsername != null && proxyUsername.isNotEmpty,
      });

      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.findProxy = (uri) {
          if (proxyUsername != null && proxyUsername.isNotEmpty) {
            final credentials = '$proxyUsername:$proxyPassword';
            final auth = Uri.parse(proxyUrl).replace(userInfo: credentials);
            return 'PROXY ${auth.host}:${auth.port}';
          }
          final proxy = Uri.parse(proxyUrl);
          return 'PROXY ${proxy.host}:${proxy.port}';
        };
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

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
        onRequest: (options, handler) {
          _log.debug('发送 HTTP 请求', {
            'method': options.method,
            'url': options.uri.toString(),
            'headers': options.headers,
          });
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log.debug('收到 HTTP 响应', {
            'statusCode': response.statusCode,
            'url': response.requestOptions.uri.toString(),
          });
          handler.next(response);
        },
        onError: (error, handler) {
          _log.error('HTTP 请求错误', {
            'url': error.requestOptions.uri.toString(),
            'method': error.requestOptions.method,
            'type': error.type.toString(),
            'message': error.message,
            'statusCode': error.response?.statusCode,
            'requestBody': error.requestOptions.data,
            'responseBody': error.response?.data,
          });
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
        _log.warning('请求超时', {'type': error.type.toString()});
        return TimeoutException();

      case DioExceptionType.connectionError:
        _log.error('网络连接错误');
        return NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        _log.error('服务器响应错误: 状态码 $statusCode', {
          'statusCode': statusCode,
          'response': error.response?.data,
        });
        if (statusCode == 401) {
          return UnauthorizedException();
        } else if (statusCode == 429) {
          return RateLimitException();
        }
        return ApiException(
          message:
              error.response?.data?['error']?['message'] ??
              'Server error occurred',
          statusCode: statusCode,
        );

      default:
        _log.error('未知错误', {'message': error.message});
        return ApiException(message: error.message ?? 'Unknown error occurred');
    }
  }
}
