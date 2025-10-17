 import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:riverpod/riverpod.dart';
 import '../../domain/agent_tool.dart';
 import '../../data/agent_repository.dart';
import '../../data/tool_executor.dart';
import '../../data/enhanced_agent_integration.dart';
import '../../data/agent_chat_service.dart';
import '../../../../core/providers/providers.dart';
import '../../domain/agent_tool.dart' as agent_domain;
import '../../../chat/domain/function_call.dart';

/// Agent 仓库 Provider
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final executorManager = ToolExecutorManager();
  return AgentRepository(storage, executorManager);
});

/// 增强 Agent 集成 Provider
final enhancedAgentIntegrationProvider =
    Provider<EnhancedAgentIntegration>((ref) {
  final repository = ref.watch(agentRepositoryProvider);
  return EnhancedAgentIntegration(repository);
});

/// Agent 聊天服务 Provider
final agentChatServiceProvider = Provider<AgentChatService>((ref) {
  final apiClient = ref.watch(openAIApiClientProvider);
  final agentIntegration = ref.watch(enhancedAgentIntegrationProvider);
  return AgentChatService(apiClient, agentIntegration);
});

/// 所有 Agent 配置 Provider
final allAgentsProvider = FutureProvider<List<AgentConfig>>((ref) async {
  final repository = ref.watch(agentRepositoryProvider);
  return repository.getAllAgents();
});

/// 所有工具 Provider
final allToolsProvider = FutureProvider<List<AgentTool>>((ref) async {
  final repository = ref.watch(agentRepositoryProvider);
  return repository.getAllTools();
});

 /// 当前会话的 Agent Provider
 final currentConversationAgentProvider =
     StateProvider.autoDispose<agent_domain.AgentConfig?>((ref) => null);
 
 /// 获取指定 Agent 的工具定义
 final agentToolDefinitionsProvider =
    FutureProvider.family<List<ToolDefinition>, agent_domain.AgentConfig>(
  (ref, agent) async {
    final integration = ref.watch(enhancedAgentIntegrationProvider);
    return integration.getAgentToolDefinitions(agent);
  },
);

/// 创建默认工具
final initializeDefaultToolsProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(agentRepositoryProvider);
  final existingTools = await repository.getAllTools();

  // 如果已经有工具，则不重复创建
  if (existingTools.isNotEmpty) return;

  // 创建默认工具
  await repository.createTool(
    name: 'calculator',
    description: '执行数学计算',
    type: AgentToolType.calculator,
    parameters: {
      'type': 'object',
      'properties': {
        'expression': {
          'type': 'string',
          'description': '要计算的数学表达式',
        },
      },
      'required': ['expression'],
    },
  );

  await repository.createTool(
    name: 'search',
    description: '搜索网络信息',
    type: AgentToolType.search,
    parameters: {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': '搜索关键词',
        },
      },
      'required': ['query'],
    },
  );

  await repository.createTool(
    name: 'file_reader',
    description: '读取文件内容',
    type: AgentToolType.fileOperation,
    parameters: {
      'type': 'object',
      'properties': {
        'operation': {
          'type': 'string',
          'description': '操作类型',
          'enum': ['read', 'write', 'list', 'info'],
        },
        'path': {
          'type': 'string',
          'description': '文件路径',
        },
      },
      'required': ['operation', 'path'],
    },
  );
});
