import '../domain/mcp_config.dart';
import '../../../core/services/log_service.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'dart:io';

/// MCP 健康检查策略枚举
enum HealthCheckStrategy {
  /// 标准 HTTP GET 请求到 /health 端点
  standard,

  /// 对多个端点进行探测（自动发现）
  probe,

  /// 通过工具列表端点检查
  toolsListing,

  /// 只检查网络连通性
  networkOnly,

  /// 自定义检查（由使用者提供）
  custom,

  /// 禁用健康检查
  disabled,
}

/// 健康检查结果
class HealthCheckResult {
  final bool success;
  final String message;
  final Duration duration;
  final HealthCheckStrategy strategy;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  final String? detectedEndpoint;

  HealthCheckResult({
    required this.success,
    required this.message,
    required this.duration,
    required this.strategy,
    this.details,
    DateTime? timestamp,
    this.detectedEndpoint,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'HealthCheckResult(success=\$success, strategy=\$strategy, duration=\${duration.inMilliseconds}ms, message=\$message)';
}

/// MCP 健康检查执行器基类
abstract class HealthCheckExecutor {
  Future<HealthCheckResult> execute(
    String endpoint,
    Map<String, String>? headers,
  );
}

/// 标准 HTTP 健康检查
class StandardHealthCheckExecutor implements HealthCheckExecutor {
  final Dio dio;
  final LogService log = LogService();
  final String healthPath;

  StandardHealthCheckExecutor({Dio? dio, this.healthPath = '/health'})
    : dio = dio ?? Dio();

  @override
  Future<HealthCheckResult> execute(
    String endpoint,
    Map<String, String>? headers,
  ) async {
    final startTime = DateTime.now();
    try {
      final url = _buildUrl(endpoint, healthPath);
      log.debug('执行标准健康检查', {'url': url});

      final response = await dio
          .get(
            url,
            options: Options(
              headers: headers,
              receiveTimeout: const Duration(seconds: 5),
              validateStatus: (status) => status != null && status < 500,
            ),
          )
          .timeout(const Duration(seconds: 5));

      final duration = DateTime.now().difference(startTime);
      final success = response.statusCode == 200;

      return HealthCheckResult(
        success: success,
        message: success ? '健康检查通过' : 'HTTP \${response.statusCode}',
        duration: duration,
        strategy: HealthCheckStrategy.standard,
        details: {
          'statusCode': response.statusCode,
          'contentLength': response.data?.toString().length ?? 0,
        },
        detectedEndpoint: healthPath,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      return HealthCheckResult(
        success: false,
        message: '健康检查失败: \${e.toString()}',
        duration: duration,
        strategy: HealthCheckStrategy.standard,
      );
    }
  }

  String _buildUrl(String endpoint, String path) {
    try {
      final uri = Uri.parse(endpoint);
      return uri.replace(path: path).toString();
    } catch (e) {
      return '\$endpoint\$path';
    }
  }
}

/// 端点探测健康检查
class ProbeHealthCheckExecutor implements HealthCheckExecutor {
  final Dio dio;
  final LogService log = LogService();
  final List<String> probePaths;

  ProbeHealthCheckExecutor({
    Dio? dio,
    this.probePaths = const [
      '/health',
      '/api/health',
      '/ping',
      '/api/v1/health',
      '/api/kubernetes/sse',
      '/status',
      '/healthz',
      '/ready',
      '/',
    ],
  }) : dio = dio ?? Dio();

  @override
  Future<HealthCheckResult> execute(
    String endpoint,
    Map<String, String>? headers,
  ) async {
    final startTime = DateTime.now();
    String? successfulPath;
    int? lastStatusCode;

    try {
      final baseUrl = _extractBaseUrl(endpoint);

      for (final path in probePaths) {
        try {
          log.debug('探测端点', {'path': path});
          final url = '\$baseUrl\$path';

          final response = await dio
              .get(
                url,
                options: Options(
                  headers: headers,
                  receiveTimeout: const Duration(seconds: 3),
                  validateStatus: (status) => status != null && status < 500,
                ),
              )
              .timeout(const Duration(seconds: 3));

          lastStatusCode = response.statusCode;
          if (response.statusCode == 200 || response.statusCode == 101) {
            successfulPath = path;
            log.info('探测到有效端点', {
              'path': path,
              'statusCode': response.statusCode,
            });
            break;
          }
        } catch (e) {
          log.debug('端点探测失败', {'path': path, 'error': e.toString()});
          continue;
        }
      }

      final duration = DateTime.now().difference(startTime);

      if (successfulPath != null) {
        return HealthCheckResult(
          success: true,
          message: '探测到有效端点: \$successfulPath',
          duration: duration,
          strategy: HealthCheckStrategy.probe,
          details: {
            'probeCount': probePaths.length,
            'successfulPath': successfulPath,
          },
          detectedEndpoint: successfulPath,
        );
      } else {
        return HealthCheckResult(
          success: false,
          message: '未找到有效的健康检查端点 (尝试了\${probePaths.length}个)',
          duration: duration,
          strategy: HealthCheckStrategy.probe,
          details: {
            'probeCount': probePaths.length,
            'lastStatusCode': lastStatusCode,
          },
        );
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      return HealthCheckResult(
        success: false,
        message: '端点探测异常: \${e.toString()}',
        duration: duration,
        strategy: HealthCheckStrategy.probe,
      );
    }
  }

  String _extractBaseUrl(String endpoint) {
    try {
      final uri = Uri.parse(endpoint);
      final port = uri.port;
      final portStr = (port == 80 || port == 443 || port == 0) ? '' : ':\$port';
      return '\${uri.scheme}://\${uri.host}\$portStr';
    } catch (e) {
      return endpoint;
    }
  }
}

/// 工具列表健康检查
class ToolsListingHealthCheckExecutor implements HealthCheckExecutor {
  final Dio dio;
  final LogService log = LogService();

  ToolsListingHealthCheckExecutor({Dio? dio}) : dio = dio ?? Dio();

  @override
  Future<HealthCheckResult> execute(
    String endpoint,
    Map<String, String>? headers,
  ) async {
    final startTime = DateTime.now();
    try {
      log.debug('通过工具列表检查健康状态', {'endpoint': endpoint});

      final response = await dio
          .get(
            '\$endpoint/tools',
            options: Options(
              headers: headers,
              receiveTimeout: const Duration(seconds: 5),
              validateStatus: (status) => status != null && status < 500,
            ),
          )
          .timeout(const Duration(seconds: 5));

      final duration = DateTime.now().difference(startTime);
      final success = response.statusCode == 200;

      if (success) {
        int toolCount = 0;
        if (response.data is List) {
          toolCount = (response.data as List).length;
        } else if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          if (map['tools'] is List) {
            toolCount = (map['tools'] as List).length;
          }
        }

        return HealthCheckResult(
          success: true,
          message: '健康检查通过，获取到 \$toolCount 个工具',
          duration: duration,
          strategy: HealthCheckStrategy.toolsListing,
          details: {'toolCount': toolCount},
          detectedEndpoint: '/tools',
        );
      } else {
        return HealthCheckResult(
          success: false,
          message: '工具列表端点返回 HTTP \${response.statusCode}',
          duration: duration,
          strategy: HealthCheckStrategy.toolsListing,
          details: {'statusCode': response.statusCode},
        );
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      return HealthCheckResult(
        success: false,
        message: '工具列表检查失败: \${e.toString()}',
        duration: duration,
        strategy: HealthCheckStrategy.toolsListing,
      );
    }
  }
}

/// 网络连通性检查
class NetworkOnlyHealthCheckExecutor implements HealthCheckExecutor {
  final LogService log = LogService();

  @override
  Future<HealthCheckResult> execute(
    String endpoint,
    Map<String, String>? headers,
  ) async {
    final startTime = DateTime.now();
    try {
      log.debug('检查网络连通性', {'endpoint': endpoint});

      final uri = Uri.parse(endpoint);
      final socket = await Socket.connect(
        uri.host,
        uri.port == 0 ? (uri.scheme == 'https' ? 443 : 80) : uri.port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();

      final duration = DateTime.now().difference(startTime);
      return HealthCheckResult(
        success: true,
        message: '网络连接成功',
        duration: duration,
        strategy: HealthCheckStrategy.networkOnly,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      return HealthCheckResult(
        success: false,
        message: '网络连接失败: \${e.toString()}',
        duration: duration,
        strategy: HealthCheckStrategy.networkOnly,
      );
    }
  }
}
