import '../domain/agent_tool.dart';
import '../../../core/storage/storage_service.dart';
import 'tool_executor.dart';
import 'package:uuid/uuid.dart';

/// Agent 仓库
class AgentRepository {
  final StorageService _storage;
  final ToolExecutorManager _executorManager;

  AgentRepository(this._storage, this._executorManager);

  /// 创建 Agent 配置
  Future<AgentConfig> createAgent({
    required String name,
    String? description,
    required List<String> toolIds,
    String? systemPrompt,
  }) async {
    final agent = AgentConfig(
      id: const Uuid().v4(),
      name: name,
      description: description,
      toolIds: toolIds,
      systemPrompt: systemPrompt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.saveSetting('agent_${agent.id}', agent.toJson());
    return agent;
  }

  /// 创建工具
  Future<AgentTool> createTool({
    required String name,
    required String description,
    required AgentToolType type,
    Map<String, dynamic>? parameters,
  }) async {
    final tool = AgentTool(
      id: const Uuid().v4(),
      name: name,
      description: description,
      type: type,
      parameters: parameters ?? {},
    );

    await _storage.saveSetting('agent_tool_${tool.id}', tool.toJson());
    return tool;
  }

  /// 执行工具
  Future<ToolExecutionResult> executeTool(
    AgentTool tool,
    Map<String, dynamic> input,
  ) async {
    return _executorManager.execute(tool, input);
  }

  /// 获取所有 Agent
  List<AgentConfig> getAllAgents() {
    // TODO: 实现从 storage 读取所有 agent
    return [];
  }

  /// 获取所有工具
  List<AgentTool> getAllTools() {
    // TODO: 实现从 storage 读取所有工具
    return [];
  }

  /// 更新 Agent
  Future<void> updateAgent(AgentConfig agent) async {
    final updated = agent.copyWith(updatedAt: DateTime.now());
    await _storage.saveSetting('agent_${agent.id}', updated.toJson());
  }

  /// 删除 Agent
  Future<void> deleteAgent(String id) async {
    // TODO: 实现从 storage 删除
  }

  /// 更新工具
  Future<void> updateTool(AgentTool tool) async {
    await _storage.saveSetting('agent_tool_${tool.id}', tool.toJson());
  }

  /// 删除工具
  Future<void> deleteTool(String id) async {
    // TODO: 实现从 storage 删除
  }
}
