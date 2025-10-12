import 'dart:async';
import 'package:uuid/uuid.dart';
import '../domain/message.dart';
import '../domain/conversation.dart';
import '../../../core/network/openai_api_client.dart';
import '../../../core/storage/storage_service.dart';

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
      
      return Message(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: response.choices.first.message.content,
        timestamp: DateTime.now(),
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

      await for (final chunk in _apiClient.createChatCompletionStream(request)) {
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
  }) async {
    final conversation = Conversation(
      id: _uuid.v4(),
      title: title ?? 'New Conversation',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      systemPrompt: systemPrompt,
    );

    await _storage.saveConversation(
      conversation.id,
      conversation.toJson(),
    );

    return conversation;
  }

  Future<void> saveConversation(Conversation conversation) async {
    await _storage.saveConversation(
      conversation.id,
      conversation.toJson(),
    );
  }

  Conversation? getConversation(String id) {
    final data = _storage.getConversation(id);
    if (data == null) return null;
    return Conversation.fromJson(data);
  }

  List<Conversation> getAllConversations() {
    final conversations = _storage.getAllConversations();
    return conversations
        .map((data) => Conversation.fromJson(data))
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
}
