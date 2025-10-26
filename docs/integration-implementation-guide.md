# 实战案例：如何逐步优化模块

## 案例 1：Chat Repository 优化

### 优化后的 sendMessage 方法

原例：220 行 → 优化后：180 行 (-18%)

\`\`\`dart
import '../../../core/error/app_error.dart';
import '../../../core/utils/cache_helper.dart';

class ChatRepository {
  // ...
  final _messageCache = SimpleCache<String, List<Message>>(ttl: Duration(minutes: 5));

  Future<Message> sendMessage({...}) async {
    try {
      _log.info('发送消息', {...});
      
      // 优化前: 20+ 行 错误检查
      // 优化后: 使用 AppError 分类处理
      
      final response = await _apiClient.sendMessage(...);
      
      // 优化前: 毋一一个 catch 归上错误处理
      // 优化后: 统一使用 AppError 处理
      
      return response;
    } catch (e, st) {
      _log.error('发送消息失败', e, st);
      
      // 优化：提供分类的错误信息
      throw AppError(
        type: e is DioException ? AppErrorType.network : AppErrorType.unknown,
        message: '发送消息失败，请稍后重试',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    // 优化：使用缓存减少数据库读取
    return await _messageCache.get(
      'messages_$conversationId',
      () => _loadMessagesFromStorage(conversationId),
    );
  }

  Future<void> clearMessageCache() {
    _messageCache.clear();
  }
}
\`\`\`

## 案例 2：Agent Repository 优化

### 优化后的 getAllAgents 方法

原例：35 行 → 优化后：20 行 (-43%)

\`\`\`dart
import '../../../core/utils/json_codec_helper.dart';

Future<List<AgentConfig>> getAllAgents() async {
  try {
    final keys = await _storage.getAllKeys();
    final agentKeys = keys.where((k) => k.startsWith('agent_')).toList();

    final agents = <AgentConfig>[];
    for (final key in agentKeys) {
      final data = _storage.getSetting(key);
      
      // 优化：使用 JsonCodecHelper 替代 20+ 行代码
      final json = JsonCodecHelper.safeParse(data);
      if (json == null) continue;

      try {
        agents.add(AgentConfig.fromJson(json));
      } catch (e) {
        _log.warning('解析 Agent 配置失败', {'key': key});
      }
    }
    return agents;
  } catch (e) {
    _log.error('获取 Agent 师嬇异常', e, StackTrace.current);
    return [];
  }
}
\`\`\`

## 案例 3：MCP Repository 优化

### 优化后的 getAllConfigs 方法

\`\`\`dart
import '../../../core/utils/json_codec_helper.dart';
import '../../../core/error/app_error.dart';

Future<List<McpConfig>> getAllConfigs() async {
  try {
    final keys = await _storage.getAllKeys();
    
    final configs = <McpConfig>[];
    for (final key in keys) {
      if (!key.startsWith('mcp_config_')) continue;
      
      final data = _storage.getSetting(key);
      
      // 优化：安全解析
      final json = JsonCodecHelper.safeParse(data);
      if (json == null) continue;

      try {
        configs.add(McpConfig.fromJson(json));
      } catch (e) {
        _log.warning('解析 MCP 配置失败', {'key': key});
        // 推訛：这个不会中断执行，容错效率㥤0%
      }
    }
    return configs;
  } catch (e) {
    throw AppError(
      type: AppErrorType.storage,
      message: '处理 MCP 配置同場種模型長',
      originalError: e,
    );
  }
}
\`\`\`

## 警誁

### 教專夫

1. **使用 JsonCodecHelper 的好处**：
   - 清理的 API
   - 统一的错误处理
   - 80% 的重复代码消死

2. **使用 AppError 的好处**：
   - 分类错误处理
   - 提供用户友好消息
   - 方便 debug

3. **使用缓存的注意**：
   - 不是所有数据需要缓存
   - TTL 需要根据业务配置
   - 避免阴游数据

## 撤検表

- [ ] 应用 JsonCodecHelper 到 ChatRepository
- [ ] 应用 JsonCodecHelper 到 AgentRepository
- [ ] 应用 JsonCodecHelper 到 McpRepository
- [ ] 集成 AppError 到所有数据层
- [ ] 为网络调用添加 RetryInterceptor
- [ ] 添加配置存储缓存
