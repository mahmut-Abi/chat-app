import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/data/chat_repository.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';
import 'package:chat_app/features/chat/domain/message.dart';
import 'package:chat_app/core/network/openai_api_client.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([OpenAIApiClient, StorageService])
import 'conversation_creation_test.mocks.dart';

void main() {
  late ChatRepository chatRepository;
  late MockOpenAIApiClient mockApiClient;
  late MockStorageService mockStorage;

  setUp(() {
    mockApiClient = MockOpenAIApiClient();
    mockStorage = MockStorageService();
    chatRepository = ChatRepository(mockApiClient, mockStorage);
  });

  group('对话创建测试', () {
    test('创建对话应该立即保存到存储', () async {
      // Arrange
      when(mockStorage.saveConversation(any, any)).thenAnswer((_) async {});

      // Act
      final conversation = await chatRepository.createConversation(
        title: '测试对话',
      );

      // Assert
      expect(conversation.title, '测试对话');
      expect(conversation.messages, isEmpty);
      verify(mockStorage.saveConversation(conversation.id, any)).called(1);
    });

    test('多次创建对话应该产生不同的ID', () async {
      // Arrange
      when(mockStorage.saveConversation(any, any)).thenAnswer((_) async {});

      // Act
      final conv1 = await chatRepository.createConversation(title: '对话1');
      final conv2 = await chatRepository.createConversation(title: '对话2');
      final conv3 = await chatRepository.createConversation(title: '对话3');

      // Assert
      expect(conv1.id, isNot(equals(conv2.id)));
      expect(conv2.id, isNot(equals(conv3.id)));
      expect(conv1.id, isNot(equals(conv3.id)));

      // 验证每个对话都被保存
      verify(mockStorage.saveConversation(conv1.id, any)).called(1);
      verify(mockStorage.saveConversation(conv2.id, any)).called(1);
      verify(mockStorage.saveConversation(conv3.id, any)).called(1);
    });

    test('保存对话应该更新消息列表', () async {
      // Arrange
      when(mockStorage.saveConversation(any, any)).thenAnswer((_) async {});
      final conversation = await chatRepository.createConversation(
        title: '测试对话',
      );

      // Act - 添加消息并保存
      final updatedConv = conversation.copyWith(
        messages: [
          Message(
            id: '1',
            role: MessageRole.user,
            content: '测试消息',
            timestamp: DateTime.now(),
          ),
        ],
      );

      await chatRepository.saveConversation(updatedConv);

      // Assert
      verify(
        mockStorage.saveConversation(
          conversation.id,
          argThat(
            predicate((json) {
              final data = json as Map<String, dynamic>;
              final messages = data['messages'] as List;
              return messages.length == 1;
            }),
          ),
        ),
      ).called(1);
    });
  });
}
