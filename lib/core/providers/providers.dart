import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../network/dio_client.dart';
import '../network/openai_api_client.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/domain/conversation.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/domain/api_config.dart';
import '../../features/models/data/models_repository.dart';
import '../../features/prompts/data/prompts_repository.dart';
import '../../features/prompts/domain/prompt_template.dart';
import '../../features/token_usage/data/token_usage_repository.dart';
import '../constants/app_constants.dart';
import '../utils/token_counter.dart';
import 'package:flutter/foundation.dart';
import '../../features/mcp/data/mcp_repository.dart';
import '../../features/mcp/domain/mcp_config.dart';
import '../../features/mcp/data/mcp_tools_service.dart';
import '../../features/mcp/data/mcp_unified_resources_service.dart';
import '../../features/mcp/data/mcp_resources_client.dart';
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

/// MCP 连接状态 Provider - 改进的單次检查
/// 帧控制不会自动刷新，配置刐拒无效的供应商优化
/// 改版本：每次不会缓存，始终从仓库获取实時状态
final mcpConnectionStatusProvider =
    Provider.family<McpConnectionStatus, String>((ref, configId) {
      final repository = ref.watch(mcpRepositoryProvider);
      final status = repository.getConnectionStatus(configId);
      return status ?? McpConnectionStatus.disconnected;
    });

/// MCP 工具列表 Provider
final mcpToolsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, configId) async {
      final repository = ref.watch(mcpRepositoryProvider);
      final client = repository.getClient(configId);
      if (client == null) {
        return [];
      }
      try {
        final tools = await client.listTools();
        return tools ?? [];
      } catch (e) {
        return [];
      }
    });

/// MCP 所有工具 Provider
final mcpAllToolsProvider = FutureProvider.autoDispose<List<McpToolWithConfig>>(
  (ref) async {
    final repository = ref.watch(mcpRepositoryProvider);
    final toolsService = McpToolsService(repository);
    return await toolsService.getAllToolsWithConfig();
  },
);

/// MCP 所有资源 Provider (工具、提示词、资源)
final mcpResourcesProvider = FutureProvider.autoDispose
    .family<MCPAllResources, String>((ref, configId) async {
      final repository = ref.watch(mcpRepositoryProvider);
      final service = McpUnifiedResourcesService(repository);
      return await service.getAllResources(configId);
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
final activeApiConfigProvider = FutureProvider.autoDispose<ApiConfig?>((
  ref,
) async {
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
  final apiConfig = ref.watch(activeApiConfigProvider).value;
  final provider = apiConfig?.provider;
  return OpenAIApiClient(ref.watch(dioClientProvider), provider);
});

// Chat Repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.watch(openAIApiClientProvider),
    ref.watch(storageServiceProvider),
    ref.watch(tokenUsageRepositoryProvider),
  );
});

// Models Repository
final modelsRepositoryProvider = Provider<ModelsRepository>((ref) {
  return ModelsRepository(
    ref.watch(openAIApiClientProvider),
    ref.watch(storageServiceProvider),
  );
});

// App Settings
final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(() {
      return AppSettingsNotifier();
    });

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    if (kDebugMode) {
      print('AppSettingsNotifier.build() called');
    }
    try {
      final settingsRepo = ref.watch(settingsRepositoryProvider);
      final settings = await settingsRepo.getSettings();
      if (kDebugMode) {
        print('Loaded settings: ${settings.toJson()}');
      }
      return settings;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load settings: $e');
      }
      return const AppSettings();
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    if (kDebugMode) {
      print('AppSettingsNotifier.updateSettings() called');
      print('New settings: ${settings.toJson()}');
    }
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.saveSettings(settings);
    state = AsyncValue.data(settings);
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

// Token Usage Repository Provider
final tokenUsageRepositoryProvider = Provider<TokenUsageRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TokenUsageRepository(storage);
});

// Conversations Provider
final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((
  ref,
) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  if (kDebugMode) {
    print('🔄 conversationsProvider: 重新获取数据');
  }
  return chatRepo.getAllConversations();
});

// Conversation Groups Provider
final conversationGroupsProvider =
    FutureProvider.autoDispose<List<ConversationGroup>>((ref) async {
      final chatRepo = ref.watch(chatRepositoryProvider);
      if (kDebugMode) {
        print('🔄 conversationGroupsProvider: 重新获取数据');
      }
      return chatRepo.getAllGroups();
    });
