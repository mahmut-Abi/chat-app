import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/models/data/models_repository.dart';
import '../../features/prompts/data/prompts_repository.dart';
import '../../features/prompts/domain/prompt_template.dart';
import '../../features/token_usage/data/token_usage_repository.dart';
import '../utils/token_counter.dart';
import 'storage_providers.dart';
import 'network_providers.dart';

/// Models, Prompts, Token Providers

// ============ Models Repository ============

/// Models Repository Provider
final modelsRepositoryProvider = Provider<ModelsRepository>((ref) {
  final openAIClient = ref.watch(openAIApiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return ModelsRepository(
    openAIClient,
    storage,
  );
});

// ============ Prompts Repository ============

/// Prompts Repository Provider
final promptsRepositoryProvider = Provider<PromptsRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PromptsRepository(storage);
});

/// All Prompt Templates Provider
final promptTemplatesProvider =
    FutureProvider.autoDispose<List<PromptTemplate>>((ref) async {
      final promptsRepo = ref.watch(promptsRepositoryProvider);
      return await promptsRepo.getAllTemplates();
    });

// ============ Token Usage ============

/// Token Counter Provider
final tokenCounterProvider = Provider<TokenCounter>((ref) {
  return TokenCounter();
});

/// Token Usage Repository Provider
final tokenUsageRepositoryProvider = Provider<TokenUsageRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TokenUsageRepository(storage);
});
