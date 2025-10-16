import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_log.freezed.dart';
part 'conversation_log.g.dart';

/// 对话日志类型
enum ConversationLogType {
  userMessage,
  assistantMessage,
  systemMessage,
  functionCall,
  error,
  contextUpdate,
}

/// 对话日志条目
@freezed
class ConversationLog with _$ConversationLog {
  const factory ConversationLog({
    required String id,
    required String conversationId,
    required DateTime timestamp,
    required ConversationLogType type,
    required String content,
    String? modelName,
    String? functionName,
    Map<String, dynamic>? metadata,
    int? tokenCount,
    int? responseTime,
  }) = _ConversationLog;

  factory ConversationLog.fromJson(Map<String, dynamic> json) =>
      _$ConversationLogFromJson(json);
}
