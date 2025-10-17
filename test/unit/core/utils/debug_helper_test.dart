/// 调试工具测试

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/utils/debug_helper.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:chat_app/features/settings/data/settings_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'debug_helper_test.mocks.dart';

@GenerateMocks([StorageService, SettingsRepository])
void main() {
  group('DebugHelper', () {
    late MockStorageService mockStorage;
    late MockSettingsRepository mockSettingsRepo;

    setUp(() {
      mockStorage = MockStorageService();
      mockSettingsRepo = MockSettingsRepository();
    });

    test('应该能够打印 API 配置调试信息', () async {
      when(mockStorage.getAllKeys()).thenAnswer((_) async => ['key1', 'key2']);
      when(mockSettingsRepo.getAllApiConfigs()).thenAnswer((_) async => []);
      when(mockSettingsRepo.getActiveApiConfig()).thenAnswer((_) async => null);

      await expectLater(
        DebugHelper.printApiConfigDebugInfo(mockStorage, mockSettingsRepo),
        completes,
      );
    });
  });
}
