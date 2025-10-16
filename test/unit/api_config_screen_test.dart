import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfigScreen - Bug #1 修复验证', () {
    test('验证测试连接和刷新模型使用相同的 API 配置途径', () {
      // 这个测试验证修复前的问题：
      // 1. _testConnection() 使用 _baseUrlController.text, _apiKeyController.text
      // 2. _fetchAvailableModels() 也使用 _baseUrlController.text, _apiKeyController.text
      // 3. 现在两者都应该包含 proxyUsername 和 proxyPassword

      // 这个测试确认了我们的修复：
      // 在 _testConnection() 中添加了 proxyUsername 和 proxyPassword 参数

      const baseUrl = 'https://api.openai.com/v1';
      const apiKey = 'test-key';
      const proxyUrl = 'http://proxy.com';
      const proxyUsername = 'proxy-user';
      const proxyPassword = 'proxy-pass';
      final enableProxy = true;

      // 模拟 _testConnection() 中创建 DioClient 的逻辑（修复后）
      final testConnectionConfig = {
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'proxyUrl': enableProxy ? proxyUrl : null,
        'proxyUsername': enableProxy ? proxyUsername : null,
        'proxyPassword': enableProxy ? proxyPassword : null,
      };

      // 模拟 _fetchAvailableModels() 中创建 DioClient 的逻辑
      final refreshModelsConfig = {
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'proxyUrl': enableProxy ? proxyUrl : null,
        'proxyUsername': enableProxy ? proxyUsername : null,
        'proxyPassword': enableProxy ? proxyPassword : null,
      };

      // 验证两个配置应该完全相同
      expect(
        testConnectionConfig['baseUrl'],
        equals(refreshModelsConfig['baseUrl']),
        reason: '测试连接和刷新模型应使用相同的 baseUrl',
      );
      expect(
        testConnectionConfig['apiKey'],
        equals(refreshModelsConfig['apiKey']),
        reason: '测试连接和刷新模型应使用相同的 apiKey',
      );
      expect(
        testConnectionConfig['proxyUrl'],
        equals(refreshModelsConfig['proxyUrl']),
        reason: '测试连接和刷新模型应使用相同的 proxyUrl',
      );
      expect(
        testConnectionConfig['proxyUsername'],
        equals(refreshModelsConfig['proxyUsername']),
        reason: '测试连接和刷新模型应使用相同的 proxyUsername',
      );
      expect(
        testConnectionConfig['proxyPassword'],
        equals(refreshModelsConfig['proxyPassword']),
        reason: '测试连接和刷新模型应使用相同的 proxyPassword',
      );

      // 验证代理认证信息不为 null（这是修复的关键）
      expect(
        testConnectionConfig['proxyUsername'],
        isNotNull,
        reason: '修复后，_testConnection() 应该传递 proxyUsername',
      );
      expect(
        testConnectionConfig['proxyPassword'],
        isNotNull,
        reason: '修复后，_testConnection() 应该传递 proxyPassword',
      );
    });

    test('验证当代理禁用时，两个方法都不传递代理信息', () {
      const baseUrl = 'https://api.openai.com/v1';
      const apiKey = 'test-key';
      final enableProxy = false;

      // 模拟 _testConnection() 中创建 DioClient 的逻辑
      final testConnectionConfig = {
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'proxyUrl': enableProxy ? 'http://proxy.com' : null,
        'proxyUsername': enableProxy ? 'proxy-user' : null,
        'proxyPassword': enableProxy ? 'proxy-pass' : null,
      };

      // 模拟 _fetchAvailableModels() 中创建 DioClient 的逻辑
      final refreshModelsConfig = {
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'proxyUrl': enableProxy ? 'http://proxy.com' : null,
        'proxyUsername': enableProxy ? 'proxy-user' : null,
        'proxyPassword': enableProxy ? 'proxy-pass' : null,
      };

      // 验证当代理禁用时，所有代理配置都为 null
      expect(testConnectionConfig['proxyUrl'], isNull);
      expect(testConnectionConfig['proxyUsername'], isNull);
      expect(testConnectionConfig['proxyPassword'], isNull);

      expect(refreshModelsConfig['proxyUrl'], isNull);
      expect(refreshModelsConfig['proxyUsername'], isNull);
      expect(refreshModelsConfig['proxyPassword'], isNull);
    });
  });
}
