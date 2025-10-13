import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/data/chat_repository.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';
import 'package:chat_app/features/chat/domain/message.dart';
import 'package:chat_app/core/network/openai_api_client.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([OpenAIApiClient, StorageService])
import 'chat_repository_test.mocks.dart';

void main() {
  late ChatRepository repository;
  late MockOpenAIApiClient mockApiClient;
  late MockStorageService mockStorage;

  setUp(() {
    mockApiClient = MockOpenAIApiClient();
    mockStorage = MockStorageService();
    repository = ChatRepository(mockApiClient, mockStorage);
  });

  group('ChatRepository - Conversation Management', () {
    test('应该正确创建会话', () async {
      final conversation = await repository.createConversation(
        title: 'Test Conversation',
      );

      expect(conversation.title, 'Test Conversation');
      expect(conversation.messages, isEmpty);
      expect(conversation.id, isNotEmpty);

      // 验证空对话不会被保存
      verifyNever(mockStorage.saveConversation(any, any));
    });

    test('应该跳过保存空对话', () async {
      final conversation = await repository.createConversation(title: 'Test');

      // 尝试保存空对话
      await repository.saveConversation(conversation);

      // 验证没有调用保存
      verifyNever(mockStorage.saveConversation(any, any));
    });

    test('应该正确保存非空对话', () async {
      when(mockStorage.saveConversation(any, any)).thenAnswer((_) async => {});

      final conversation = await repository.createConversation(title: 'Test');

      // 添加一条消息
      final updatedConversation = conversation.copyWith(
        messages: [
          Message(
            id: 'msg-1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
          ),
        ],
      );

      await repository.saveConversation(updatedConversation);

      // 验证保存被调用
      verify(
        mockStorage.saveConversation(updatedConversation.id, any),
      ).called(1);
    });

    test('应该正确获取所有会话', () {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'conv-1',
          'title': 'Conv 1',
          'messages': [],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'settings': <String, dynamic>{},
          'tags': [],
          'isPinned': false,
        },
      ];

      when(mockStorage.getAllConversations()).thenReturn(mockData);

      final conversations = repository.getAllConversations();

      expect(conversations.length, 1);
      expect(conversations.first.id, 'conv-1');
    });

    test('应该正确删除会话', () async {
      when(mockStorage.deleteConversation(any)).thenAnswer((_) async => {});

      await repository.deleteConversation('conv-1');

      verify(mockStorage.deleteConversation('conv-1')).called(1);
    });
  });

  group('ChatRepository - Tags and Groups', () {
    test('应该正确创建分组', () async {
      when(mockStorage.saveGroup(any, any)).thenAnswer((_) async => {});

      final group = await repository.createGroup(
        name: 'Work',
        color: '#FF0000',
      );

      expect(group.name, 'Work');
      expect(group.color, '#FF0000');
      verify(mockStorage.saveGroup(any, any)).called(1);
    });

    test('应该正确获取所有标签', () {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'conv-1',
          'title': 'Conv 1',
          'messages': [],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'settings': <String, dynamic>{},
          'tags': ['work', 'important'],
          'isPinned': false,
        },
      ];

      when(mockStorage.getAllConversations()).thenReturn(mockData);

      final tags = repository.getAllTags();

      expect(tags, contains('work'));
      expect(tags, contains('important'));
    });
  });

  group('ChatRepository - Pin Feature', () {
    test('应该正确置顶会话', () async {
      // 创建一个非空对话（包含消息）
      final conversation = Conversation(
        id: 'conv-1',
        title: 'Test',
        messages: [
          Message(
            id: 'msg-1',
            role: MessageRole.user,
            content: 'Test message',
            timestamp: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: false,
      );

      when(
        mockStorage.getConversation('conv-1'),
      ).thenReturn(conversation.toJson());
      when(mockStorage.saveConversation(any, any)).thenAnswer((_) async => {});

      await repository.togglePinConversation('conv-1');

      verify(mockStorage.saveConversation('conv-1', any)).called(1);
    });
  });
}
