import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../storage/storage_service.dart';
import '../../features/agent/data/agent_repository.dart';
import '../../features/agent/data/tool_executor.dart';
import '../../features/agent/data/default_agents.dart';
import '../../features/agent/domain/agent_tool.dart';
import '../../features/mcp/data/mcp_repository.dart';
import '../../features/mcp/data/default_mcp_servers.dart';
import 'log_service.dart';

/// 应用初始化服务
///
/// 负责在应用启动时初始化所有必要的数据和配置
class AppInitializationService {
  final StorageService _storage;
  final _log = LogService();

  AppInitializationService(this._storage);

  /// 执行完整的应用初始化
  Future<void> initialize() async {
    _log.info('开始应用初始化');

    try {
      // 1. 初始化默认工具
      await _initializeDefaultTools();

      // 2. 初始化内置 Agent
      await _initializeDefaultAgents();

      // 3. 初始化示例 MCP 服务器（可选）
      await _initializeMcpServers();

      _log.info('应用初始化完成');
    } catch (e, stackTrace) {
      _log.error('应用初始化失败', e, stackTrace);
      // 不抛出异常，让应用继续运行
    }
  }

  /// 初始化默认工具
  Future<void> _initializeDefaultTools() async {
    _log.info('初始化默认工具');

    try {
      final repository = AgentRepository(_storage, ToolExecutorManager());
      final existingTools = await repository.getAllTools();

      if (existingTools.isNotEmpty) {
        _log.info('默认工具已存在，跳过初始化', {'count': existingTools.length});
        return;
      }

      // 创建计算器工具
      await repository.createTool(
        name: 'calculator',
        description: '数学计算器，支持基本运算和复杂表达式',
        type: AgentToolType.calculator,
        parameters: {
          'type': 'object',
          'properties': {
            'expression': {
              'type': 'string',
              'description': '要计算的数学表达式，例如: (2+3)*4',
            },
          },
          'required': ['expression'],
        },
      );

      // 创建搜索工具
      await repository.createTool(
        name: 'search',
        description: '网络搜索工具，帮助查找相关信息',
        type: AgentToolType.search,
        parameters: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string', 'description': '搜索关键词或问题'},
          },
          'required': ['query'],
        },
      );

      // 创建文件操作工具
      await repository.createTool(
        name: 'file_reader',
        description: '文件和目录操作工具，支持读取、写入、列出、查看信息',
        type: AgentToolType.fileOperation,
        parameters: {
          'type': 'object',
          'properties': {
            'operation': {
              'type': 'string',
              'description': '操作类型',
              'enum': ['read', 'write', 'list', 'info'],
            },
            'path': {'type': 'string', 'description': '文件或目录路径'},
            'content': {'type': 'string', 'description': '要写入的内容（仅write操作需要）'},
          },
          'required': ['operation', 'path'],
        },
      );

      _log.info('默认工具初始化完成', {'count': 3});
    } catch (e, stackTrace) {
      _log.error('默认工具初始化失败', e, stackTrace);
      rethrow;
    }
  }

  /// 初始化内置 Agent
  Future<void> _initializeDefaultAgents() async {
    _log.info('初始化内置 Agent');

    try {
      final repository = AgentRepository(_storage, ToolExecutorManager());
      await DefaultAgents.initializeDefaultAgents(repository);

      // 验证初始化结果
      final agents = await repository.getAllAgents();
      final builtInCount = agents.where((a) => a.isBuiltIn).length;

      _log.info('内置 Agent 初始化完成', {
        'total': agents.length,
        'builtIn': builtInCount,
      });
    } catch (e, stackTrace) {
      _log.error('内置 Agent 初始化失败', e, stackTrace);
      rethrow;
    }
  }

  /// 初始化示例 MCP 服务器
  Future<void> _initializeMcpServers() async {
    _log.info('初始化示例 MCP 服务器');

    try {
      final repository = McpRepository(_storage);
      await DefaultMcpServers.initializeQuickStartServers(repository);

      _log.info('示例 MCP 服务器初始化完成');
    } catch (e, stackTrace) {
      _log.error('示例 MCP 服务器初始化失败', e, stackTrace);
      // 不抛出异常，MCP 是可选功能
    }
  }

  /// 重置所有初始化数据
  Future<void> reset() async {
    _log.info('重置应用数据');

    try {
      final agentRepo = AgentRepository(_storage, ToolExecutorManager());
      final mcpRepo = McpRepository(_storage);

      // 删除所有工具和 Agent
      final agents = await agentRepo.getAllAgents();
      for (final agent in agents) {
        await agentRepo.deleteAgent(agent.id);
      }

      final tools = await agentRepo.getAllTools();
      for (final tool in tools) {
        await agentRepo.deleteTool(tool.id);
      }

      // 删除所有 MCP 配置
      final mcpConfigs = await mcpRepo.getAllConfigs();
      for (final config in mcpConfigs) {
        await mcpRepo.deleteConfig(config.id);
      }

      // 重新初始化
      await initialize();

      _log.info('应用数据重置完成');
    } catch (e, stackTrace) {
      _log.error('应用数据重置失败', e, stackTrace);
      rethrow;
    }
  }
}

/// 应用初始化服务 Provider
final appInitializationServiceProvider = Provider<AppInitializationService>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return AppInitializationService(storage);
});

/// 应用初始化状态 Provider
final appInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(appInitializationServiceProvider);
  await service.initialize();
});
