import '../domain/agent_tool.dart';

/// 工具定义常量服务
/// 集中管理所有工具的参数定义，避免重复定义
class ToolDefinitionsService {
  /// 获取工具的默认参数定义
  static Map<String, dynamic> getDefaultParameters(AgentToolType type) {
    return _parameterDefinitions[type] ?? {};
  }

  /// 获取工具的默认描述
  static String getDefaultDescription(AgentToolType type) {
    return _descriptions[type] ?? '';
  }

  /// 所有工具的参数定义（集中管理）
  static const Map<AgentToolType, Map<String, dynamic>> _parameterDefinitions =
      {
        AgentToolType.calculator: {
          'type': 'object',
          'properties': {
            'expression': {'type': 'string', 'description': '要计算的数学表达式'},
          },
          'required': ['expression'],
        },
        AgentToolType.search: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string', 'description': '搜索关键词'},
          },
          'required': ['query'],
        },
        AgentToolType.fileOperation: {
          'type': 'object',
          'properties': {
            'operation': {
              'type': 'string',
              'description': '操作类型 (read/write/list/info)',
              'enum': ['read', 'write', 'list', 'info'],
            },
            'path': {'type': 'string', 'description': '文件或目录路径'},
            'content': {'type': 'string', 'description': '写入的内容（仅 write 操作）'},
          },
          'required': ['operation', 'path'],
        },
        AgentToolType.codeExecution: {'type': 'object', 'properties': {}},
        AgentToolType.custom: {'type': 'object', 'properties': {}},
      };

  /// 工具描述
  static const Map<AgentToolType, String> _descriptions = {
    AgentToolType.calculator: '执行数学表达式计算',
    AgentToolType.search: '搜索相关信息',
    AgentToolType.fileOperation: '执行文件操作',
    AgentToolType.codeExecution: '执行代码片段',
    AgentToolType.custom: '自定义工具',
  };
}
