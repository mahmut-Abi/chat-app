import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/agent_tool.dart';
import 'agent_repository.dart';
import 'tool_executor.dart';
import '../../../core/providers/providers.dart';

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
final agentConfigsProvider = FutureProvider<List<AgentConfig>>((ref) async {
  final repository = ref.read(agentRepositoryProvider);
  return await repository.getAllAgents();
});

/// Agent 工具列表 Provider
final agentToolsProvider = FutureProvider<List<AgentTool>>((ref) async {
  final repository = ref.read(agentRepositoryProvider);
  return await repository.getAllTools();
});
