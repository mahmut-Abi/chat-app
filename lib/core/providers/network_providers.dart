import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../network/openai_api_client.dart';
import '../../features/settings/domain/api_config.dart';


/// Network Providers
/// API clients and connection configuration

// ============ Settings Repository ============

/// Settings Repository Provider (imported from storage_providers)
// This is defined in storage_providers.dart

// ============ API Configuration ============

/// Active API Configuration Provider
final activeApiConfigProvider = FutureProvider.autoDispose<ApiConfig?>((ref) async {
  // For now, return null - actual implementation in settings
  return null;
});

// ============ Dio Client ============

/// Dio Client Provider
final dioClientProvider = Provider<DioClient>((ref) {
  final baseUrl = 'https://api.openai.com/v1';
  final apiKey = '';
  return DioClient(
    baseUrl: baseUrl,
    apiKey: apiKey,
  );
});

// ============ OpenAI API Client ============

/// OpenAI API Client Provider
final openAIApiClientProvider = Provider<OpenAIApiClient>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return OpenAIApiClient(dioClient, null);
});
