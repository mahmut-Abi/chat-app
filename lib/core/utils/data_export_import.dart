import 'dart:convert';
import '../storage/storage_service.dart';
import '../services/log_service.dart';

class DataExportImport {
  final StorageService _storage;
  final LogService _log = LogService();

  DataExportImport(this._storage);

  Future<String> exportAllData() async {
    try {
      final conversations = _storage.getAllConversations();
      final apiConfigs = await _storage.getAllApiConfigs();
      final appSettings = await _storage.getAppSettings();
      final mcpConfigs = await _storage.getAllMcpConfigs();
      final agentConfigs = await _storage.getAllAgentConfigs();
      final agentTools = await _storage.getAllAgentTools();

      final data = {
        'version': '1.1.0',
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

      _log.info('Export completed');
      return jsonEncode(data);
    } catch (e, st) {
      _log.error('Export failed', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> importData(String jsonData) async {
    try {
      final Map<String, dynamic> data;
      try {
        data = jsonDecode(jsonData) as Map<String, dynamic>;
      } catch (e) {
        _log.error('Failed to parse JSON', e);
        return {'success': false, 'error': 'Invalid JSON format'};
      }

      if (data.isEmpty) {
        return {'success': false, 'error': 'Empty import data'};
      }

      final version = data['version'] as String? ?? '1.0.0';
      _log.info('Starting import', {'version': version});

      int conversationsCount = 0;
      int apiConfigsCount = 0;
      bool appSettingsImported = false;
      int mcpConfigsCount = 0;
      int agentConfigsCount = 0;
      int agentToolsCount = 0;
      int groupsCount = 0;
      int promptTemplatesCount = 0;
      int modelsCount = 0;
      final List<String> errors = [];
      final List<String> warnings = [];

      // 导入应用设置
      try {
        if (data.containsKey('appSettings') && data['appSettings'] != null) {
          final appSettings = _normalizeMap(data['appSettings']);
          await _storage.saveAppSettings(appSettings);
          appSettingsImported = true;
        }
      } catch (e) {
        warnings.add('Failed to import app settings');
      }

      // 导入对话
      try {
        if (data.containsKey('conversations')) {
          final conversations = _normalizeList(data['conversations']);
          for (int i = 0; i < conversations.length; i++) {
            try {
              final convMap = _normalizeConversation(conversations[i] as Map<String, dynamic>);
              final id = convMap['id'] as String?;
              if (id == null || id.isEmpty) continue;
              await _storage.saveConversation(id, convMap);
              conversationsCount++;
            } catch (e) {
              warnings.add('Failed to import conversation at index $i');
            }
          }
        }
      } catch (e) {
        errors.add('Failed to process conversations');
      }

      // 导入 API 配置
      try {
        if (data.containsKey('apiConfigs')) {
          final apiConfigs = _normalizeList(data['apiConfigs']);
          for (int i = 0; i < apiConfigs.length; i++) {
            try {
              final configMap = _normalizeMap(apiConfigs[i]);
              final id = configMap['id'] as String?;
              if (id == null || id.isEmpty) continue;
              await _storage.saveApiConfig(id, configMap);
              apiConfigsCount++;
            } catch (e) {
              warnings.add('Failed to import API config at index $i');
            }
          }
        }
      } catch (e) {
        errors.add('Failed to process API configs');
      }

      // 导入 MCP 配置
      try {
        if (data.containsKey('mcpConfigs')) {
          final mcpConfigs = _normalizeList(data['mcpConfigs']);
          for (int i = 0; i < mcpConfigs.length; i++) {
            try {
              final configMap = _normalizeMap(mcpConfigs[i]);
              final id = configMap['id'] as String?;
              if (id == null || id.isEmpty) continue;
              await _storage.saveMcpConfig(id, configMap);
              mcpConfigsCount++;
            } catch (e) {
              warnings.add('Failed to import MCP config at index $i');
            }
          }
        }
      } catch (e) {
        errors.add('Failed to process MCP configs');
      }

      // 导入 Agent 配置
      try {
        if (data.containsKey('agentConfigs')) {
          final agentConfigs = _normalizeList(data['agentConfigs']);
          for (int i = 0; i < agentConfigs.length; i++) {
            try {
              final configMap = _normalizeMap(agentConfigs[i]);
              final id = configMap['id'] as String?;
              if (id == null || id.isEmpty) continue;
              await _storage.saveAgentConfig(id, configMap);
              agentConfigsCount++;
            } catch (e) {
              warnings.add('Failed to import Agent config at index $i');
            }
          }
        }
      } catch (e) {
        errors.add('Failed to process Agent configs');
      }

      // 导入 Agent 工具
      try {
        if (data.containsKey('agentTools')) {
          final agentTools = _normalizeList(data['agentTools']);
          for (int i = 0; i < agentTools.length; i++) {
            try {
              final toolMap = _normalizeMap(agentTools[i]);
              final id = toolMap['id'] as String?;
              if (id == null || id.isEmpty) continue;
              await _storage.saveSetting('agent_tool_$id', jsonEncode(toolMap));
              agentToolsCount++;
            } catch (e) {
              warnings.add('Failed to import Agent tool at index $i');
            }
          }
        }
      } catch (e) {
        errors.add('Failed to process Agent tools');
      }

      // 导入对话分组
      try {
        if (data.containsKey('groups')) {
          final groups = _normalizeList(data['groups']);
          for (int i = 0; i < groups.length; i++) {
            try {
              final groupMap = _normalizeMap(groups[i]);
              final id = groupMap['id'] as String?;
              if (id == null || id.isEmpty) continue;
              await _storage.saveGroup(id, groupMap);
              groupsCount++;
            } catch (e) {
              warnings.add('Failed to import group at index $i');
            }
          }
        }
      } catch (e) {
        errors.add('Failed to process groups');
      }

      // 导入提示词模板
      try {
        if (data.containsKey('promptTemplates')) {
          final templates = _normalizeList(data['promptTemplates']);
          for (int i = 0; i < templates.length; i++) {
            try {
              final templateMap = _normalizeMap(templates[i]);
              final id = templateMap['id'] as String?;
              if (id == null || id.isEmpty) continue;
              await _storage.savePromptTemplate(id, templateMap);
              promptTemplatesCount++;
            } catch (e) {
              warnings.add('Failed to import prompt template at index $i');
            }
          }
        }
      } catch (e) {
        errors.add('Failed to process prompt templates');
      }

      // 导入模型列表
      try {
        if (data.containsKey('models')) {
          final models = _normalizeList(data['models']);
          for (int i = 0; i < models.length; i++) {
            try {
              final modelMap = _normalizeMap(models[i]);
              final id = modelMap['id'] as String?;
              if (id == null || id.isEmpty) continue;
              await _storage.saveModel(id, modelMap);
              modelsCount++;
            } catch (e) {
              warnings.add('Failed to import model at index $i');
            }
          }
        }
      } catch (e) {
        errors.add('Failed to process models');
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
        'errors': errors,
        'warnings': warnings,
        'hasErrors': errors.isNotEmpty,
      };
    } catch (e, st) {
      _log.error('Import failed', e, st);
      return {'success': false, 'error': e.toString()};
    }
  }

  List<dynamic> _normalizeList(dynamic value) {
    if (value is List) return value;
    if (value == null) return [];
    throw FormatException('Expected list');
  }

  Map<String, dynamic> _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('Expected map');
  }

  Map<String, dynamic> _normalizeConversation(Map<String, dynamic> conv) {
    return {
      'id': conv['id'],
      'title': conv['title'] ?? 'Untitled',
      'createdAt': _normalizeDateTime(conv['createdAt'], DateTime.now()),
      'updatedAt': _normalizeDateTime(conv['updatedAt'], DateTime.now()),
      'systemPrompt': conv['systemPrompt'],
      'settings': _normalizeMap(conv['settings'] ?? {}),
      'tags': _normalizeList(conv['tags'] ?? []),
      'groupId': conv['groupId'],
      'totalTokens': _normalizeInt(conv['totalTokens']),
      'isPinned': _normalizeBool(conv['isPinned']),
      'isTemporary': _normalizeBool(conv['isTemporary']),
      'agentId': conv['agentId'],
      'messages': _normalizeMessages(conv['messages'] ?? []),
    };
  }

  List<Map<String, dynamic>> _normalizeMessages(dynamic messages) {
    if (messages is! List) return [];
    return messages.map((msg) {
      if (msg is! Map) return <String, dynamic>{};
      try {
        return _normalizeMessage(msg as Map<String, dynamic>);
      } catch (e) {
        _log.debug('Failed to normalize message', {'error': e.toString()});
        return <String, dynamic>{};
      }
    }).cast<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> msg) {
    final images = _normalizeImageAttachments(msg['images']);
    final toolCalls = _normalizeToolCalls(msg['toolCalls']);
    
    return {
      'id': msg['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'role': _normalizeRole(msg['role']),
      'content': msg['content'] ?? '',
      'timestamp': _normalizeDateTime(msg['timestamp'], DateTime.now()),
      'isStreaming': _normalizeBool(msg['isStreaming']),
      'hasError': _normalizeBool(msg['hasError']),
      'errorMessage': msg['errorMessage'],
      'metadata': _normalizeMap(msg['metadata'] ?? {}),
      'tokenCount': _normalizeInt(msg['tokenCount']),
      'images': images,
      'model': msg['model'],
      'promptTokens': _normalizeInt(msg['promptTokens']),
      'completionTokens': _normalizeInt(msg['completionTokens']),
      'responseDurationMs': _normalizeInt(msg['responseDurationMs']),
      'toolCalls': toolCalls,
    };
  }

  String _normalizeRole(dynamic role) {
    if (role is String && ['system', 'user', 'assistant'].contains(role)) return role;
    return 'user';
  }

  DateTime _normalizeDateTime(dynamic value, DateTime defaultValue) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  int? _normalizeInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is double) return value.toInt();
    return null;
  }

  List<Map<String, dynamic>>? _normalizeImageAttachments(dynamic images) {
    if (images == null) return null;
    if (images is! List) return null;
    final normalized = <Map<String, dynamic>>[];
    for (final img in images) {
      if (img is! Map) continue;
      try {
        final imgMap = img as Map<String, dynamic>;
        normalized.add({
          "path": imgMap["path"] ?? "",
          "base64Data": imgMap["base64Data"],
          "mimeType": imgMap["mimeType"],
        });
      } catch (e) {
        continue;
      }
    }
    return normalized.isEmpty ? null : normalized;
  }

  List<Map<String, dynamic>>? _normalizeToolCalls(dynamic toolCalls) {
    if (toolCalls == null) return null;
    if (toolCalls is! List) return null;
    final normalized = <Map<String, dynamic>>[];
    for (final call in toolCalls) {
      if (call is! Map) continue;
      try {
        final callMap = call as Map<String, dynamic>;
        normalized.add({
          "id": callMap["id"] ?? "",
          "type": callMap["type"] ?? "function",
          "function": _normalizeMap(callMap["function"] ?? {}),
        });
      } catch (e) {
        continue;
      }
    }
    return normalized.isEmpty ? null : normalized;
  }

  bool _normalizeBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
  }
}
