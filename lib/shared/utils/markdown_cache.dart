import 'package:flutter/material.dart';

/// Markdown 渲染结果缓存 - LRU 缓存实现
class MarkdownCache {
  static const int _maxCacheSize = 50;
  static final Map<String, dynamic> _cache = {};
  static final List<String> _accessOrder = [];
  
  /// 获取缓存的渲染结果
  static dynamic get(String markdown) {
    if (_cache.containsKey(markdown)) {
      _accessOrder.remove(markdown);
      _accessOrder.add(markdown);
      return _cache[markdown];
    }
    return null;
  }
  
  /// 存储渲染结果到缓存
  static void set(String markdown, dynamic renderedWidget) {
    if (_cache.length >= _maxCacheSize && !_cache.containsKey(markdown)) {
      final oldestKey = _accessOrder.removeAt(0);
      _cache.remove(oldestKey);
    }
    _cache[markdown] = renderedWidget;
    _accessOrder.remove(markdown);
    _accessOrder.add(markdown);
  }
  
  /// 清空所有缓存
  static void clear() {
    _cache.clear();
    _accessOrder.clear();
  }
  
  /// 获取缓存统计
  static Map<String, int> getStats() => {
    'cached_items': _cache.length,
    'max_size': _maxCacheSize,
  };
}
