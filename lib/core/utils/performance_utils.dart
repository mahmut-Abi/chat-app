import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 性能优化工具类
class PerformanceUtils {
  static const int _defaultCacheSize = 100;
  static final Map<String, dynamic> _cache = {};
  static final List<String> _cacheKeys = [];

  /// 缓存数据
  static void cache(String key, dynamic value) {
    if (_cache.containsKey(key)) {
      return;
    }

    if (_cache.length >= _defaultCacheSize) {
      // 移除最旧的缓存
      final oldestKey = _cacheKeys.first;
      _cache.remove(oldestKey);
      _cacheKeys.removeAt(0);
    }

    _cache[key] = value;
    _cacheKeys.add(key);
  }

  /// 获取缓存
  static T? getCache<T>(String key) {
    return _cache[key] as T?;
  }

  /// 清除缓存
  static void clearCache() {
    _cache.clear();
    _cacheKeys.clear();
  }

  /// 性能监控
  static Future<T> measurePerformance<T>({
    required String label,
    required Future<T> Function() task,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await task();
      stopwatch.stop();
      debugPrint('$label 执行耗时: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('$label 执行失败: $e');
      rethrow;
    }
  }

  /// 防抖动
  static Function debounce(
    Function func, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, () {
        func();
      });
    };
  }

  /// 节流
  static Function throttle(
    Function func, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    bool isThrottled = false;
    return () {
      if (!isThrottled) {
        func();
        isThrottled = true;
        Timer(duration, () {
          isThrottled = false;
        });
      }
    };
  }
}

/// 虚拟滚动列表
class VirtualListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final double itemExtent;

  const VirtualListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.itemExtent = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemExtent: itemExtent,
      itemBuilder: itemBuilder,
      cacheExtent: itemExtent * 10,
    );
  }
}
