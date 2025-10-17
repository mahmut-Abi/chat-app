import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/features/settings/data/settings_repository.dart';
import 'package:chat_app/features/settings/domain/api_config.dart';
import 'package:chat_app/core/storage/storage_service.dart';

@GenerateMocks([StorageService])
import 'settings_repository_test.mocks.dart';

void main() {
  late SettingsRepository repository;
  late MockStorageService mockStorage;

  setUp(() {
    mockStorage = MockStorageService();
    repository = SettingsRepository(mockStorage);
  });

  group('应用设置', () {
    test('应该正确保存设置', () async {
      when(mockStorage.saveAppSettings(any)).thenAnswer((_) async => {});

      const settings = AppSettings(
        themeMode: 'dark',
        language: 'zh',
        fontSize: 16.0,
        backgroundImage: 'test.jpg',
        backgroundOpacity: 0.5,
      );

      await repository.saveSettings(settings);

      verify(mockStorage.saveAppSettings(any)).called(1);
    });

    test('应该正确读取设置', () async {
      final mockSettings = {
        'themeMode': 'dark',
        'language': 'zh',
        'fontSize': 16.0,
        'enableMarkdown': true,
        'enableCodeHighlight': true,
        'enableLatex': false,
        'backgroundImage': 'test.jpg',
        'backgroundOpacity': 0.5,
      };

      when(mockStorage.getAppSettings()).thenAnswer((_) async => mockSettings);

      final settings = await repository.getSettings();

      expect(settings.themeMode, 'dark');
      expect(settings.language, 'zh');
      expect(settings.fontSize, 16.0);
      expect(settings.backgroundImage, 'test.jpg');
      expect(settings.backgroundOpacity, 0.5);
    });

    test('应该返回默认设置当无保存数据', () async {
      when(mockStorage.getAppSettings()).thenAnswer((_) async => null);

      final settings = await repository.getSettings();

      expect(settings.themeMode, 'system');
      expect(settings.language, 'en');
      expect(settings.fontSize, 14.0);
    });
  });

  group('API 配置', () {
    test('应该正确创建 API 配置', () async {
      when(mockStorage.saveApiConfig(any, any)).thenAnswer((_) async => {});

      final config = await repository.createApiConfig(
        name: 'Test API',
        provider: 'openai',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(config.name, 'Test API');
      expect(config.provider, 'openai');
      expect(config.baseUrl, 'https://api.openai.com/v1');
      verify(mockStorage.saveApiConfig(any, any)).called(1);
    });

    test('应该正确读取 API 配置', () async {
      final mockConfig = {
        'id': 'config-1',
        'name': 'Test API',
        'provider': 'openai',
        'baseUrl': 'https://api.openai.com/v1',
        'apiKey': 'test-key',
        'isActive': true,
        'defaultModel': 'gpt-4',
        'temperature': 0.7,
        'maxTokens': 2000,
        'topP': 1.0,
        'frequencyPenalty': 0.0,
        'presencePenalty': 0.0,
      };

      when(
        mockStorage.getApiConfig('config-1'),
      ).thenAnswer((_) async => mockConfig);

      final config = await repository.getApiConfig('config-1');

      expect(config, isNotNull);
      expect(config!.name, 'Test API');
      expect(config.provider, 'openai');
    });

    test('应该正确设置活动 API 配置', () async {
      final mockConfigs = [
        {
          'id': 'config-1',
          'name': 'API 1',
          'provider': 'openai',
          'baseUrl': 'https://api.openai.com/v1',
          'apiKey': 'key-1',
          'isActive': false,
          'defaultModel': 'gpt-4',
          'temperature': 0.7,
          'maxTokens': 2000,
          'topP': 1.0,
          'frequencyPenalty': 0.0,
          'presencePenalty': 0.0,
        },
        {
          'id': 'config-2',
          'name': 'API 2',
          'provider': 'custom',
          'baseUrl': 'https://custom.api.com/v1',
          'apiKey': 'key-2',
          'isActive': true,
          'defaultModel': 'gpt-4',
          'temperature': 0.7,
          'maxTokens': 2000,
          'topP': 1.0,
          'frequencyPenalty': 0.0,
          'presencePenalty': 0.0,
        },
      ];

      when(mockStorage.getAllApiConfigs()).thenAnswer((_) async => mockConfigs);
      when(mockStorage.getApiConfig(any)).thenAnswer(
        (invocation) async => mockConfigs.firstWhere(
          (c) => c['id'] == invocation.positionalArguments[0],
        ),
      );
      when(mockStorage.saveApiConfig(any, any)).thenAnswer((_) async => {});

      await repository.setActiveApiConfig('config-1');

      // 验证所有配置都被保存
      verify(mockStorage.saveApiConfig(any, any)).called(2);
    });
  });
}
