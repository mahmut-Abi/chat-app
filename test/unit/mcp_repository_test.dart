import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/features/mcp/data/mcp_repository.dart';
import 'package:chat_app/features/mcp/domain/mcp_config.dart';
import 'package:chat_app/core/storage/storage_service.dart';

@GenerateMocks([StorageService])
import 'mcp_repository_test.mocks.dart';

void main() {
  late MockStorageService mockStorage;
  late McpRepository repository;

  setUp(() {
    mockStorage = MockStorageService();
    repository = McpRepository(mockStorage);
  });

  group('McpRepository', () {
    test('应该成功创建 MCP 配置', () async {
      when(mockStorage.saveSetting(any, any)).thenAnswer((_) async => {});

      final config = await repository.createConfig(
        name: 'Test MCP',
        endpoint: 'http://localhost:3000',
        description: 'Test Description',
      );

      expect(config.name, 'Test MCP');
      expect(config.endpoint, 'http://localhost:3000');
      expect(config.description, 'Test Description');
      verify(mockStorage.saveSetting(any, any)).called(1);
    });

    test('应该成功获取所有 MCP 配置', () async {
      final testConfig = McpConfig(
        id: 'test-id',
        name: 'Test MCP',
        endpoint: 'http://localhost:3000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        mockStorage.getAllKeys(),
      ).thenAnswer((_) async => ['mcp_config_test-id', 'other_key']);
      when(
        mockStorage.getSetting('mcp_config_test-id'),
      ).thenReturn(testConfig.toJson());

      final configs = await repository.getAllConfigs();

      expect(configs.length, 1);
      expect(configs.first.id, 'test-id');
      expect(configs.first.name, 'Test MCP');
    });

    test('应该成功更新 MCP 配置', () async {
      final config = McpConfig(
        id: 'test-id',
        name: 'Original Name',
        endpoint: 'http://localhost:3000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockStorage.saveSetting(any, any)).thenAnswer((_) async => {});

      await repository.updateConfig(config);

      verify(mockStorage.saveSetting('mcp_config_${config.id}', any)).called(1);
    });

    test('应该成功删除 MCP 配置', () async {
      when(mockStorage.deleteSetting(any)).thenAnswer((_) async => {});

      await repository.deleteConfig('test-id');

      verify(mockStorage.deleteSetting('mcp_config_test-id')).called(1);
    });
  });
}
