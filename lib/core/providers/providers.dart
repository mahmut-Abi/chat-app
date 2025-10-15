import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../network/dio_client.dart';
import '../network/openai_api_client.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/domain/api_config.dart';
import '../../features/models/data/models_repository.dart';
import '../../features/prompts/data/prompts_repository.dart';
import '../../features/prompts/domain/prompt_template.dart';
import '../constants/app_constants.dart';
import '../utils/token_counter.dart';
import 'package:flutter/foundation.dart';
import '../../features/mcp/data/mcp_repository.dart';
import '../../features/mcp/domain/mcp_config.dart';
import '../../features/agent/data/agent_repository.dart';
import '../../features/agent/data/tool_executor.dart';
import '../../features/agent/domain/agent_tool.dart';
import '../services/log_service.dart';

// Storage Service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Log Service
final logServiceProvider = Provider<LogService>((ref) {
  return LogService();
});

// Settings Repository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(storageServiceProvider));
});

// ============ MCP Providers ============

/// MCP Repository Provider
final mcpRepositoryProvider = Provider<McpRepository>((ref) {
  final storage = ref.read(storageServiceProvider);
  return McpRepository(storage);
});

/// MCP 配置列表 Provider
final mcpConfigsProvider = FutureProvider.autoDispose<List<McpConfig>>((
  ref,
) async {
  final repository = ref.watch(mcpRepositoryProvider);
  return await repository.getAllConfigs();
});

/// MCP 连接状态 Provider
final mcpConnectionStatusProvider =
    Provider.family<McpConnectionStatus, String>((ref, configId) {
      final repository = ref.watch(mcpRepositoryProvider);
      return repository.getConnectionStatus(configId) ??
          McpConnectionStatus.disconnected;
    });

// ============ Agent Providers ============

/// Tool Executor Manager Provider
final toolExecutorManagerProvider = Provider<ToolExecutorManager>((ref) {
  return ToolExecutorManager();
});

/// Agent Repository Provider
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  final storage = ref.read(storageServiceProvider);
  final executorManager = ref.read(toolExecutorManagerProvider);
  return AgentRepository(storage, executorManager);
});

/// Agent 配置列表 Provider
final agentConfigsProvider = FutureProvider.autoDispose<List<AgentConfig>>((
  ref,
) async {
  final repository = ref.watch(agentRepositoryProvider);
  return await repository.getAllAgents();
});

/// Agent 工具列表 Provider
final agentToolsProvider = FutureProvider.autoDispose<List<AgentTool>>((
  ref,
) async {
  final repository = ref.watch(agentRepositoryProvider);
  return await repository.getAllTools();
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
    proxyUrl: apiConfig?.proxyUrl,
    proxyUsername: apiConfig?.proxyUsername,
    proxyPassword: apiConfig?.proxyPassword,
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
final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  () {
    return AppSettingsNotifier();
  },
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    if (kDebugMode) {
      print('AppSettingsNotifier.build() called');
    }
    try {
      final settingsRepo = ref.watch(settingsRepositoryProvider);
      final settings = settingsRepo.getSettings();
      if (kDebugMode) {
        print('Loaded settings: ${settings.toJson()}');
      }
      return settings;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load settings: $e');
      }
      // 如果加载设置失败,返回默认设置
      return const AppSettings();
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    if (kDebugMode) {
      print('AppSettingsNotifier.updateSettings() called');
      print('New settings: ${settings.toJson()}');
    }
    // 先持久化到存储
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.saveSettings(settings);
    // 再更新内存状态
    state = settings;
    if (kDebugMode) {
      print('Settings saved and state updated');
    }
  }
}

// Token Counter
final tokenCounterProvider = Provider<TokenCounter>((ref) {
  return TokenCounter();
});

// Prompts Repository Provider
final promptsRepositoryProvider = Provider<PromptsRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PromptsRepository(storage);
});

// Prompt Templates Provider
final promptTemplatesProvider =
    FutureProvider.autoDispose<List<PromptTemplate>>((ref) async {
      final promptsRepo = ref.watch(promptsRepositoryProvider);
      return await promptsRepo.getAllTemplates();
    });
