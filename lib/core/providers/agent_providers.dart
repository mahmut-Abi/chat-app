import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/agent/data/agent_repository.dart';
import '../../features/agent/data/tool_executor.dart';
import '../../features/agent/domain/agent_tool.dart';
import 'storage_providers.dart';

/// Agent Providers
/// Agent configuration and tools related

// ============ Tool Executor Manager ============

/// Tool Executor Manager Provider
final toolExecutorManagerProvider = Provider<ToolExecutorManager>((ref) {
  return ToolExecutorManager();
});

// ============ Agent Repository ============

/// Agent Repository Provider
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  final storage = ref.read(storageServiceProvider);
  final executorManager = ref.read(toolExecutorManagerProvider);
  return AgentRepository(storage, executorManager);
});

// ============ Agent Configurations and Tools ============

/// All Agent Configurations Provider
final agentConfigsProvider = FutureProvider.autoDispose<List<AgentConfig>>((ref) async {
  final repository = ref.watch(agentRepositoryProvider);
  return await repository.getAllAgents();
});

/// All Agent Tools Provider
final agentToolsProvider = FutureProvider.autoDispose<List<AgentTool>>((ref) async {
  final repository = ref.watch(agentRepositoryProvider);
  return await repository.getAllTools();
});
