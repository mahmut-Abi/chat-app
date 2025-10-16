import 'package:uuid/uuid.dart';
import '../../../core/storage/storage_service.dart';
import '../domain/conversation_log.dart';
import '../domain/mcp_log.dart';
import '../domain/agent_log.dart';

/// 日志仓库
class LogsRepository {
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  static const String _conversationLogsKey = 'conversation_logs';
  static const String _mcpLogsKey = 'mcp_logs';
  static const String _agentLogsKey = 'agent_logs';

  LogsRepository(this._storage);

  // ========== 对话日志 ==========

  /// 记录对话日志
  Future<ConversationLog> logConversation({
    required String conversationId,
    required ConversationLogType type,
    required String content,
    String? modelName,
    String? functionName,
    Map<String, dynamic>? metadata,
    int? tokenCount,
    int? responseTime,
  }) async {
    final log = ConversationLog(
      id: _uuid.v4(),
      conversationId: conversationId,
      timestamp: DateTime.now(),
      type: type,
      content: content,
      modelName: modelName,
      functionName: functionName,
      metadata: metadata,
      tokenCount: tokenCount,
      responseTime: responseTime,
    );

    final logs = await getConversationLogs();
    logs.add(log);
    await _saveConversationLogs(logs);

    return log;
  }

  /// 获取所有对话日志
  Future<List<ConversationLog>> getConversationLogs({
    String? conversationId,
    ConversationLogType? type,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final data = await _storage.getString(_conversationLogsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = _storage.decodeJson(data);
    var logs = jsonList
        .map((json) => ConversationLog.fromJson(json as Map<String, dynamic>))
        .toList();

    // 应用过滤
    if (conversationId != null) {
      logs = logs
          .where((log) => log.conversationId == conversationId)
          .toList();
    }
    if (type != null) {
      logs = logs.where((log) => log.type == type).toList();
    }
    if (startTime != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startTime)).toList();
    }
    if (endTime != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endTime)).toList();
    }

    // 按时间倒序排列
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// 保存对话日志
  Future<void> _saveConversationLogs(List<ConversationLog> logs) async {
    final jsonList = logs.map((log) => log.toJson()).toList();
    await _storage.saveString(
      _conversationLogsKey,
      _storage.encodeJson(jsonList),
    );
  }

  /// 清空对话日志
  Future<void> clearConversationLogs() async {
    await _storage.remove(_conversationLogsKey);
  }

  // ========== MCP 日志 ==========

  /// 记录 MCP 日志
  Future<McpLog> logMcp({
    required String mcpId,
    required String mcpName,
    required McpLogType type,
    required String message,
    String? toolName,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? response,
    String? errorMessage,
    int? executionTime,
  }) async {
    final log = McpLog(
      id: _uuid.v4(),
      mcpId: mcpId,
      mcpName: mcpName,
      timestamp: DateTime.now(),
      type: type,
      message: message,
      toolName: toolName,
      parameters: parameters,
      response: response,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );

    final logs = await getMcpLogs();
    logs.add(log);
    await _saveMcpLogs(logs);

    return log;
  }

  /// 获取所有 MCP 日志
  Future<List<McpLog>> getMcpLogs({
    String? mcpId,
    McpLogType? type,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final data = await _storage.getString(_mcpLogsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = _storage.decodeJson(data);
    var logs = jsonList
        .map((json) => McpLog.fromJson(json as Map<String, dynamic>))
        .toList();

    // 应用过滤
    if (mcpId != null) {
      logs = logs.where((log) => log.mcpId == mcpId).toList();
    }
    if (type != null) {
      logs = logs.where((log) => log.type == type).toList();
    }
    if (startTime != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startTime)).toList();
    }
    if (endTime != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endTime)).toList();
    }

    // 按时间倒序排列
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// 保存 MCP 日志
  Future<void> _saveMcpLogs(List<McpLog> logs) async {
    final jsonList = logs.map((log) => log.toJson()).toList();
    await _storage.saveString(_mcpLogsKey, _storage.encodeJson(jsonList));
  }

  /// 清空 MCP 日志
  Future<void> clearMcpLogs() async {
    await _storage.remove(_mcpLogsKey);
  }

  // ========== Agent 日志 ==========

  /// 记录 Agent 日志
  Future<AgentLog> logAgent({
    required String agentId,
    required String agentName,
    required AgentLogType type,
    required String message,
    String? taskId,
    String? toolName,
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    String? decision,
    String? errorMessage,
    int? executionTime,
  }) async {
    final log = AgentLog(
      id: _uuid.v4(),
      agentId: agentId,
      agentName: agentName,
      timestamp: DateTime.now(),
      type: type,
      message: message,
      taskId: taskId,
      toolName: toolName,
      input: input,
      output: output,
      decision: decision,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );

    final logs = await getAgentLogs();
    logs.add(log);
    await _saveAgentLogs(logs);

    return log;
  }

  /// 获取所有 Agent 日志
  Future<List<AgentLog>> getAgentLogs({
    String? agentId,
    AgentLogType? type,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final data = await _storage.getString(_agentLogsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = _storage.decodeJson(data);
    var logs = jsonList
        .map((json) => AgentLog.fromJson(json as Map<String, dynamic>))
        .toList();

    // 应用过滤
    if (agentId != null) {
      logs = logs.where((log) => log.agentId == agentId).toList();
    }
    if (type != null) {
      logs = logs.where((log) => log.type == type).toList();
    }
    if (startTime != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startTime)).toList();
    }
    if (endTime != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endTime)).toList();
    }

    // 按时间倒序排列
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// 保存 Agent 日志
  Future<void> _saveAgentLogs(List<AgentLog> logs) async {
    final jsonList = logs.map((log) => log.toJson()).toList();
    await _storage.saveString(_agentLogsKey, _storage.encodeJson(jsonList));
  }

  /// 清空 Agent 日志
  Future<void> clearAgentLogs() async {
    await _storage.remove(_agentLogsKey);
  }

  /// 清空所有日志
  Future<void> clearAllLogs() async {
    await Future.wait([
      clearConversationLogs(),
      clearMcpLogs(),
      clearAgentLogs(),
    ]);
  }
}
