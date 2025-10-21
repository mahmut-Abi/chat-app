import 'dart:convert';
import '../storage/storage_service.dart';

class DataExportImport {
  final StorageService _storage;

  DataExportImport(this._storage);

  Future<String> exportAllData() async {
    final conversations = _storage.getAllConversations();
    final apiConfigs = await _storage.getAllApiConfigs();
    final appSettings = await _storage.getAppSettings();
    final mcpConfigs = await _storage.getAllMcpConfigs();
    final agentConfigs = await _storage.getAllAgentConfigs();
    final agentTools = await _storage.getAllAgentTools();

    final data = {
    'version': '1.0.0',
    'exportDate': DateTime.now().toIso8601String(),
    'conversations': conversations,
    'apiConfigs': apiConfigs,
    'appSettings': appSettings,
    'mcpConfigs': mcpConfigs,
    'agentConfigs': agentConfigs,
    'agentTools': agentTools,
    'groups': _storage.getAllGroups(),
    'promptTemplates': _storage.getAllPromptTemplates(),
    'models': _storage.getAllModels(),
    };

    return jsonEncode(data);
  }

  Future<Map<String, dynamic>> importData(String jsonData) async {
   try {
     final data = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // 验证数据的有效性
      if (data.isEmpty) {
        return {'success': false, 'error': 'Empty import data'};
      }
      
      // 验证版本不積容
      final version = data['version'];
      if (version != null && version != '1.0.0') {
        // 记录版本协议不匹配的警告，但仍然尝试导入
        _log.warning('Data version mismatch', {'version': version, 'expected': '1.0.0'});
      }

      int conversationsCount = 0;
      int apiConfigsCount = 0;
      bool appSettingsImported = false;
      int mcpConfigsCount = 0;
      int agentConfigsCount = 0;
      int agentToolsCount = 0;
      int groupsCount = 0;
      int promptTemplatesCount = 0;
      int modelsCount = 0;

      // 导入应用设置（包括背景图片）
      if (data.containsKey('appSettings') && data['appSettings'] != null) {
        final appSettings = data['appSettings'] as Map<String, dynamic>;
        await _storage.saveAppSettings(appSettings);
        appSettingsImported = true;
      }

      // 导入对话
      if (data.containsKey('conversations')) {
        final conversations = data['conversations'] as List;
        for (final conv in conversations) {
          final convMap = conv as Map<String, dynamic>;
          await _storage.saveConversation(convMap['id'] as String, convMap);
          conversationsCount++;
        }
      }

      // 导入 API 配置
      if (data.containsKey('apiConfigs')) {
        final apiConfigs = data['apiConfigs'] as List;
        for (final config in apiConfigs) {
          final configMap = config as Map<String, dynamic>;
          await _storage.saveApiConfig(configMap['id'] as String, configMap);
          apiConfigsCount++;
        }
      }

      // 导入 MCP 配置
      if (data.containsKey('mcpConfigs')) {
        final mcpConfigs = data['mcpConfigs'] as List;
        for (final config in mcpConfigs) {
          final configMap = config as Map<String, dynamic>;
          await _storage.saveMcpConfig(configMap['id'] as String, configMap);
          mcpConfigsCount++;
        }
      }

      // 导入 Agent 配置
      if (data.containsKey('agentConfigs')) {
        final agentConfigs = data['agentConfigs'] as List;
        for (final config in agentConfigs) {
          final configMap = config as Map<String, dynamic>;
          await _storage.saveAgentConfig(configMap['id'] as String, configMap);
          agentConfigsCount++;
        }
      }

      // 导入 Agent 工具
      if (data.containsKey('agentTools')) {
        final agentTools = data['agentTools'] as List;
        for (final tool in agentTools) {
          final toolMap = tool as Map<String, dynamic>;
          // 使用 saveSetting 因为工具使用 agent_tool_ 前缀
          await _storage.saveSetting('agent_tool_' + (toolMap['id'] as String), jsonEncode(toolMap));
          agentToolsCount++;
        }
      }

      // 导入对话分组
      if (data.containsKey('groups')) {
        final groups = data['groups'] as List;
        for (final group in groups) {
          final groupMap = group as Map<String, dynamic>;
          await _storage.saveGroup(groupMap['id'] as String, groupMap);
          groupsCount++;
        }
      }

      // 导入提示词模板
      if (data.containsKey('promptTemplates')) {
        final templates = data['promptTemplates'] as List;
        for (final template in templates) {
          final templateMap = template as Map<String, dynamic>;
          await _storage.savePromptTemplate(templateMap['id'] as String, templateMap);
          promptTemplatesCount++;
        }
      }

      // 导入模型列表
      if (data.containsKey('models')) {
        final models = data['models'] as List;
        for (final model in models) {
          final modelMap = model as Map<String, dynamic>;
          await _storage.saveModel(modelMap['id'] as String, modelMap);
          modelsCount++;
        }
      }

      return {
        'success': true,
        'conversationsCount': conversationsCount,
        'apiConfigsCount': apiConfigsCount,
        'appSettingsImported': appSettingsImported,
        'mcpConfigsCount': mcpConfigsCount,
        'agentConfigsCount': agentConfigsCount,
        'agentToolsCount': agentToolsCount,
        'groupsCount': groupsCount,
        'promptTemplatesCount': promptTemplatesCount,
        'modelsCount': modelsCount,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
