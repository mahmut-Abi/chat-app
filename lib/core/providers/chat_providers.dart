import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/domain/conversation.dart' as chat_domain;
import 'network_providers.dart';
import 'storage_providers.dart';

/// Chat Providers
/// 对话、消息、分组相关

// ============ Chat 仓库 ============

/// Chat 仓库 Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final openAIClient = ref.watch(openAIApiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return ChatRepository(
    openAIClient,
    storage,
  );
});

// ============ 对话、消息 ============

/// 所有对话 Provider
final conversationsProvider = FutureProvider.autoDispose<List<chat_domain.Conversation>>((ref) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.getAllConversations();
});

/// 对话分组 Provider
final conversationGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  final conversations = chatRepo.getAllConversations();
  
  // 按 groupId 分组
  final groupMap = <String, List<chat_domain.Conversation>>{};
  for (final conv in conversations) {
    final groupId = conv.groupId ?? 'default';
    groupMap.putIfAbsent(groupId, () => []).add(conv);
  }
  
  return groupMap.entries
      .map((e) => {'groupId': e.key, 'count': e.value.length})
      .toList();
});
