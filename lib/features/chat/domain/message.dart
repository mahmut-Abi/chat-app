import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

// ignore_for_file: non_abstract_class_inherits_abstract_member

enum MessageRole { system, user, assistant }

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required MessageRole role,
    required String content,
    required DateTime timestamp,
    @Default(false) bool isStreaming,
    @Default(false) bool hasError,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    int? tokenCount,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

@freezed
class ChatCompletionRequest with _$ChatCompletionRequest {
  const factory ChatCompletionRequest({
    required String model,
    required List<Map<String, String>> messages,
    @Default(0.7) double temperature,
    @Default(2048) int maxTokens,
    @Default(1.0) double topP,
    @Default(0.0) double frequencyPenalty,
    @Default(0.0) double presencePenalty,
    @Default(false) bool stream,
  }) = _ChatCompletionRequest;

  factory ChatCompletionRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatCompletionRequestFromJson(json);
}

@freezed
class ChatCompletionResponse with _$ChatCompletionResponse {
  const factory ChatCompletionResponse({
    required String id,
    required String model,
    required List<Choice> choices,
    Usage? usage,
  }) = _ChatCompletionResponse;

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatCompletionResponseFromJson(json);
}

@freezed
class Choice with _$Choice {
  const factory Choice({
    required int index,
    required MessageData message,
    String? finishReason,
  }) = _Choice;

  factory Choice.fromJson(Map<String, dynamic> json) => _$ChoiceFromJson(json);
}

@freezed
class MessageData with _$MessageData {
  const factory MessageData({required String role, required String content}) =
      _MessageData;

  factory MessageData.fromJson(Map<String, dynamic> json) =>
      _$MessageDataFromJson(json);
}

@freezed
class Usage with _$Usage {
  const factory Usage({
    required int promptTokens,
    required int completionTokens,
    required int totalTokens,
  }) = _Usage;

  factory Usage.fromJson(Map<String, dynamic> json) => _$UsageFromJson(json);
}
