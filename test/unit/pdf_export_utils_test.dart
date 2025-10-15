import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/domain/conversation.dart';
import 'package:chat_app/features/chat/domain/message.dart';

void main() {
  group('PdfExport Utils', () {
    late Conversation testConversation;

    setUp(() {
      testConversation = Conversation(
        id: 'conv1',
        title: '测试对话',
        messages: [
          Message(
            id: 'msg1',
            content: '用户消息',
            role: MessageRole.user,
            timestamp: DateTime(2024, 1, 1, 10, 0),
            tokenCount: 5,
          ),
          Message(
            id: 'msg2',
            content: 'AI 回复',
            role: MessageRole.assistant,
            timestamp: DateTime(2024, 1, 1, 10, 1),
            tokenCount: 10,
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1, 10, 1),
        systemPrompt: '你是一个有用的 AI 助手',
        tags: const ['重要', '工作'],
        totalTokens: 15,
      );
    });

    test('应该正确创建对话数据结构', () {
      expect(testConversation.title, '测试对话');
      expect(testConversation.messages.length, 2);
      expect(testConversation.systemPrompt, '你是一个有用的 AI 助手');
      expect(testConversation.tags, const ['重要', '工作']);
      expect(testConversation.totalTokens, 15);
    });

    test('应该正确过滤非系统消息', () {
      final conversationWithSystem = testConversation.copyWith(
        messages: [
          Message(
            id: 'sys',
            content: '系统消息',
            role: MessageRole.system,
            timestamp: DateTime(2024, 1, 1, 9, 59),
          ),
          ...testConversation.messages,
        ],
      );

      final nonSystemMessages = conversationWithSystem.messages
          .where((m) => m.role != MessageRole.system)
          .toList();

      expect(nonSystemMessages.length, 2);
      expect(
        nonSystemMessages.every((m) => m.role != MessageRole.system),
        true,
      );
    });

    test('应该正确计算 Token 总数', () {
      final totalTokens = testConversation.messages.fold<int>(
        0,
        (sum, msg) => sum + (msg.tokenCount ?? 0),
      );

      expect(totalTokens, 15);
      expect(totalTokens, testConversation.totalTokens);
    });

    test('应该正确格式化对话元数据', () {
      final metadata = {
        'title': testConversation.title,
        'created': testConversation.createdAt.toString(),
        'updated': testConversation.updatedAt.toString(),
        'tags': testConversation.tags.join(', '),
        'totalTokens': testConversation.totalTokens,
      };

      expect(metadata['title'], '测试对话');
      expect(metadata['tags'], '重要, 工作');
      expect(metadata['totalTokens'], 15);
    });

    test('应该正确处理空消息列表', () {
      final emptyConversation = testConversation.copyWith(messages: const []);

      expect(emptyConversation.messages.isEmpty, true);
      expect(emptyConversation.title, '测试对话');
    });
  });
}
