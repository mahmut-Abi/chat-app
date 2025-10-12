import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../network/dio_client.dart';
import '../network/openai_api_client.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/domain/api_config.dart';
import '../../features/models/data/models_repository.dart';
import '../constants/app_constants.dart';

// Storage Service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Settings Repository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(storageServiceProvider));
});

// Active API Config
final activeApiConfigProvider = FutureProvider<ApiConfig?>((ref) async {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return settingsRepo.getActiveApiConfig();
});

// DIO Client
final dioClientProvider = Provider<DioClient>((ref) {
  final apiConfig = ref.watch(activeApiConfigProvider).value;
  
  return DioClient(
    baseUrl: apiConfig?.baseUrl ?? AppConstants.defaultApiUrl,
    apiKey: apiConfig?.apiKey ?? '',
    connectTimeout: AppConstants.defaultTimeout,
    receiveTimeout: AppConstants.streamTimeout,
  );
});

// OpenAI API Client
final openAIApiClientProvider = Provider<OpenAIApiClient>((ref) {
  return OpenAIApiClient(ref.watch(dioClientProvider));
});

// Chat Repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.watch(openAIApiClientProvider),
    ref.watch(storageServiceProvider),
  );
});

// Models Repository
final modelsRepositoryProvider = Provider<ModelsRepository>((ref) {
  return ModelsRepository(ref.watch(openAIApiClientProvider));
});

// App Settings
final appSettingsProvider = StateProvider<AppSettings>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return settingsRepo.getSettings();
});
