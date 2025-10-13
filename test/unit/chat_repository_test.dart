import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/data/chat_repository.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';
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
    });

    test('应该正确保存会话', () async {
      when(mockStorage.saveConversation(any, any)).thenAnswer((_) async => {});

      final conversation = await repository.createConversation(title: 'Test');

      await repository.saveConversation(conversation);

      verify(mockStorage.saveConversation(conversation.id, any)).called(2);
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
      final conversation = Conversation(
        id: 'conv-1',
        title: 'Test',
        messages: [],
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
