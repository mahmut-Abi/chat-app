import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:chat_app/features/mcp/data/mcp_repository.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';

import 'mcp_persistence_test.mocks.dart';

/// Bug #27-28: MCP 配置持久化测试
@GenerateMocks([StorageService])
void main() {
  late MockStorageService mockStorage;
  late McpRepository repository;

  setUp(() {
    mockStorage = MockStorageService();
    repository = McpRepository(mockStorage);
  });

  group('MCP Configuration Persistence', () {
    test('should save MCP config to storage', () async {
      // Arrange
      when(
        mockStorage.saveSetting(any, any),
      ).thenAnswer((_) async => Future.value());

      // Act
      await repository.createConfig(
        name: 'Test MCP',
        endpoint: 'http://localhost:3000',
      );

      // Assert
      verify(
        mockStorage.saveSetting(argThat(contains('mcp_config_')), any),
      ).called(1);
    });

    test('should load MCP configs from storage', () async {
      // Arrange
      final config1Data = {
        'id': 'test-1',
        'name': 'MCP 1',
        'connectionType': 'http',
        'endpoint': 'http://localhost:3000',
        'enabled': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final config2Data = {
        'id': 'test-2',
        'name': 'MCP 2',
        'connectionType': 'http',
        'endpoint': 'http://localhost:3001',
        'enabled': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockStorage.getAllKeys()).thenAnswer(
        (_) async => ['mcp_config_test-1', 'mcp_config_test-2', 'other_key'],
      );

      when(mockStorage.getSetting('mcp_config_test-1')).thenReturn(config1Data);
      when(mockStorage.getSetting('mcp_config_test-2')).thenReturn(config2Data);
      when(mockStorage.getSetting('other_key')).thenReturn(null);

      // Act
      final configs = await repository.getAllConfigs();

      // Assert
      expect(configs.length, 2);
      expect(configs[0].id, 'test-1');
      expect(configs[0].name, 'MCP 1');
      expect(configs[1].id, 'test-2');
      expect(configs[1].name, 'MCP 2');
    });

    test('should update existing MCP config', () async {
      // Arrange
      final config = McpConfig(
        id: 'test-mcp-1',
        name: 'Original Name',
        connectionType: McpConnectionType.http,
        endpoint: 'http://localhost:3000',
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedConfig = config.copyWith(name: 'Updated Name');

      when(
        mockStorage.saveSetting(any, any),
      ).thenAnswer((_) async => Future.value());

      // Act
      await repository.updateConfig(updatedConfig);

      // Assert
      verify(
        mockStorage.saveSetting(
          'mcp_config_test-mcp-1',
          argThat(
            predicate((Map<String, dynamic>? data) {
              return data != null && data['name'] == 'Updated Name';
            }),
          ),
        ),
      ).called(1);
    });

    test('should delete MCP config from storage', () async {
      // Arrange
      final configId = 'test-mcp-1';
      when(
        mockStorage.deleteSetting(any),
      ).thenAnswer((_) async => Future.value());

      // Act
      await repository.deleteConfig(configId);

      // Assert
      verify(mockStorage.deleteSetting('mcp_config_test-mcp-1')).called(1);
    });

    test('should handle empty storage gracefully', () async {
      // Arrange
      when(mockStorage.getAllKeys()).thenAnswer((_) async => []);

      // Act
      final configs = await repository.getAllConfigs();

      // Assert
      expect(configs, isEmpty);
    });

    test('should handle corrupted data gracefully', () async {
      // Arrange
      when(
        mockStorage.getAllKeys(),
      ).thenAnswer((_) async => ['mcp_config_corrupted']);
      when(
        mockStorage.getSetting('mcp_config_corrupted'),
      ).thenReturn('invalid json string');

      // Act
      final configs = await repository.getAllConfigs();

      // Assert - 应该返回空列表而不是抛出异常
      expect(configs, isEmpty);
    });
  });

  group('MCP Configuration JSON Serialization', () {
    test('should correctly serialize to JSON', () {
      // Arrange
      final config = McpConfig(
        id: 'test-1',
        name: 'Test MCP',
        connectionType: McpConnectionType.http,
        endpoint: 'http://localhost:3000',
        enabled: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      // Act
      final json = config.toJson();

      // Assert
      expect(json['id'], 'test-1');
      expect(json['name'], 'Test MCP');
      expect(json['endpoint'], 'http://localhost:3000');
      expect(json['enabled'], true);
      expect(json['createdAt'], isNotNull);
      expect(json['updatedAt'], isNotNull);
    });

    test('should correctly deserialize from JSON', () {
      // Arrange
      final json = {
        'id': 'test-1',
        'name': 'Test MCP',
        'connectionType': 'http',
        'endpoint': 'http://localhost:3000',
        'enabled': true,
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2024, 1, 2).toIso8601String(),
      };

      // Act
      final config = McpConfig.fromJson(json);

      // Assert
      expect(config.id, 'test-1');
      expect(config.name, 'Test MCP');
      expect(config.endpoint, 'http://localhost:3000');
      expect(config.enabled, true);
    });

    test('should handle optional fields in JSON', () {
      // Arrange
      final json = {
        'id': 'test-1',
        'name': 'Test MCP',
        'connectionType': 'http',
        'endpoint': 'http://localhost:3000',
        'enabled': true,
        'description': 'Test description',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Act
      final config = McpConfig.fromJson(json);

      // Assert
      expect(config.description, 'Test description');
    });
  });
}
