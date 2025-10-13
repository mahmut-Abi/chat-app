import 'package:json_annotation/json_annotation.dart';

part 'token_record.g.dart';

/// Token 消耗记录
@JsonSerializable()
class TokenRecord {
  final String id;
  final String conversationId;
  final String conversationTitle;
  final String messageId;
  final String model;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final DateTime timestamp;
  final String? messagePreview; // 消息预览（前50个字符）

  TokenRecord({
    required this.id,
    required this.conversationId,
    required this.conversationTitle,
    required this.messageId,
    required this.model,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.timestamp,
    this.messagePreview,
  });

  factory TokenRecord.fromJson(Map<String, dynamic> json) =>
      _$TokenRecordFromJson(json);

  Map<String, dynamic> toJson() => _$TokenRecordToJson(this);
}
