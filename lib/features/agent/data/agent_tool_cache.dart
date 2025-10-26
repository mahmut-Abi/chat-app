import 'dart:async';
import '../domain/agent_tool.dart';

/// Agent 工具执行缓存
class AgentToolCache {
  final Map<String, _CachedResult> _cache = {};
  final Map<String, Timer> _expireTimers = {};
  final Duration _defaultDuration;

  AgentToolCache({Duration defaultDuration = const Duration(hours: 1)})
    : _defaultDuration = defaultDuration;

  ToolExecutionResult? get(String toolId, Map<String, dynamic> arguments) {
    final key = _generateKey(toolId, arguments);
    final cached = _cache[key];
    if (cached == null || cached.isExpired) {
      _removeCached(key);
      return null;
    }
    return cached.result;
  }

  void set(
    String toolId,
    Map<String, dynamic> arguments,
    ToolExecutionResult result, {
    Duration? duration,
  }) {
    final key = _generateKey(toolId, arguments);
    final actualDuration = duration ?? _defaultDuration;
    _expireTimers[key]?.cancel();
    _cache[key] = _CachedResult(result, DateTime.now().add(actualDuration));
    _expireTimers[key] = Timer(actualDuration, () {
      _removeCached(key);
    });
  }

  void clearAll() {
    _expireTimers.forEach((_, timer) => timer.cancel());
    _expireTimers.clear();
    _cache.clear();
  }

  int get size => _cache.length;

  void _removeCached(String key) {
    _cache.remove(key);
    _expireTimers[key]?.cancel();
    _expireTimers.remove(key);
  }

  String _generateKey(String toolId, Map<String, dynamic> arguments) {
    final sortedKeys = arguments.keys.toList()..sort();
    return '${toolId}_${sortedKeys.join('_')}';
  }

  void dispose() {
    clearAll();
  }
}

class _CachedResult {
  final ToolExecutionResult result;
  final DateTime expireTime;
  _CachedResult(this.result, this.expireTime);
  bool get isExpired => DateTime.now().isAfter(expireTime);
}
