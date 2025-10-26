import 'package:dio/dio.dart';
import '../services/log_service.dart';

/// 网络请求配置
class NetworkConfig {
  /// 超时时间（毫秒）
  static const int defaultConnectTimeout = 30000; // 30秒
  static const int defaultReceiveTimeout = 60000; // 60秒
  static const int defaultSendTimeout = 60000;    // 60秒

  /// 重试配置
  static const int maxRetries = 3;
  static const int initialRetryDelay = 1000; // 1秒
  static const int maxRetryDelay = 10000;    // 10秒

  /// 不需要重试的初始化名单
  static final Set<int> nonRetryableStatusCodes = {
    400, // Bad Request
    401, // Unauthorized
    403, // Forbidden
    404, // Not Found
    422, // Unprocessable Entity
  };

  /// 前需要重试的初始化名单
  static final Set<int> retryableStatusCodes = {
    408, // Request Timeout
    429, // Too Many Requests
    500, // Internal Server Error
    502, // Bad Gateway
    503, // Service Unavailable
    504, // Gateway Timeout
  };
}

/// Dio 客户端配置上下文
class DioConfig {
  static BaseOptions createBaseOptions(String baseUrl) {
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(
        milliseconds: NetworkConfig.defaultConnectTimeout,
      ),
      receiveTimeout: const Duration(
        milliseconds: NetworkConfig.defaultReceiveTimeout,
      ),
      sendTimeout: const Duration(
        milliseconds: NetworkConfig.defaultSendTimeout,
      ),
      validateStatus: (status) => status != null && status < 500,
      contentType: 'application/json',
    );
  }
}

/// 重试拦截器
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;
  final Function(String)? onLog;
  final _log = LogService();

  RetryInterceptor({
    required this.dio,
    this.retries = NetworkConfig.maxRetries,
    List<Duration>? retryDelays,
    this.onLog,
  }) : retryDelays = retryDelays ??
      List.generate(
        NetworkConfig.maxRetries,
        (i) => Duration(
          milliseconds: NetworkConfig.initialRetryDelay * (i + 1),
        ),
      );

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err) || err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }

    for (int i = 0; i < retries; i++) {
      try {
        await Future.delayed(retryDelays[i]);
        _log.info('API 重试', {'attempt': i + 1, 'path': err.requestOptions.path});
        onLog?.call('正在重试次数: ${i + 1}/$retries');

        final options = err.requestOptions;
        options.extra['retried'] = true;

        final response = await dio.request<dynamic>(
          options.path,
          cancelToken: options.cancelToken,
          data: options.data,
          onReceiveProgress: options.onReceiveProgress,
          onSendProgress: options.onSendProgress,
          queryParameters: options.queryParameters,
          options: Options(
            method: options.method,
            sendTimeout: options.sendTimeout,
            receiveTimeout: options.receiveTimeout,
          ),
        );

        return handler.resolve(response);
      } catch (e) {
        if (i == retries - 1) {
          _log.error('余下重试次数了', e);
          return handler.next(err);
        }
      }
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      return NetworkConfig.retryableStatusCodes.contains(statusCode);
    }

    return false;
  }
}
