import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/domain/message.dart';

void main() {
  group('Message', () {
    test('应该正确创建消息', () {
      final now = DateTime.now();
      final message = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: now,
      );

      expect(message.id, 'msg-1');
      expect(message.role, MessageRole.user);
      expect(message.content, 'Hello');
      expect(message.timestamp, now);
      expect(message.isStreaming, false);
      expect(message.hasError, false);
    });

    test('应该正确复制消息并更新字段', () {
      final original = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final updated = original.copyWith(
        content: 'Hello World',
        isStreaming: true,
      );

      expect(updated.id, original.id);
      expect(updated.content, 'Hello World');
      expect(updated.isStreaming, true);
    });

    test('应该正确序列化和反序列化', () {
      final message = Message(
        id: 'msg-1',
        role: MessageRole.assistant,
        content: 'Test content',
        timestamp: DateTime.now(),
      );

      final json = message.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, message.id);
      expect(restored.role, message.role);
      expect(restored.content, message.content);
    });

    test('应该正确处理图片附件', () {
      final image = ImageAttachment(
        path: '/path/to/image.jpg',
        mimeType: 'image/jpeg',
      );

      final message = Message(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Check this image',
        timestamp: DateTime.now(),
        images: [image],
      );

      expect(message.images, isNotNull);
      expect(message.images!.length, 1);
      expect(message.images!.first.path, '/path/to/image.jpg');
    });
  });

  group('ChatCompletionRequest', () {
    test('应该正确创建请求', () {
      final request = ChatCompletionRequest(
        model: 'gpt-3.5-turbo',
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
      );

      expect(request.model, 'gpt-3.5-turbo');
      expect(request.messages.length, 1);
      expect(request.temperature, 0.7);
      expect(request.maxTokens, 2048);
      expect(request.stream, false);
    });

    test('应该正确更新请求参数', () {
      final request = ChatCompletionRequest(
        model: 'gpt-3.5-turbo',
        messages: [],
      );

      final updated = request.copyWith(
        temperature: 0.9,
        maxTokens: 4096,
        stream: true,
      );

      expect(updated.temperature, 0.9);
      expect(updated.maxTokens, 4096);
      expect(updated.stream, true);
      expect(updated.model, 'gpt-3.5-turbo');
    });
  });
}
