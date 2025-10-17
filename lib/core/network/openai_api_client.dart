import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../features/chat/domain/message.dart';
import 'dio_client.dart';
import '../services/log_service.dart';

class ApiTestResult {
  final bool success;
  final String message;

  ApiTestResult({required this.success, required this.message});
}

class OpenAIApiClient {
  final DioClient _dioClient;
  final LogService _log = LogService();
  final String? _provider;

  OpenAIApiClient(this._dioClient, [this._provider]);

  // 根据 API 提供商过滤请求参数
  Map<String, dynamic> _filterRequestParams(
    Map<String, dynamic> params,
    String provider,
  ) {
    final filtered = Map<String, dynamic>.from(params);

    // DeepSeek 不支持的参数
    if (provider.toLowerCase().contains('deepseek')) {
      // DeepSeek 支持的基本参数: model, messages, temperature, max_tokens, top_p, stream
      // 不支持: frequency_penalty, presence_penalty
      filtered.remove('frequency_penalty');
      filtered.remove('presence_penalty');

      // 限制 temperature 范围 (0-2)
      if (filtered['temperature'] != null) {
        final temp = filtered['temperature'] as double;
        filtered['temperature'] = temp.clamp(0.0, 2.0);
      }

      // 确保 max_tokens 在合理范围内
      if (filtered['max_tokens'] != null) {
        final maxTokens = filtered['max_tokens'] as int;
        // DeepSeek 的 max_tokens 范围通常是 1-8192
        filtered['max_tokens'] = maxTokens.clamp(1, 8192);
      }

      // 确保 top_p 在 0-1 范围内
      if (filtered['top_p'] != null) {
        final topP = filtered['top_p'] as double;
        filtered['top_p'] = topP.clamp(0.0, 1.0);
      }

      _log.debug('DeepSeek 参数过滤', {
        'original': params.keys.toList(),
        'filtered': filtered.keys.toList(),
      });

      _log.info('DeepSeek 过滤后的完整请求', {'filteredRequest': jsonEncode(filtered)});
    }

    return filtered;
  }

  // 测试 API 连接
  Future<ApiTestResult> testConnection() async {
    _log.info('开始测试 API 连接');
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
        _log.info('API 连接测试成功', {'modelsCount': models});
        _log.info('API 连接测试成功', {'modelsCount': models});
        return ApiTestResult(success: true, message: '连接成功!找到 $models 个可用模型');
      } else {
        _log.warning('API 连接测试失败', {'statusCode': response.statusCode});
        return ApiTestResult(
          success: false,
          message: '连接失败:状态码 ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _log.error('API 连接测试异常', {'error': e.toString()});
      return ApiTestResult(success: false, message: _getDioErrorMessage(e));
    } catch (e) {
      _log.error('API 连接测试未知错误', {'error': e.toString()});
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
    _log.debug('创建聊天完成请求', {
      'model': request.model,
      'messagesCount': request.messages.length,
    });

    try {
      var requestData = request.toJson();

      _log.info('原始请求数据', {
        'provider': _provider ?? 'unknown',
        'requestData': jsonEncode(requestData),
      });

      // 如果指定了 provider，过滤不支持的参数
      if (_provider != null && _provider.isNotEmpty) {
        requestData = _filterRequestParams(requestData, _provider);
      }

      _log.debug('发送聊天完成请求', {
        'provider': _provider,
        'requestData': jsonEncode(requestData),
      });

      final response = await _dioClient.dio.post(
        '/chat/completions',
        data: requestData,
      );

      _log.debug('聊天完成响应成功', {
        'statusCode': response.statusCode,
        'hasChoices': response.data['choices'] != null,
      });

      return ChatCompletionResponse.fromJson(response.data);
    } catch (e, stackTrace) {
      if (e is DioException && e.response != null) {
        _log.error('聊天完成请求失败', {
          'error': e.toString(),
          'statusCode': e.response?.statusCode,
          'responseData': jsonEncode(e.response?.data),
          'requestData': e.requestOptions.data != null
              ? jsonEncode(e.requestOptions.data)
              : 'null',
        });

        // 如果是400错误,提供更详细的诊断
        if (e.response?.statusCode == 400) {
          _log.error('400错误诊断', {
            'errorType': e.response?.data?['error']?['type'],
            'errorMessage': e.response?.data?['error']?['message'],
            'errorCode': e.response?.data?['error']?['code'],
            'requestModel': (e.requestOptions.data as Map?)?['model'],
            'messagesCount':
                ((e.requestOptions.data as Map?)?['messages'] as List?)?.length,
          });

          // 检查是否有图片消息
          final messages =
              (e.requestOptions.data as Map?)?['messages'] as List?;
          if (messages != null) {
            for (var i = 0; i < messages.length; i++) {
              final msg = messages[i];
              final content = msg['content'];
              if (content is List) {
                final hasImage = content.any(
                  (part) => part['type'] == 'image_url',
                );
                if (hasImage) {
                  _log.error('消息$i包含图片', {
                    'partsCount': content.length,
                    'contentPreview': content.map((p) => p['type']).toList(),
                  });
                }
              }
            }
          }
        }
      } else {
        _log.error('聊天完成请求失败', {'error': e.toString()}, stackTrace);
      }
      rethrow;
    }
  }

  Stream<String> createChatCompletionStream(
    ChatCompletionRequest request,
  ) async* {
    _log.debug('创建流式聊天完成请求', {
      'model': request.model,
      'messagesCount': request.messages.length,
    });

    try {
      var requestData = request.copyWith(stream: true).toJson();

      _log.info('流式请求原始数据', {
        'model': requestData['model'],
        'messagesCount': (requestData['messages'] as List?)?.length ?? 0,
        'hasMultimodal':
            (requestData['messages'] as List?)?.any((msg) {
              final content = msg['content'];
              return content is List;
            }) ??
            false,
      });

      // 如果指定了 provider，过滤不支持的参数
      if (_provider != null && _provider.isNotEmpty) {
        requestData = _filterRequestParams(requestData, _provider);
      }

      _log.info('发送流式请求数据', {
        'provider': _provider ?? 'openai',
        'url': '/chat/completions',
        'stream': true,
      });

      final response = await _dioClient.dio.post(
        '/chat/completions',
        data: requestData,
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
                _log.debug('收到流式响应块', {'contentLength': content.length});
                yield content as String;
              }
            } catch (e) {
              // Skip invalid JSON chunks
              _log.debug('跳过无效的 JSON 块', {'error': e.toString()});
              continue;
            }
          }
        }
      }
    } catch (e) {
      _log.error('流式请求异常', {
        'error': e.toString(),
        'type': e.runtimeType.toString(),
      });
      rethrow;
    }
  }

  Future<List<String>> getAvailableModels() async {
    _log.debug('获取可用模型列表');
    try {
      final response = await _dioClient.dio.get('/models');
      final models =
          (response.data['data'] as List)
              .map((model) => model['id'] as String)
              .toList()
            ..sort(); // 按字母顺序排列

      _log.info('成功获取模型列表', {'count': models.length});
      return models;
    } catch (e) {
      _log.warning('获取模型列表失败，使用默认列表', {'error': e.toString()});
      // API 调用失败时返回空列表，让用户手动输入
      return [];
    }
  }
}
