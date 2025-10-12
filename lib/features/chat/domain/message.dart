import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'message.g.dart';

enum MessageRole { system, user, assistant }

@JsonSerializable()
class Message extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final bool hasError;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final int? tokenCount;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.hasError = false,
    this.errorMessage,
    this.metadata,
    this.tokenCount,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    bool? hasError,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    int? tokenCount,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      tokenCount: tokenCount ?? this.tokenCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        content,
        timestamp,
        isStreaming,
        hasError,
        errorMessage,
        metadata,
        tokenCount,
      ];
}

@JsonSerializable()
class ChatCompletionRequest {
  final String model;
  final List<Map<String, String>> messages;
  final double temperature;
  final int maxTokens;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final bool stream;

  const ChatCompletionRequest({
    required this.model,
    required this.messages,
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.stream = false,
  });

  factory ChatCompletionRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatCompletionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChatCompletionRequestToJson(this);

  ChatCompletionRequest copyWith({
    String? model,
    List<Map<String, String>>? messages,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    bool? stream,
  }) {
    return ChatCompletionRequest(
      model: model ?? this.model,
      messages: messages ?? this.messages,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      stream: stream ?? this.stream,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChatCompletionResponse {
  final String id;
  final String model;
  final List<Choice> choices;
  final Usage? usage;

  const ChatCompletionResponse({
    required this.id,
    required this.model,
    required this.choices,
    this.usage,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatCompletionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChatCompletionResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Choice {
  final int index;
  final MessageData message;
  final String? finishReason;

  const Choice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory Choice.fromJson(Map<String, dynamic> json) => _$ChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$ChoiceToJson(this);
}

@JsonSerializable()
class MessageData {
  final String role;
  final String content;

  const MessageData({
    required this.role,
    required this.content,
  });

  factory MessageData.fromJson(Map<String, dynamic> json) =>
      _$MessageDataFromJson(json);

  Map<String, dynamic> toJson() => _$MessageDataToJson(this);
}

@JsonSerializable()
class Usage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) => _$UsageFromJson(json);

  Map<String, dynamic> toJson() => _$UsageToJson(this);
}
