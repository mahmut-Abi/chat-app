import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../features/chat/domain/message.dart';
import 'dio_client.dart';

class OpenAIApiClient {
  final DioClient _dioClient;

  OpenAIApiClient(this._dioClient);

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
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
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
