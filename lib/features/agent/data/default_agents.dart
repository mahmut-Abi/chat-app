import 'agent_repository.dart';
import '../domain/agent_tool.dart';
import '../../../core/services/log_service.dart';

/// 默认 Agent 配置
class DefaultAgents {
  static final _log = LogService();

  /// 初始化默认 Agent
  static Future<void> initializeDefaultAgents(
    AgentRepository repository,
  ) async {
    // DISABLED - no built-in agents needed
    return;
    _log.info('开始初始化默认 Agent');

    try {
      // 检查是否已经初始化过
      final existingAgents = await repository.getAllAgents();
      // 检查是否有被删除的内置 Agent ID
      final deletedBuiltInIds = await repository.getDeletedBuiltInAgentIds();
      final hasDefaultAgents = existingAgents.any((a) => a.isBuiltIn);

      if (hasDefaultAgents) {
        _log.info('默认 Agent 已存在，跳过初始化');
        return;
      }

      // 如果有被删除的内置 Agent，不重新创建它们
      if (deletedBuiltInIds.isNotEmpty) {
        _log.info('检测到用户已删除的内置 Agent，跳过初始化', {
          'deletedCount': deletedBuiltInIds.length,
        });
        return;
      }

      // 获取所有工具
      final tools = await repository.getAllTools();
      if (tools.isEmpty) {
        _log.warning('没有可用的工具，跳过 Agent 初始化');
        return;
      }

      // 查找工具
      AgentTool? calcTool;
      AgentTool? searchTool;
      AgentTool? fileTool;

      for (final tool in tools) {
        if (tool.type == AgentToolType.calculator) {
          calcTool = tool;
        } else if (tool.type == AgentToolType.search) {
          searchTool = tool;
        } else if (tool.type == AgentToolType.fileOperation) {
          fileTool = tool;
        }
      }

      _log.info('找到的工具', {
        'calculator': calcTool != null,
        'search': searchTool != null,
        'file': fileTool != null,
      });

      // 创建默认 Agent
      final defaultAgents = <Future<AgentConfig>>[];

      // 1. 通用助手
      if (calcTool != null && searchTool != null) {
        defaultAgents.add(
          repository.createAgent(
            name: '通用助手',
            description: '全能型助手，可以帮助你解答问题、进行计算和搜索',
            toolIds: [calcTool.id, searchTool.id],
            systemPrompt: '''你是一个友好、专业的通用助手。

你可以：
1. 回答各类问题
2. 进行数学计算
3. 搜索相关信息

请用清晰、准确的方式回答用户的问题。''',
            isBuiltIn: true,
            iconName: 'assistant',
          ),
        );
      }

      // 2. 数学专家
      if (calcTool != null) {
        defaultAgents.add(
          repository.createAgent(
            name: '数学专家',
            description: '专注于数学计算和问题解答',
            toolIds: [calcTool.id],
            systemPrompt: '''你是一位经验丰富的数学专家。

你擅长：
1. 代数计算和方程求解
2. 几何问题分析
3. 统计和概率计算
4. 数学概念解释

请提供详细的解题步骤和清晰的解释。''',
            isBuiltIn: true,
            iconName: 'calculate',
          ),
        );
      }

      // 3. 研究助手
      if (searchTool != null && fileTool != null) {
        defaultAgents.add(
          repository.createAgent(
            name: '研究助手',
            description: '帮助进行学术研究和信息收集',
            toolIds: [searchTool.id, fileTool.id],
            systemPrompt: '''你是一个专业的研究助手。

你可以帮助：
1. 搜索和收集相关文献
2. 整理和分析资料
3. 提供研究思路和建议
4. 管理研究文档

请提供结构化的研究支持。''',
            isBuiltIn: true,
            iconName: 'search',
          ),
        );
      }

      // 4. 文件管理员
      if (fileTool != null) {
        defaultAgents.add(
          repository.createAgent(
            name: '文件管理员',
            description: '专注于文件和目录管理',
            toolIds: [fileTool.id],
            systemPrompt: '''你是一个高效的文件管理助手。

你可以：
1. 读取和写入文件
2. 列出目录内容
3. 获取文件信息
4. 整理和组织文件

请帮助用户高效管理文件。''',
            isBuiltIn: true,
            iconName: 'folder',
          ),
        );
      }

      // 5. 编程助手
      if (fileTool != null && searchTool != null) {
        defaultAgents.add(
          repository.createAgent(
            name: '编程助手',
            description: '帮助解决编程问题和代码审查',
            toolIds: [fileTool.id, searchTool.id],
            systemPrompt: '''你是一个经验丰富的编程助手。

你擅长：
1. 代码编写和审查
2. 调试和问题排查
3. 技术文档查询
4. 最佳实践建议

请提供清晰的代码示例和解释。''',
            isBuiltIn: true,
            iconName: 'code',
          ),
        );
      }

      // 等待所有 Agent 创建完成
      await Future.wait(defaultAgents);

      _log.info('成功创建 ${defaultAgents.length} 个默认 Agent');
    } catch (e, stackTrace) {
      _log.error('初始化默认 Agent 失败', e, stackTrace);
    }
  }

  /// 重置默认 Agent（删除并重新创建）
  static Future<void> resetDefaultAgents(AgentRepository repository) async {
    _log.info('重置默认 Agent');

    try {
      // 删除所有内置 Agent
      final existingAgents = await repository.getAllAgents();
      for (final agent in existingAgents) {
        if (agent.isBuiltIn) {
          await repository.deleteAgent(agent.id);
        }
      }

      // 清除已删除的内置 Agent ID 列表
      await repository.clearDeletedBuiltInAgents();

      // 重新创建
      await initializeDefaultAgents(repository);

      _log.info('默认 Agent 重置完成');
    } catch (e, stackTrace) {
      _log.error('重置默认 Agent 失败', e, stackTrace);
    }
  }
}
