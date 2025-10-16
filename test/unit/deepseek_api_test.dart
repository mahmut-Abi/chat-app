import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/domain/message.dart';
import 'dart:convert';

void main() {
  group('DeepSeek API 参数序列化', () {
    test('ChatCompletionRequest 应该使用 snake_case 序列化', () {
      final request = ChatCompletionRequest(
        model: 'deepseek-chat',
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        temperature: 0.7,
        maxTokens: 2048,
        topP: 1.0,
        frequencyPenalty: 0.5,
        presencePenalty: 0.3,
        stream: false,
      );

      final json = request.toJson();

      // 验证字段名使用 snake_case
      expect(json['max_tokens'], equals(2048));
      expect(json['top_p'], equals(1.0));
      expect(json['frequency_penalty'], equals(0.5));
      expect(json['presence_penalty'], equals(0.3));

      // 验证不应该包含 camelCase 字段
      expect(json.containsKey('maxTokens'), isFalse);
      expect(json.containsKey('topP'), isFalse);
      expect(json.containsKey('frequencyPenalty'), isFalse);
      expect(json.containsKey('presencePenalty'), isFalse);
    });

    test('ChatCompletionRequest JSON 应该符合 OpenAI API 格式', () {
      final request = ChatCompletionRequest(
        model: 'deepseek-chat',
        messages: [
          {'role': 'user', 'content': 'Test message'},
        ],
        temperature: 0.8,
        maxTokens: 1024,
        topP: 0.9,
        stream: false,
      );

      final jsonString = jsonEncode(request.toJson());

      // 验证 JSON 字符串包含正确的字段名
      expect(jsonString.contains('"max_tokens":'), isTrue);
      expect(jsonString.contains('"top_p":'), isTrue);
      expect(jsonString.contains('"model":"deepseek-chat"'), isTrue);

      // 验证不包含 camelCase
      expect(jsonString.contains('maxTokens'), isFalse);
      expect(jsonString.contains('topP'), isFalse);
    });

    test('Usage 应该使用 snake_case 序列化', () {
      final usage = Usage(
        promptTokens: 100,
        completionTokens: 200,
        totalTokens: 300,
      );

      final json = usage.toJson();

      expect(json['prompt_tokens'], equals(100));
      expect(json['completion_tokens'], equals(200));
      expect(json['total_tokens'], equals(300));

      expect(json.containsKey('promptTokens'), isFalse);
      expect(json.containsKey('completionTokens'), isFalse);
      expect(json.containsKey('totalTokens'), isFalse);
    });

    test('Choice 应该使用 snake_case 序列化', () {
      final choice = Choice(
        index: 0,
        message: const MessageData(role: 'assistant', content: 'Hello'),
        finishReason: 'stop',
      );

      final json = choice.toJson();

      expect(json['finish_reason'], equals('stop'));
      expect(json.containsKey('finishReason'), isFalse);
    });

    test('应该能够从 snake_case JSON 反序列化', () {
      final json = {
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'user', 'content': 'Test'},
        ],
        'temperature': 0.7,
        'max_tokens': 2048,
        'top_p': 1.0,
        'frequency_penalty': 0.0,
        'presence_penalty': 0.0,
        'stream': false,
      };

      final request = ChatCompletionRequest.fromJson(json);

      expect(request.model, equals('deepseek-chat'));
      expect(request.temperature, equals(0.7));
      expect(request.maxTokens, equals(2048));
      expect(request.topP, equals(1.0));
      expect(request.frequencyPenalty, equals(0.0));
      expect(request.presencePenalty, equals(0.0));
      expect(request.stream, equals(false));
    });
  });
}
