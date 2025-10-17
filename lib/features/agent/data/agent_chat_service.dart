import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../chat/domain/message.dart';
import '../../chat/domain/conversation.dart';
import '../../chat/domain/function_call.dart';
import 'enhanced_agent_integration.dart';
import '../domain/agent_tool.dart';
import '../../../core/network/openai_api_client.dart';
import '../../../core/services/log_service.dart';

/// Agent 聊天服务
/// 负责处理带 Agent 的消息发送和工具调用
class AgentChatService {
  final OpenAIApiClient _apiClient;
  final EnhancedAgentIntegration _agentIntegration;
  final _uuid = const Uuid();
  final _log = LogService();

  AgentChatService(
    this._apiClient,
    this._agentIntegration,
  );

  /// 使用 Agent 发送消息
  Future<Message> sendMessageWithAgent({
    required String conversationId,
    required String content,
    required ModelConfig config,
    required AgentConfig agent,
    List<Message>? conversationHistory,
  }) async {
    try {
      _log.info('使用 Agent 发送消息', {
        'conversationId': conversationId,
        'agentId': agent.id,
        'agentName': agent.name,
      });

      // 获取 Agent 的工具定义
      final toolDefinitions =
          await _agentIntegration.getAgentToolDefinitions(agent);

      // 构建消息列表
      final messages = _buildMessages(agent, conversationHistory, content);

      // 创建请求
      final request = ChatCompletionRequest(
        model: config.model,
        messages: messages,
        temperature: config.temperature,
        maxTokens: config.maxTokens,
        topP: config.topP,
        frequencyPenalty: config.frequencyPenalty,
        presencePenalty: config.presencePenalty,
        stream: false,
        tools: toolDefinitions.isNotEmpty ? toolDefinitions : null,
      );

      // 发送请求并处理工具调用
      final result = await _sendRequestWithToolCalls(
        request,
        agent,
        messages,
        config,
      );

      return Message(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: result['content'] as String,
        timestamp: DateTime.now(),
        tokenCount: result['tokenCount'] as int?,
        toolCalls: result['toolCalls'] as List<ToolCall>?,
        metadata: result['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      _log.error('Agent 消息发送失败', {
        'conversationId': conversationId,
        'error': e.toString(),
      });

      return Message(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        hasError: true,
        errorMessage: '发送失败: ${e.toString()}',
      );
    }
  }

  /// 构建消息列表
  List<Map<String, dynamic>> _buildMessages(
    AgentConfig agent,
    List<Message>? conversationHistory,
    String content,
  ) {
    final messages = <Map<String, dynamic>>[];

    // 添加 system prompt
    if (agent.systemPrompt != null && agent.systemPrompt!.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': agent.systemPrompt!,
      });
    }

    // 添加历史消息
    if (conversationHistory != null) {
      for (final msg in conversationHistory) {
        final msgData = <String, dynamic>{
          'role': msg.role.name,
          'content': msg.content,
        };

        // 如果有工具调用，添加到消息中
        if (msg.toolCalls != null && msg.toolCalls!.isNotEmpty) {
          msgData['tool_calls'] =
              msg.toolCalls!.map((tc) => tc.toJson()).toList();
        }

        messages.add(msgData);
      }
    }

    // 添加用户消息
    messages.add({
      'role': 'user',
      'content': content,
    });

    return messages;
  }

  /// 发送请求并处理工具调用
  Future<Map<String, dynamic>> _sendRequestWithToolCalls(
    ChatCompletionRequest request,
    AgentConfig agent,
    List<Map<String, dynamic>> messages,
    ModelConfig config,
  ) async {
    var currentRequest = request;
    var currentMessages = List<Map<String, dynamic>>.from(messages);
    var iterationCount = 0;
    const maxIterations = 5; // 防止无限循环

    while (iterationCount < maxIterations) {
      iterationCount++;
      _log.debug('Agent 请求迭代', {'iteration': iterationCount});

      // 调用 API
      final response = await _apiClient.createChatCompletion(currentRequest);
      final choice = response.choices.first;
      final messageData = choice.message;

      // 检查是否有工具调用
      if (messageData.toolCalls == null || messageData.toolCalls!.isEmpty) {
        // 没有工具调用，返回结果
        _log.info('收到最终响应', {
          'iterations': iterationCount,
          'contentLength': messageData.content.length,
        });

        return {
          'content': messageData.content,
          'tokenCount': response.usage?.completionTokens,
          'toolCalls': null,
          'metadata': {
            'iterations': iterationCount,
            'finishReason': choice.finishReason,
          },
        };
      }

      // 执行工具调用
      _log.info('检测到工具调用', {
        'count': messageData.toolCalls!.length,
      });

      final toolCallMessage = Message(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: messageData.content,
        timestamp: DateTime.now(),
        toolCalls: messageData.toolCalls,
      );

      // 处理工具调用
      final processedMessage =
          await _agentIntegration.processToolCallResponse(toolCallMessage, agent);

      // 获取工具执行结果
      final toolResults = (processedMessage.metadata?['toolResults'] as List?)
          ?.map((r) => ToolExecutionResult.fromJson(r))
          .toList();

      if (toolResults == null) {
        throw Exception('工具执行失败：无法获取结果');
      }

      // 添加 assistant 消息和工具结果到对话历史
      currentMessages.add({
        'role': 'assistant',
        'content': messageData.content,
        'tool_calls':
            messageData.toolCalls!.map((tc) => tc.toJson()).toList(),
      });

      // 添加工具结果消息
      final toolResultMessages = _agentIntegration.buildToolResultMessages(
        messageData.toolCalls!,
        toolResults,
      );
      currentMessages.addAll(toolResultMessages);

      // 准备下一次请求
      currentRequest = currentRequest.copyWith(messages: currentMessages);

      // 如果所有工具调用失败，提前返回错误
      if (toolResults.every((r) => !r.success)) {
        _log.warning('所有工具调用失败');
        return {
          'content':
              '工具执行失败:\n${_agentIntegration.formatToolResults(toolResults)}',
          'tokenCount': response.usage?.completionTokens,
          'toolCalls': messageData.toolCalls,
          'metadata': {
            'toolResults': toolResults.map((r) => r.toJson()).toList(),
            'error': '所有工具执行失败',
            'iterations': iterationCount,
          },
        };
      }
    }

    throw Exception('达到最大迭代次数 ($maxIterations)');
  }
}
