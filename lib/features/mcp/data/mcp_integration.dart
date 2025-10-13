import '../domain/mcp_config.dart';
import 'mcp_repository.dart';
import '../../chat/domain/message.dart';
import '../../chat/domain/conversation.dart';

/// MCP 与聊天功能集成
class McpIntegration {
  final McpRepository _repository;

  McpIntegration(this._repository);

  /// 为会话添加 MCP 上下文
  Future<Conversation> enrichConversationWithMcp(
    Conversation conversation,
    String mcpConfigId,
  ) async {
    final client = _repository.getClient(mcpConfigId);
    if (client == null) {
      throw Exception('MCP 客户端未连接');
    }

    // 获取上下文
    final context = await client.getContext(conversation.id);

    if (context == null) {
      return conversation;
    }

    // 将上下文添加到 system prompt
    final enrichedSystemPrompt = _buildEnrichedSystemPrompt(
      conversation.systemPrompt,
      context,
    );

    return conversation.copyWith(systemPrompt: enrichedSystemPrompt);
  }

  /// 同步消息到 MCP 服务器
  Future<void> syncMessageToMcp(
    Message message,
    String conversationId,
    String mcpConfigId,
  ) async {
    final client = _repository.getClient(mcpConfigId);
    if (client == null) return;

    try {
      await client.pushContext(conversationId, {
        'type': 'message',
        'role': message.role.toString(),
        'content': message.content,
        'timestamp': message.timestamp.toIso8601String(),
      });
    } catch (e) {
      // 记录错误但不影响主流程
      // debugPrint('同步消息到 MCP 失败: $e');
    }
  }

  /// 构建带 MCP 上下文的 system prompt
  String _buildEnrichedSystemPrompt(
    String? originalPrompt,
    Map<String, dynamic> mcpContext,
  ) {
    final buffer = StringBuffer();

    if (originalPrompt != null && originalPrompt.isNotEmpty) {
      buffer.writeln(originalPrompt);
      buffer.writeln();
    }

    buffer.writeln('--- MCP 上下文 ---');

    // 添加 MCP 提供的上下文信息
    mcpContext.forEach((key, value) {
      buffer.writeln('$key: $value');
    });

    return buffer.toString();
  }

  /// 获取可用的 MCP 配置
  Future<List<McpConfig>> getAvailableMcpConfigs() async {
    final configs = await _repository.getAllConfigs();
    return configs.where((c) => c.enabled).toList();
  }

  /// 检查 MCP 连接状态
  McpConnectionStatus? checkConnectionStatus(String configId) {
    return _repository.getConnectionStatus(configId);
  }
}
