import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_log.freezed.dart';
part 'agent_log.g.dart';

/// Agent 日志类型
enum AgentLogType {
  taskStarted,
  taskCompleted,
  taskFailed,
  toolExecution,
  decisionMaking,
  stateUpdate,
  error,
}

/// Agent 日志条目
@freezed
class AgentLog with _$AgentLog {
  const factory AgentLog({
    required String id,
    required String agentId,
    required String agentName,
    required DateTime timestamp,
    required AgentLogType type,
    required String message,
    String? taskId,
    String? toolName,
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    String? decision,
    String? errorMessage,
    int? executionTime,
  }) = _AgentLog;

  factory AgentLog.fromJson(Map<String, dynamic> json) =>
      _$AgentLogFromJson(json);
}
