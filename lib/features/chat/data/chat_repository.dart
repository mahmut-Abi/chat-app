import 'dart:async';
import 'package:uuid/uuid.dart';
import '../domain/message.dart';
import '../domain/conversation.dart';
import '../../../core/network/openai_api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/token_counter.dart';
import '../../../core/utils/markdown_export.dart';

class ChatRepository {
  final OpenAIApiClient _apiClient;
  final StorageService _storage;
  final _uuid = const Uuid();

  ChatRepository(this._apiClient, this._storage);

  // Send message and get response
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    required ModelConfig config,
    List<Message>? conversationHistory,
  }) async {
    try {
      final messages = _buildMessageList(conversationHistory, content);

      final request = ChatCompletionRequest(
        model: config.model,
        messages: messages,
        temperature: config.temperature,
        maxTokens: config.maxTokens,
        topP: config.topP,
        frequencyPenalty: config.frequencyPenalty,
        presencePenalty: config.presencePenalty,
        stream: false,
      );

      final response = await _apiClient.createChatCompletion(request);
      final tokenCount = response.usage?.completionTokens;

      return Message(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: response.choices.first.message.content,
        timestamp: DateTime.now(),
        tokenCount: tokenCount,
      );
    } catch (e) {
      return Message(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  // Send message with streaming response
  Stream<String> sendMessageStream({
    required String conversationId,
    required String content,
    required ModelConfig config,
    List<Message>? conversationHistory,
  }) async* {
    try {
      final messages = _buildMessageList(conversationHistory, content);

      final request = ChatCompletionRequest(
        model: config.model,
        messages: messages,
        temperature: config.temperature,
        maxTokens: config.maxTokens,
        topP: config.topP,
        frequencyPenalty: config.frequencyPenalty,
        presencePenalty: config.presencePenalty,
        stream: true,
      );

      await for (final chunk
          in _apiClient.createChatCompletionStream(request)) {
        yield chunk;
      }
    } catch (e) {
      yield '[Error: ${e.toString()}]';
    }
  }

  List<Map<String, String>> _buildMessageList(
    List<Message>? history,
    String newContent,
  ) {
    final messages = <Map<String, String>>[];

    if (history != null) {
      for (final msg in history) {
        messages.add({
          'role': msg.role.name,
          'content': msg.content,
        });
      }
    }

    messages.add({
      'role': 'user',
      'content': newContent,
    });

    return messages;
  }

  // Conversation management
  Future<Conversation> createConversation({
    String? title,
    String? systemPrompt,
    List<String>? tags,
    String? groupId,
  }) async {
    final conversation = Conversation(
      id: _uuid.v4(),
      title: title ?? 'New Conversation',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      systemPrompt: systemPrompt,
      tags: tags ?? [],
      groupId: groupId,
    );

    await _storage.saveConversation(
      conversation.id,
      conversation.toJson(),
    );

    return conversation;
  }

  Future<void> saveConversation(Conversation conversation) async {
    // 计算总 token 数
    int totalTokens = 0;
    for (final message in conversation.messages) {
      if (message.tokenCount != null) {
        totalTokens += message.tokenCount!;
      } else {
        totalTokens += TokenCounter.estimate(message.content);
      }
    }

    final updatedConversation = conversation.copyWith(
      totalTokens: totalTokens,
    );

    await _storage.saveConversation(
      updatedConversation.id,
      updatedConversation.toJson(),
    );
  }

  Conversation? getConversation(String id) {
    final data = _storage.getConversation(id);
    if (data == null) return null;
    return Conversation.fromJson(data);
  }

  List<Conversation> getAllConversations() {
    final conversations = _storage.getAllConversations();
    return conversations.map((data) => Conversation.fromJson(data)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> deleteConversation(String id) async {
    await _storage.deleteConversation(id);
  }

  Future<void> updateConversationTitle(String id, String title) async {
    final conversation = getConversation(id);
    if (conversation != null) {
      final updated = conversation.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      await saveConversation(updated);
    }
  }

  // 添加标签管理功能
  Future<void> addTagToConversation(String id, String tag) async {
    final conversation = getConversation(id);
    if (conversation != null) {
      final tags = List<String>.from(conversation.tags);
      if (!tags.contains(tag)) {
        tags.add(tag);
        final updated = conversation.copyWith(
          tags: tags,
          updatedAt: DateTime.now(),
        );
        await saveConversation(updated);
      }
    }
  }

  Future<void> removeTagFromConversation(String id, String tag) async {
    final conversation = getConversation(id);
    if (conversation != null) {
      final tags = List<String>.from(conversation.tags);
      tags.remove(tag);
      final updated = conversation.copyWith(
        tags: tags,
        updatedAt: DateTime.now(),
      );
      await saveConversation(updated);
    }
  }

  Future<void> setConversationGroup(String id, String? groupId) async {
    final conversation = getConversation(id);
    if (conversation != null) {
      final updated = conversation.copyWith(
        groupId: groupId,
        updatedAt: DateTime.now(),
      );
      await saveConversation(updated);
    }
  }

  // 根据标签筛选对话
  List<Conversation> getConversationsByTag(String tag) {
    final conversations = getAllConversations();
    return conversations.where((c) => c.tags.contains(tag)).toList();
  }

  // 根据分组筛选对话
  List<Conversation> getConversationsByGroup(String? groupId) {
    final conversations = getAllConversations();
    return conversations.where((c) => c.groupId == groupId).toList();
  }

  // 导出功能
  String exportToMarkdown(String id) {
    final conversation = getConversation(id);
    if (conversation == null) {
      throw Exception('对话不存在');
    }
    return MarkdownExport.exportConversation(conversation);
  }

  String exportAllToMarkdown() {
    final conversations = getAllConversations();
    return MarkdownExport.exportConversations(conversations);
  }
}
