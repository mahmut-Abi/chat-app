import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/utils/token_counter.dart';

void main() {
  group('TokenCounter', () {
    test('应该正确估算英文文本的 token 数', () {
      const text = 'Hello world';
      final count = TokenCounter.estimate(text);
      expect(count, greaterThan(0));
      expect(count, lessThan(20));
    });

    test('应该正确估算中文文本的 token 数', () {
      const text = '你好世界';
      final count = TokenCounter.estimate(text);
      expect(count, greaterThan(0));
      expect(count, lessThan(20));
    });

    test('应该处理空字符串', () {
      const text = '';
      final count = TokenCounter.estimate(text);
      expect(count, equals(0));
    });

    test('应该正确估算消息列表的 token 数', () {
      final messages = [
        {'role': 'user', 'content': 'Hello'},
        {'role': 'assistant', 'content': 'Hi there!'},
      ];
      final count = TokenCounter.estimateMessages(messages);
      expect(count, greaterThan(0));
    });
  });
}
