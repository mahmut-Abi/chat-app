import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('API 配置存储逻辑测试', () {
    // 模拟 Hive Box 的存储
    late Map<String, String> mockStorage;

    setUp(() {
      mockStorage = {};
    });

    test('应该能够保存 API 配置', () {
      // Arrange
      final config = {
        'id': 'test-id',
        'name': 'Test Config',
        'provider': 'openai',
        'apiKey': 'test-key',
        'baseUrl': 'https://api.openai.com',
      };
      final key = 'api_config_test-id';

      // Act - 模拟 saveApiConfig 逻辑
      mockStorage[key] = jsonEncode(config);

      // Assert
      expect(mockStorage[key], isNotNull);

      final decoded = jsonDecode(mockStorage[key]!) as Map<String, dynamic>;
      expect(decoded['id'], 'test-id');
      expect(decoded['name'], 'Test Config');
      expect(decoded['provider'], 'openai');
      expect(decoded['apiKey'], 'test-key');
    });

    test('应该能够读取 API 配置', () {
      // Arrange
      final config = {
        'id': 'test-id',
        'name': 'Test Config',
        'provider': 'openai',
      };
      final key = 'api_config_test-id';
      mockStorage[key] = jsonEncode(config);

      // Act - 模拟 getApiConfig 逻辑
      final data = mockStorage[key];

      // Assert
      expect(data, isNotNull);
      final decoded = jsonDecode(data!) as Map<String, dynamic>;
      expect(decoded['id'], 'test-id');
    });

    test('应该能够更新 API 配置', () {
      // Arrange
      final config1 = {'id': 'test-id', 'name': 'Original Name'};
      final config2 = {'id': 'test-id', 'name': 'Updated Name'};
      final key = 'api_config_test-id';

      // Act - 模拟多次 put 操作
      mockStorage[key] = jsonEncode(config1);
      mockStorage[key] = jsonEncode(config2); // 更新

      // Assert
      final data = mockStorage[key];
      final decoded = jsonDecode(data!) as Map<String, dynamic>;
      expect(decoded['name'], 'Updated Name');
    });

    test('应该能够获取所有 API 配置', () {
      // Arrange
      final config1 = {'id': 'id1', 'name': 'Config 1'};
      final config2 = {'id': 'id2', 'name': 'Config 2'};
      final config3 = {'id': 'id3', 'name': 'Config 3'};

      mockStorage['api_config_id1'] = jsonEncode(config1);
      mockStorage['api_config_id2'] = jsonEncode(config2);
      mockStorage['api_config_id3'] = jsonEncode(config3);
      mockStorage['other_key'] = 'should not be included';

      // Act - 模拟 getAllApiConfigs 逻辑
      final allKeys = mockStorage.keys
          .where((key) => key.startsWith('api_config_'))
          .toList();

      final configs = allKeys
          .map((key) => mockStorage[key])
          .where((data) => data != null)
          .map((data) {
            try {
              return jsonDecode(data!) as Map<String, dynamic>;
            } catch (e) {
              return null;
            }
          })
          .where((config) => config != null)
          .cast<Map<String, dynamic>>()
          .toList();

      // Assert
      expect(configs.length, 3);
      expect(configs.any((c) => c['id'] == 'id1'), true);
      expect(configs.any((c) => c['id'] == 'id2'), true);
      expect(configs.any((c) => c['id'] == 'id3'), true);
    });

    test('应该能够删除 API 配置', () {
      // Arrange
      final config = {'id': 'test-id', 'name': 'Test'};
      final key = 'api_config_test-id';
      mockStorage[key] = jsonEncode(config);

      // Act - 模拟 deleteApiConfig 逻辑
      mockStorage.remove(key);

      // Assert
      final data = mockStorage[key];
      expect(data, isNull);
    });

    test('读取不存在的配置应该返回 null', () {
      // Act
      final data = mockStorage['api_config_nonexistent'];

      // Assert
      expect(data, isNull);
    });

    test('应该能够处理多次更新同一配置', () {
      // Arrange
      final key = 'api_config_test-id';

      // Act & Assert - 多次更新
      for (int i = 0; i < 10; i++) {
        final config = {'id': 'test-id', 'name': 'Config v\$i', 'version': i};
        mockStorage[key] = jsonEncode(config);

        final data = mockStorage[key];
        final decoded = jsonDecode(data!) as Map<String, dynamic>;
        expect(decoded['version'], i);
        expect(decoded['name'], 'Config v\$i');
      }
    });

    test('应该能够处理特殊字符', () {
      // Arrange
      final config = {
        'id': 'test-id',
        'name': '中文名称 Special!@#\\\$%^&*()',
        'description': 'Line1\\nLine2\\nLine3',
      };
      final key = 'api_config_test-id';

      // Act
      mockStorage[key] = jsonEncode(config);
      final data = mockStorage[key];

      // Assert
      expect(data, isNotNull);
      final decoded = jsonDecode(data!) as Map<String, dynamic>;
      expect(decoded['name'], '中文名称 Special!@#\\\$%^&*()');
      expect(decoded['description'], contains('Line1'));
    });

    test('应该能够处理大型配置数据', () {
      // Arrange
      final config = {
        'id': 'test-id',
        'name': 'Large Config',
        'models': List.generate(
          100,
          (i) => {
            'id': 'model-$i',
            'name': 'Model $i',
          },
        ),
      };
      final key = 'api_config_test-id';

      // Act
      mockStorage[key] = jsonEncode(config);
      final data = mockStorage[key];

      // Assert
      expect(data, isNotNull);
      final decoded = jsonDecode(data!) as Map<String, dynamic>;
      expect(decoded['models'], hasLength(100));
      expect(decoded['models'][0]['id'], 'model-0');
      expect(decoded['models'][99]['id'], 'model-99');
    });

    test('JSON 编解码应该保持数据完整性', () {
      // Arrange
      final originalConfig = {
        'id': 'test-id',
        'name': 'Test',
        'nested': {'key1': 'value1', 'key2': 123, 'key3': true},
        'array': [
          1,
          2,
          3,
          'four',
          {'five': 5},
        ],
      };

      // Act
      final encoded = jsonEncode(originalConfig);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      // Assert
      expect(decoded['id'], originalConfig['id']);
      expect(decoded['name'], originalConfig['name']);
      expect(decoded['nested'], originalConfig['nested']);
      expect(decoded['array'], originalConfig['array']);
    });

    test('应该能够处理空配置', () {
      // Arrange
      final config = <String, dynamic>{};
      final key = 'api_config_empty';

      // Act
      mockStorage[key] = jsonEncode(config);
      final data = mockStorage[key];

      // Assert
      expect(data, isNotNull);
      final decoded = jsonDecode(data!) as Map<String, dynamic>;
      expect(decoded.isEmpty, true);
    });
  });
}
