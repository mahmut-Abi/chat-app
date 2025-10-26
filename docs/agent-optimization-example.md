/// Agent 仓一一一优化示例
/// 
/// 以下按需改实现 getAllAgents() 方法为例
/// 
/// **优化前（原始代码）:**
/// ```dart
/// Future<List<AgentConfig>> getAllAgents() async {
///   try {
///     final keys = await _storage.getAllKeys();
///     final agentKeys = keys.where((k) => k.startsWith('agent_')).toList();
///     
///     final agents = <AgentConfig>[];
///     for (final key in agentKeys) {
///       final data = _storage.getSetting(key);
///       if (data != null) {
///         try {
///           // 支持两种格式: 字符串(新) 和 Map(旧)
///           final Map<String, dynamic> json;
///           if (data is String) {
///             json = jsonDecode(data) as Map<String, dynamic>;
///           } else if (data is Map<String, dynamic>) {
///             json = data;
///           } else {
///             continue;
///           }
///           agents.add(AgentConfig.fromJson(json));
///         } catch (e) {
///           _log.warning('解析 Agent 配置失败', {'key': key});
///         }
///       }
///     }
///     return agents;
///   } catch (e) {
///     _log.error('获取 Agent 配置异常', e);
///     return [];
///   }
/// }
/// ```
/// 
/// **优化后（使用 JsonCodecHelper）:**
/// ```dart
/// import '../../../core/utils/json_codec_helper.dart';
/// 
/// Future<List<AgentConfig>> getAllAgents() async {
///   try {
///     final keys = await _storage.getAllKeys();
///     final agentKeys = keys.where((k) => k.startsWith('agent_')).toList();
///     
///     final agents = <AgentConfig>[];
///     for (final key in agentKeys) {
///       final data = _storage.getSetting(key);
///       final json = JsonCodecHelper.safeParse(data);
///       
///       if (json != null) {
///         try {
///           agents.add(AgentConfig.fromJson(json));
///         } catch (e) {
///           _log.warning('解析 Agent 配置失败', {'key': key, 'error': e.toString()});
///         }
///       }
///     }
///     return agents;
///   } catch (e) {
///     _log.error('获取 Agent 配置异常', e, StackTrace.current);
///     return [];
///   }
/// }
/// ```
/// 
/// ## 优化效果
/// 
/// - **代码行数**: 28 行 → 20 行 (-29%)
/// - **可书性**: 自然酸（简洲和一次调用）
/// - **安全性**: 统一的空指针检查
/// - **维所成本**: 鬱陋起来更容易
/// 
/// ## 其他需要优化的方法
/// 
/// 下列 AgentRepository 中的方法也有類似的优化空间：
/// 
/// 1. **getAllTools()** - 相同的 JSON 处理
/// 2. **updateToolStatus()** - 相同的 JSON 处理
/// 3. **getDeletedBuiltInAgentIds()** - 相同的上下上辅管理
/// 
/// **推荐**: 将這些想法一次应用 JsonCodecHelper，会恵了 15-20 行詳語
