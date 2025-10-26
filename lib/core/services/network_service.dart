import 'package:flutter/material.dart';

/// 网络服务 - 统一的网络请求同闏
/// 支持重试、缓存、操作阈测
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  
  factory NetworkService() => _instance;
  NetworkService._internal();
  
  // 重试配置
  static const int maxRetries = 3;
  static const Duration initialBackoff = Duration(seconds: 1);
  static const double backoffMultiplier = 2.0;
  
  /// 执行带重试的请求
  Future<T> executeWithRetry<T>(
    Future<T> Function() request,
  ) async {
    int attempt = 0;
    Duration delay = initialBackoff;
    
    while (attempt < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        
        await Future.delayed(delay);
        delay *= backoffMultiplier;
      }
    }
    
    throw Exception('需求失败');
  }
  
  /// 批量执行请求
  Future<List<T>> executeBatch<T>(
    List<Future<T> Function()> requests,
  ) async {
    return Future.wait(
      requests.map((request) => executeWithRetry(request)),
    );
  }
}
