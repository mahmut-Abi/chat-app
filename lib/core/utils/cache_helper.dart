import 'dart:async';
import '../services/log_service.dart';

/// 简单的内存缓存制䯠
class SimpleCache<K, V> {
  final Map<K, V> _cache = {};
  late final Duration? _ttl;
  final Map<K, DateTime> _timestamps = {};
  final _logService = LogService();

  SimpleCache({Duration? ttl}) : _ttl = ttl;

  /// 从缓存中获取值，如果不存在也调用 fetcher
  Future<V> get(
    K key,
    Future<V> Function() fetcher,
  ) async {
    // 检查 TTL
    if (_ttl != null && _timestamps[key] != null) {
      final elapsed = DateTime.now().difference(_timestamps[key]!);
      if (elapsed > _ttl) {
        _cache.remove(key);
        _timestamps.remove(key);
      }
    }

    if (_cache.containsKey(key)) {
      _logService.debug('缓存命中', {'key': key.toString()});
      return _cache[key]!;
    }

    _logService.debug('缓存未命中，开始获取', {'key': key.toString()});
    final value = await fetcher();
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
    return value;
  }

  /// 手动设置缓存
  void set(K key, V value) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
    _logService.debug('缓存已设置', {'key': key.toString()});
  }

  /// 清除指定的缓存
  void remove(K key) {
    _cache.remove(key);
    _timestamps.remove(key);
    _logService.debug('缓存已清除', {'key': key.toString()});
  }

  /// 清空所有缓存
  void clear() {
    _cache.clear();
    _timestamps.clear();
    _logService.info('所有缓存已清除');
  }

  /// 获取缓存大小
  int get size => _cache.length;
}

/// 可以针对方法结果缓存的装饰器
class CachedFunction<T> {
  final Future<T> Function() _fn;
  late final Duration? _ttl;
  late final SimpleCache<String, T> _cache;
  final _logService = LogService();

  CachedFunction(this._fn, {Duration? ttl})
      : _ttl = ttl {
    _cache = SimpleCache<String, T>(ttl: ttl);
  }

  /// 下一次缓存失效的求惨次数
  void invalidate() => _cache.clear();

  /// 自动缓存执行
  Future<T> call() => _cache.get('_fn', _fn);
}
