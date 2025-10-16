import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_log.freezed.dart';
part 'mcp_log.g.dart';

/// MCP 日志类型
enum McpLogType {
  toolCall,
  toolResponse,
  connectionEstablished,
  connectionFailed,
  error,
  configUpdate,
}

/// MCP 日志条目
@freezed
class McpLog with _$McpLog {
  const factory McpLog({
    required String id,
    required String mcpId,
    required String mcpName,
    required DateTime timestamp,
    required McpLogType type,
    required String message,
    String? toolName,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? response,
    String? errorMessage,
    int? executionTime,
  }) = _McpLog;

  factory McpLog.fromJson(Map<String, dynamic> json) => _$McpLogFromJson(json);
}
