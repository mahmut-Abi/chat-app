import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late StorageService storageService;

  setUpAll(() async {
    // 初始化测试环境
    await Hive.initFlutter();
  });

  setUp(() {
    storageService = StorageService();
  });

  tearDown(() async {
    // 清理测试数据
    await Hive.deleteFromDisk();
  });

  group('StorageService - 基础操作', () {
    test('应该能够保存和读取设置', () async {
      // Arrange
      await storageService.init();
      const key = 'test_key';
      const value = 'test_value';

      // Act
      await storageService.saveSetting(key, value);
      final result = await storageService.getSetting(key);

      // Assert
      expect(result, value);
    });

    test('应该返回默认值当设置不存在时', () async {
      // Arrange
      await storageService.init();
      const key = 'non_existent_key';
      const defaultValue = 'default';

      // Act
      final result = storageService.getSetting(key) ?? defaultValue;

      // Assert
      expect(result, defaultValue);
    });

    test('应该能够删除设置', () async {
      // Arrange
      await storageService.init();
      const key = 'test_key';
      const value = 'test_value';
      await storageService.saveSetting(key, value);

      // Act
      await storageService.saveSetting(key, null);
      final result = storageService.getSetting(key);

      // Assert
      expect(result, null);
    });
  });

  group('StorageService - 批量操作', () {
    test('应该能够保存多个设置', () async {
      // Arrange
      await storageService.init();
      final settings = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};

      // Act
      for (final entry in settings.entries) {
        await storageService.saveSetting(entry.key, entry.value);
      }

      // Assert
      final result1 = storageService.getSetting('key1');
      final result2 = storageService.getSetting('key2');
      final result3 = storageService.getSetting('key3');
      expect(result1, 'value1');
      expect(result2, 'value2');
      expect(result3, 'value3');
    });

    test('应该能够清除所有设置', () async {
      // Arrange
      await storageService.init();
      await storageService.saveSetting('key1', 'value1');
      await storageService.saveSetting('key2', 'value2');

      // Act
      await storageService.clearAll();
      final result1 = storageService.getSetting('key1');
      final result2 = storageService.getSetting('key2');

      // Assert
      expect(result1, null);
      expect(result2, null);
    });
  });
}
