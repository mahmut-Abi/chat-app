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
     List<ImageAttachment>? images,
     List<String>? files,
   }) async {
     try {
       _log.info('发送消息', {
         'conversationId': conversationId,
         'model': config.model,
         'contentLength': content.length,
         'historyCount': conversationHistory?.length ?? 0,
         'imagesCount': images?.length ?? 0,
         'filesCount': files?.length ?? 0,
         'temperature': config.temperature,
         'maxTokens': config.maxTokens,
       });
       final messages = _buildMessageList(
         conversationHistory,
         content,
         images: images,
         files: files,
       );
 
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

      _log.info('收到响应', {
        'conversationId': conversationId,
        'tokenCount': tokenCount,
        'responseLength': response.choices.first.message.content.length,
      });

      return Message(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: response.choices.first.message.content,
        timestamp: DateTime.now(),
        tokenCount: tokenCount,
      );
    } catch (e) {
      _log.error('发送消息失败', {
        'conversationId': conversationId,
        'error': e.toString(),
      });
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
     List<ImageAttachment>? images,
     List<String>? files,
   }) async* {
     _log.info('发送流式消息', {
       'conversationId': conversationId,
       'model': config.model,
       'contentLength': content.length,
       'historyCount': conversationHistory?.length ?? 0,
       'imagesCount': images?.length ?? 0,
       'filesCount': files?.length ?? 0,
     });
 
     try {
       final messages = _buildMessageList(
         conversationHistory,
         content,
         images: images,
         files: files,
       );
 
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
        _log.debug('收到流式响应块', {'chunkLength': chunk.length});
        yield chunk;
      }

      _log.info('流式消息完成', {'conversationId': conversationId});
    } catch (e) {
      _log.error('流式消息失败', {
        'conversationId': conversationId,
        'error': e.toString(),
      });
      yield '[Error: ${e.toString()}]';
    }
  }

   List<Map<String, dynamic>> _buildMessageList(
     List<Message>? history,
     String newContent,
     {
     List<ImageAttachment>? images,
     List<String>? files,
     }
   ) {
     final messages = <Map<String, dynamic>>[];
 
     if (history != null) {
       for (final msg in history) {
         // 如果历史消息包含图片，需要构建多模态内容
         if (msg.images != null && msg.images!.isNotEmpty) {
           final content = <Map<String, dynamic>>[
             {'type': 'text', 'text': msg.content},
           ];
           
           for (final image in msg.images!) {
             if (image.base64Data != null && image.mimeType != null) {
               content.add({
                 'type': 'image_url',
                 'image_url': {
                   'url': 'data:${image.mimeType};base64,${image.base64Data}',
                 },
               });
             }
           }
           
           messages.add({'role': msg.role.name, 'content': content});
         } else {
           messages.add({'role': msg.role.name, 'content': msg.content});
         }
       }
     }
 
     // 构建新消息（包含图片和文件）
     if ((images != null && images.isNotEmpty) ||
         (files != null && files.isNotEmpty)) {
       final content = <Map<String, dynamic>>[
         {'type': 'text', 'text': newContent},
       ];
       
       // 添加图片
       if (images != null) {
         for (final image in images) {
           if (image.base64Data != null && image.mimeType != null) {
             content.add({
               'type': 'image_url',
               'image_url': {
                 'url': 'data:${image.mimeType};base64,${image.base64Data}',
               },
             });
           }
         }
       }
       
       // 添加文件内容（如果是文本文件）
       // 注意：OpenAI API 标准不直接支持文件上传，需要将文件内容转换为文本
       if (files != null && files.isNotEmpty) {
         _log.info('文件附件', {'filesCount': files.length});
         // 这里可以添加文件处理逻辑，例如读取文本文件内容
         // 目前暂不实现，因为标准 OpenAI API 不支持直接文件上传
       }
       
       messages.add({'role': 'user', 'content': content});
     } else {
       messages.add({'role': 'user', 'content': newContent});
     }
 
     return messages;
   }

  // Conversation management
  Future<Conversation> createConversation({
    String? title,
    String? systemPrompt,
    List<String>? tags,
    String? groupId,
  }) async {
    _log.info('创建新对话', {
      'title': title,
      'hasSystemPrompt': systemPrompt != null,
      'tagsCount': tags?.length ?? 0,
      'groupId': groupId,
    });

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

  Future<void> saveGroup(ConversationGroup group) async {
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

  /// 自动生成会话标题
  /// 基于第一条用户消息和AI回复生成简短的标题
  Future<void> generateConversationTitle(String conversationId) async {
    final conversation = getConversation(conversationId);
    if (conversation == null || conversation.messages.length < 2) {
      return;
    }

    // 如果标题不是默认值，不自动生成
    if (conversation.title != 'New Conversation' &&
        !conversation.title.startsWith('新会话')) {
      return;
    }

    try {
      // 获取第一条用户消息
      final userMessage = conversation.messages.firstWhere(
        (m) => m.role == MessageRole.user,
        orElse: () => conversation.messages.first,
      );

      // 使用第一条用户消息生成标题（取前30个字符）
      String title = userMessage.content.trim();

      // 移除多余的空白字符
      title = title.replaceAll(RegExp(r'\s+'), ' ');

      // 限制长度
      if (title.length > 30) {
        title = '${title.substring(0, 30)}...';
      }

      // 如果标题为空，使用默认值
      if (title.isEmpty) {
        title = '对话 ${DateTime.now().toString().substring(5, 16)}';
      }

      _log.info('自动生成会话标题', {'conversationId': conversationId, 'title': title});

      // 更新会话标题
      final updated = conversation.copyWith(title: title);
      await saveConversation(updated);
    } catch (e) {
      _log.error('生成会话标题失败', {
        'conversationId': conversationId,
        'error': e.toString(),
      });
    }
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
