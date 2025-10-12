import 'package:freezed_annotation/freezed_annotation.dart';
import 'message.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required String title,
    required List<Message> messages,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? systemPrompt,
    @Default({}) Map<String, dynamic> settings,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

@freezed
class ModelConfig with _$ModelConfig {
  const factory ModelConfig({
    required String model,
    @Default(0.7) double temperature,
    @Default(2048) int maxTokens,
    @Default(1.0) double topP,
    @Default(0.0) double frequencyPenalty,
    @Default(0.0) double presencePenalty,
  }) = _ModelConfig;

  factory ModelConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelConfigFromJson(json);
}
