import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../features/chat/domain/message.dart';
import 'dio_client.dart';

class ApiTestResult {
  final bool success;
  final String message;

  ApiTestResult({required this.success, required this.message});
}

class OpenAIApiClient {
  final DioClient _dioClient;

  OpenAIApiClient(this._dioClient);

  // 测试 API 连接
  Future<ApiTestResult> testConnection() async {
    try {
      final response = await _dioClient.dio.get(
        '/models',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final models = (response.data['data'] as List).length;
        return ApiTestResult(success: true, message: '连接成功!找到 $models 个可用模型');
      } else {
        return ApiTestResult(
          success: false,
          message: '连接失败:状态码 ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return ApiTestResult(success: false, message: _getDioErrorMessage(e));
    } catch (e) {
      return ApiTestResult(success: false, message: '连接失败:${e.toString()}');
    }
  }

  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时,请检查网络或代理设置';
      case DioExceptionType.sendTimeout:
        return '发送超时,请检查网络连接';
      case DioExceptionType.receiveTimeout:
        return '接收超时,服务器响应过慢';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'API Key 无效或已过期';
        } else if (statusCode == 403) {
          return '访问被拒绝,请检查 API Key 权限';
        } else if (statusCode == 404) {
          return 'API 端点不存在,请检查 Base URL';
        } else if (statusCode == 429) {
          return 'API 请求频率超限,请稍后重试';
        } else if (statusCode == 500) {
          return '服务器内部错误';
        }
        return 'HTTP 错误:$statusCode';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.unknown:
        if (e.error.toString().contains('SocketException')) {
          return '网络连接失败,请检查网络或代理设置';
        }
        return '未知错误:${e.error}';
      default:
        return '连接失败:${e.message}';
    }
  }

  Future<ChatCompletionResponse> createChatCompletion(
    ChatCompletionRequest request,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/chat/completions',
        data: request.toJson(),
      );

      return ChatCompletionResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Stream<String> createChatCompletionStream(
    ChatCompletionRequest request,
  ) async* {
    try {
      final response = await _dioClient.dio.post(
        '/chat/completions',
        data: request.copyWith(stream: true).toJson(),
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;

      await for (final chunk in stream) {
        final lines = utf8.decode(chunk).split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);

            if (data.trim() == '[DONE]') {
              return;
            }

            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'];

              if (content != null && content.isNotEmpty) {
                yield content as String;
              }
            } catch (e) {
              // Skip invalid JSON chunks
              continue;
            }
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _dioClient.dio.get('/models');
      final models = (response.data['data'] as List)
          .map((model) => model['id'] as String)
          .where((id) => id.contains('gpt'))
          .toList();

      return models;
    } catch (e) {
      // Return default models if API call fails
      return [
        'gpt-4',
        'gpt-4-turbo-preview',
        'gpt-3.5-turbo',
        'gpt-3.5-turbo-16k',
      ];
    }
  }
}
