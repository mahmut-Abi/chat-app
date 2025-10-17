import '../domain/agent_tool.dart';
import '../../../core/storage/storage_service.dart';
import 'tool_executor.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/log_service.dart';
import 'dart:convert';

/// Agent 仓库
class AgentRepository {
  final StorageService _storage;
  final ToolExecutorManager _executorManager;
  final _log = LogService();

  AgentRepository(this._storage, this._executorManager);

  /// 创建 Agent 配置
  Future<AgentConfig> createAgent({
    required String name,
    String? description,
    required List<String> toolIds,
    String? systemPrompt,
  }) async {
    _log.info('创建 Agent 配置', {
      'name': name,
      'toolsCount': toolIds.length,
      'hasSystemPrompt': systemPrompt != null,
    });

    final agent = AgentConfig(
      id: const Uuid().v4(),
      name: name,
      description: description,
      toolIds: toolIds,
      systemPrompt: systemPrompt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.saveSetting('agent_${agent.id}', jsonEncode(agent.toJson()));
    _log.debug('Agent 配置已保存', {'agentId': agent.id});
    return agent;
  }

  /// 创建工具
  Future<AgentTool> createTool({
    required String name,
    required String description,
    required AgentToolType type,
    Map<String, dynamic>? parameters,
  }) async {
    _log.info('创建 Agent 工具', {
      'name': name,
      'type': type.toString(),
      'hasParameters': parameters?.isNotEmpty ?? false,
    });

    final tool = AgentTool(
      id: const Uuid().v4(),
      name: name,
      description: description,
      type: type,
      parameters: parameters ?? {},
    );

    await _storage.saveSetting(
      'agent_tool_${tool.id}',
      jsonEncode(tool.toJson()),
    );
    _log.debug('工具已保存', {'toolId': tool.id});
    return tool;
  }

  /// 执行工具
  Future<ToolExecutionResult> executeTool(
    AgentTool tool,
    Map<String, dynamic> input,
  ) async {
    _log.info('开始执行工具', {
      'toolName': tool.name,
      'toolType': tool.type.toString(),
      'inputKeys': input.keys.toList(),
    });

    final result = await _executorManager.execute(tool, input);

    _log.info('工具执行完成', {
      'toolName': tool.name,
      'success': result.success,
      'hasResult': result.result != null,
    });

    return result;
  }

  /// 获取所有 Agent
  Future<List<AgentConfig>> getAllAgents() async {
    _log.debug('获取所有 Agent 配置');
    try {
      final keys = await _storage.getAllKeys();
      final agentKeys = keys
          .where((k) => k.startsWith('agent_') && !k.contains('tool'))
          .toList();

      final agents = <AgentConfig>[];
      for (final key in agentKeys) {
        final data = _storage.getSetting(key);
        if (data != null) {
          try {
            // 支持两种格式: 字符串(新) 和 Map(旧)
            final Map<String, dynamic> json;
            if (data is String) {
              json = jsonDecode(data) as Map<String, dynamic>;
            } else if (data is Map<String, dynamic>) {
              json = data;
            } else {
              continue;
            }
            agents.add(AgentConfig.fromJson(json));
          } catch (e) {
            // 跳过无效的配置
          }
        }
      }

      return agents;
    } catch (e) {
      return [];
    }
  }

  /// 获取所有工具
  Future<List<AgentTool>> getAllTools() async {
    try {
      final keys = await _storage.getAllKeys();
      final toolKeys = keys.where((k) => k.startsWith('agent_tool_')).toList();

      final tools = <AgentTool>[];
      for (final key in toolKeys) {
        final data = _storage.getSetting(key);
        if (data != null) {
          try {
            // 支持两种格式: 字符串(新) 和 Map(旧)
            final Map<String, dynamic> json;
            if (data is String) {
              json = jsonDecode(data) as Map<String, dynamic>;
            } else if (data is Map<String, dynamic>) {
              json = data;
            } else {
              continue;
            }
            tools.add(AgentTool.fromJson(json));
          } catch (e) {
            // 跳过无效的工具
          }
        }
      }

      return tools;
    } catch (e) {
      return [];
    }
  }

  /// 更新 Agent
  Future<void> updateAgent(AgentConfig agent) async {
    final updated = agent.copyWith(updatedAt: DateTime.now());
    await _storage.saveSetting(
      'agent_${agent.id}',
      jsonEncode(updated.toJson()),
    );
  }

  /// 保存 Agent 配置
  Future<void> saveConfig(AgentConfig agent) async {
    final updated = agent.copyWith(updatedAt: DateTime.now());
    await _storage.saveSetting(
      'agent_${agent.id}',
      jsonEncode(updated.toJson()),
    );
  }

  /// 删除 Agent
  Future<void> deleteAgent(String id) async {
    _log.info('删除 Agent: id=$id');
    await _storage.deleteSetting('agent_$id');
  }

  /// 更新工具
  Future<void> updateTool(AgentTool tool) async {
    await _storage.saveSetting(
      'agent_tool_${tool.id}',
      jsonEncode(tool.toJson()),
    );
  }

  /// 更新工具状态
  Future<void> updateToolStatus(String id, bool enabled) async {
    final keys = await _storage.getAllKeys();
    final toolKey = keys.firstWhere(
      (k) => k == 'agent_tool_$id',
      orElse: () => '',
    );

    if (toolKey.isEmpty) return;

    final data = _storage.getSetting(toolKey);
    if (data != null) {
      try {
        // 支持两种格式: 字符串(新) 和 Map(旧)
        final Map<String, dynamic> json;
        if (data is String) {
          json = jsonDecode(data) as Map<String, dynamic>;
        } else if (data is Map<String, dynamic>) {
          json = data;
        } else {
          return;
        }
        final tool = AgentTool.fromJson(json);
        final updated = AgentTool(
          id: tool.id,
          name: tool.name,
          description: tool.description,
          type: tool.type,
          parameters: tool.parameters,
          enabled: enabled,
          iconName: tool.iconName,
        );
        await updateTool(updated);
      } catch (e) {
        // 忽略错误
      }
    }
  }

  /// 删除工具
  Future<void> deleteTool(String id) async {
    _log.info('删除工具: id=$id');
    await _storage.deleteSetting('agent_tool_$id');
  }
}
