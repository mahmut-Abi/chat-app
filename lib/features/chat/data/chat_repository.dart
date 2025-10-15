import 'dart:async';
import 'package:uuid/uuid.dart';
import '../domain/message.dart';
import '../domain/conversation.dart';
import '../../../core/network/openai_api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/token_counter.dart';
import '../../../core/utils/markdown_export.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/log_service.dart';

class ChatRepository {
  final OpenAIApiClient _apiClient;
  final StorageService _storage;
  final _uuid = const Uuid();
  final _log = LogService();

  ChatRepository(this._apiClient, this._storage);

  // Send message and get response
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    required ModelConfig config,
    List<Message>? conversationHistory,
  }) async {
    try {
      _log.info('发送消息: conversationId=$conversationId, model=${config.model}');
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
      _log.error('发送消息失败', e);
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

      await for (final chunk in _apiClient.createChatCompletionStream(
        request,
      )) {
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
        messages.add({'role': msg.role.name, 'content': msg.content});
      }
    }

    messages.add({'role': 'user', 'content': newContent});

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
      messages: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      systemPrompt: systemPrompt,
      tags: tags ?? const [],
      groupId: groupId,
      isTemporary: true, // 标记为临时对话
    );

    // 暂不保存到存储，等待用户发送第一条消息

    if (kDebugMode) {
      print('createConversation: 创建并保存新对话 ${conversation.id}');
    }

    return conversation;
  }

  Future<void> saveConversation(Conversation conversation) async {
    // 跳过保存空对话
    if (conversation.messages.isEmpty) {
      if (kDebugMode) {
        print('saveConversation: 跳过保存空对话 ${conversation.id}');
      }
      return;
    }

    // 如果对话有消息,将 isTemporary 设为 false
    if (conversation.isTemporary) {
      conversation = conversation.copyWith(isTemporary: false);
    }

    // 计算总 token 数
    int totalTokens = 0;
    for (final message in conversation.messages) {
      if (message.tokenCount != null) {
        totalTokens += message.tokenCount!;
      } else {
        totalTokens += TokenCounter.estimate(message.content);
      }
    }

    final updatedConversation = conversation.copyWith(totalTokens: totalTokens);

    if (kDebugMode) {
      print(
        'saveConversation: 保存对话 ${conversation.id}, 消息数: ${conversation.messages.length}',
      );
    }

    await _storage.saveConversation(
      updatedConversation.id,
      updatedConversation.toJson(),
    );
  }

  Conversation? getConversation(String id) {
    final data = _storage.getConversation(id);
    if (data == null) return null;
    if (kDebugMode) {
      print('ChatRepository.getConversation:');
      print('  id: $id');
      print('  title: ${data['title']}');
      print('  messages: ${(data['messages'] as List).length}');
    }
    return Conversation.fromJson(data);
  }

  List<Conversation> getAllConversations() {
    final conversations = _storage.getAllConversations();
    return conversations
        .map((data) => Conversation.fromJson(data))
        .where((conv) => !conv.isTemporary) // 过滤临时对话
        .toList()
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

  // Conversation Group management
  Future<ConversationGroup> createGroup({
    required String name,
    String? color,
    int? sortOrder,
  }) async {
    final group = ConversationGroup(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      color: color,
      sortOrder: sortOrder,
    );

    await _storage.saveGroup(group.id, group.toJson());
    return group;
  }

  ConversationGroup? getGroup(String id) {
    final data = _storage.getGroup(id);
    if (data == null) return null;
    return ConversationGroup.fromJson(data);
  }

  List<ConversationGroup> getAllGroups() {
    final groups = _storage.getAllGroups();
    return groups.map((data) => ConversationGroup.fromJson(data)).toList()
      ..sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        }
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  Future<void> updateGroup(ConversationGroup group) async {
    await _storage.saveGroup(group.id, group.toJson());
  }

  Future<void> deleteGroup(String id) async {
    // 将分组中的对话移到未分组
    final conversations = getConversationsByGroup(id);
    for (final conv in conversations) {
      await setConversationGroup(conv.id, null);
    }
    await _storage.deleteGroup(id);
  }

  // 获取所有标签
  List<String> getAllTags() {
    final conversations = getAllConversations();
    final tags = <String>{};
    for (final conv in conversations) {
      tags.addAll(conv.tags);
    }
    return tags.toList()..sort();
  }

  // 置顶/取消置顶功能
  Future<void> togglePinConversation(String id) async {
    final conversation = getConversation(id);
    if (conversation != null) {
      final updated = conversation.copyWith(
        isPinned: !conversation.isPinned,
        updatedAt: DateTime.now(),
      );
      await saveConversation(updated);
    }
  }

  // 获取排序后的对话列表（置顶在前）
  List<Conversation> getSortedConversations() {
    final conversations = getAllConversations(); // 已经过滤了临时对话
    conversations.sort((a, b) {
      // 置顶的在前
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      // 否则按更新时间排序
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return conversations;
  }
}
