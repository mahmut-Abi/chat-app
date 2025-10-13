import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/utils/token_counter.dart';

void main() {
  group('TokenCounter', () {
    test('应该正确计算简单文本的Token数', () {
      const text = 'Hello, world!';
      final count = TokenCounter.estimate(text);

      expect(count, greaterThan(0));
      expect(count, lessThan(20));
    });

    test('应该正确计算中文文本的Token数', () {
      const text = '你好，世界！';
      final count = TokenCounter.estimate(text);

      expect(count, greaterThan(0));
    });

    test('应该正确计算多条消息的Token数', () {
      final messages = <Map<String, String>>[
        {'role': 'user', 'content': 'Hello'},
        {'role': 'assistant', 'content': 'Hi there!'},
      ];

      final count = TokenCounter.estimateMessages(messages);

      expect(count, greaterThan(0));
    });

    test('空文本应该返回0', () {
      const text = '';
      final count = TokenCounter.estimate(text);

      expect(count, 0);
    });
  });
}
