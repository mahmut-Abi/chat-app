import '../domain/mcp_config.dart';
import '../../../core/services/log_service.dart';
import 'mcp_health_check_strategy.dart';
import 'dart:async';

/// MCP 皆控事件
enum McpMonitorEvent {
  connected,
  disconnected,
  healthCheckPassed,
  healthCheckFailed,
  recoveryAttempt,
  recoverySuccess,
  recoveryFailed,
  strategyChanged,
}

/// MCP 监控程序
class McpMonitor {
  final McpConfig config;
  final LogService log = LogService();

  // 监控配置
  HealthCheckStrategy strategy = HealthCheckStrategy.probe;
  Duration healthCheckInterval = const Duration(seconds: 30);
  int maxRetries = 3;
  Duration retryDelay = const Duration(seconds: 5);

  // 内部状态
  McpConnectionStatus status = McpConnectionStatus.disconnected;
  Timer? _healthCheckTimer;
  Timer? _recoveryTimer;
  int _failureCount = 0;
  int _recoveryAttempts = 0;
  final List<HealthCheckResult> _healthCheckHistory = [];
  final _eventController = StreamController<McpMonitorEvent>.broadcast();

  // 执行器与业会
  Map<HealthCheckStrategy, HealthCheckExecutor> executors = {};
  HealthCheckExecutor? _customExecutor;

  McpMonitor({
    required this.config,
    this.strategy = HealthCheckStrategy.probe,
    this.healthCheckInterval = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
  }) {
    _initializeExecutors();
  }

  void _initializeExecutors() {
    executors = {
      HealthCheckStrategy.standard: StandardHealthCheckExecutor(),
      HealthCheckStrategy.probe: ProbeHealthCheckExecutor(),
      HealthCheckStrategy.toolsListing: ToolsListingHealthCheckExecutor(),
      HealthCheckStrategy.networkOnly: NetworkOnlyHealthCheckExecutor(),
    };
  }

  /// 设置自定义执行器
  void setCustomExecutor(HealthCheckExecutor executor) {
    _customExecutor = executor;
  }

  /// 获取事件流
  Stream<McpMonitorEvent> get events => _eventController.stream;

  /// 启动监控
  Future<void> start() async {
    log.info('启动 MCP 监控', {
      'configId': config.id,
      'strategy': strategy.toString(),
    });
    status = McpConnectionStatus.connecting;

    // 执行初始化健康检查（带自动降级）
    final result = await performHealthCheckWithFallback();

    if (result.success) {
      status = McpConnectionStatus.connected;
      _failureCount = 0;
      _eventController.add(McpMonitorEvent.connected);
      log.info('MCP 连接成功，已启动监控', {'strategy': strategy.toString()});
      _startHealthCheckTimer();
    } else {
      status = McpConnectionStatus.error;
      _eventController.add(McpMonitorEvent.healthCheckFailed);
      await attemptRecovery();
    }
  }

  /// 停止监控
  Future<void> stop() async {
    log.info('停止 MCP 监控');
    _stopHealthCheckTimer();
    _stopRecoveryTimer();
    status = McpConnectionStatus.disconnected;
    _eventController.add(McpMonitorEvent.disconnected);
  }

  /// 执行健康检查並自动下预
  Future<HealthCheckResult> performHealthCheckWithFallback() async {
    // 首先尝试当前配置的策略
    var result = await performHealthCheck();

    // 如果失败，自动尝试帮推策略
    if (!result.success &&
        strategy != HealthCheckStrategy.disabled &&
        strategy != HealthCheckStrategy.custom) {
      log.info('当前策略失败，尝试帮推策略', {'failedStrategy': strategy.toString()});

      final fallbackStrategies = [
        HealthCheckStrategy.networkOnly,
        HealthCheckStrategy.toolsListing,
        HealthCheckStrategy.standard,
      ];

      for (final fallback in fallbackStrategies) {
        if (fallback == strategy) continue;
        log.debug('尝试帮推策略', {'strategy': fallback.toString()});

        final tempExecutor = executors[fallback];
        if (tempExecutor != null) {
          try {
            final fallbackResult = await tempExecutor.execute(
              config.endpoint,
              config.headers?.cast(),
            );
            if (fallbackResult.success) {
              log.info('帮推策略成功', {'strategy': fallback.toString()});
              return fallbackResult;
            }
          } catch (e) {
            log.debug('帮推策略错误', {
              'strategy': fallback.toString(),
              'error': e.toString(),
            });
          }
        }
      }
    }

    return result;
  }

  /// 基于设置的策略执行一次健康检查
  Future<HealthCheckResult> performHealthCheck() async {
    if (strategy == HealthCheckStrategy.disabled) {
      return HealthCheckResult(
        success: true,
        message: '健康检查已禁用',
        duration: Duration.zero,
        strategy: HealthCheckStrategy.disabled,
      );
    }

    final executor = strategy == HealthCheckStrategy.custom
        ? _customExecutor
        : executors[strategy];

    if (executor == null) {
      return HealthCheckResult(
        success: false,
        message: '找不到执行器: \${strategy.toString()}',
        duration: Duration.zero,
        strategy: strategy,
      );
    }

    try {
      final result = await executor.execute(
        config.endpoint,
        config.headers?.cast(),
      );
      _healthCheckHistory.add(result);

      // 保持历史记录最多 100 条
      if (_healthCheckHistory.length > 100) {
        _healthCheckHistory.removeAt(0);
      }

      if (result.success) {
        _failureCount = 0;
        _eventController.add(McpMonitorEvent.healthCheckPassed);
      } else {
        _failureCount++;
        _eventController.add(McpMonitorEvent.healthCheckFailed);
      }

      log.info('执行健康检查', {'result': result.toString()});
      return result;
    } catch (e) {
      _failureCount++;
      final result = HealthCheckResult(
        success: false,
        message: '执行器异常: \${e.toString()}',
        duration: Duration.zero,
        strategy: strategy,
      );
      _eventController.add(McpMonitorEvent.healthCheckFailed);
      return result;
    }
  }

  /// 尝试恢复连接
  Future<void> attemptRecovery() async {
    log.warning('尝试恢复 MCP 连接', {
      'failureCount': _failureCount,
      'maxRetries': maxRetries,
    });

    _eventController.add(McpMonitorEvent.recoveryAttempt);
    _recoveryAttempts = 0;
    _startRecoveryTimer();
  }

  /// 不同策略阶段恢复
  Future<bool> _tryFallbackStrategies() async {
    final strategies = [
      HealthCheckStrategy.probe,
      HealthCheckStrategy.toolsListing,
      HealthCheckStrategy.networkOnly,
      HealthCheckStrategy.standard,
    ];

    for (final fallback in strategies) {
      if (fallback == strategy) continue; // 跳过当前策略

      log.info('氝试恢复策略', {'strategy': fallback.toString()});
      final tempStrategy = strategy;
      strategy = fallback;
      _eventController.add(McpMonitorEvent.strategyChanged);

      final result = await performHealthCheckWithFallback();
      if (result.success) {
        log.info('恢复成功', {'strategy': fallback.toString()});
        _eventController.add(McpMonitorEvent.recoverySuccess);
        return true;
      }

      strategy = tempStrategy;
    }

    return false;
  }

  /// 启动恢复定时器
  void _startRecoveryTimer() {
    _stopRecoveryTimer();
    _recoveryTimer = Timer.periodic(retryDelay, (_) async {
      if (_recoveryAttempts >= maxRetries) {
        _stopRecoveryTimer();
        log.error('恢复失败: 达到最大重试次数');
        _eventController.add(McpMonitorEvent.recoveryFailed);
        status = McpConnectionStatus.error;
        return;
      }

      _recoveryAttempts++;
      log.info('恢复尝试', {
        'attempt': _recoveryAttempts,
        'maxRetries': maxRetries,
      });

      // 先尝试当前策略
      final result = await performHealthCheck();
      if (result.success) {
        status = McpConnectionStatus.connected;
        _stopRecoveryTimer();
        _failureCount = 0;
        _eventController.add(McpMonitorEvent.recoverySuccess);
        log.info('恢复成功');
        _startHealthCheckTimer();
        return;
      }

      // 如果当前策略失败，不轮换法
      if (_recoveryAttempts >= maxRetries ~/ 2) {
        final recovered = await _tryFallbackStrategies();
        if (recovered) {
          status = McpConnectionStatus.connected;
          _stopRecoveryTimer();
          _failureCount = 0;
          _startHealthCheckTimer();
          return;
        }
      }
    });
  }

  /// 停止恢复定时器
  void _stopRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }

  /// 启动健康检查定时器
  void _startHealthCheckTimer() {
    _stopHealthCheckTimer();
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) async {
      final result = await performHealthCheck();

      if (!result.success && _failureCount >= 3) {
        status = McpConnectionStatus.error;
        _stopHealthCheckTimer();
        await attemptRecovery();
      }
    });
  }

  /// 停止健康检查定时器
  void _stopHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// 变更检查策略
  Future<void> switchStrategy(HealthCheckStrategy newStrategy) async {
    if (strategy == newStrategy) return;

    log.info('切换检查策略', {
      'from': strategy.toString(),
      'to': newStrategy.toString(),
    });
    strategy = newStrategy;
    _failureCount = 0;
    _eventController.add(McpMonitorEvent.strategyChanged);

    // 执行一次检查验证
    final result = await performHealthCheck();
    if (result.success) {
      _startHealthCheckTimer();
    }
  }

  /// 获取健康检查历史
  List<HealthCheckResult> getHealthCheckHistory() {
    return List.unmodifiable(_healthCheckHistory);
  }

  /// 获取最汚的健康检查结果
  HealthCheckResult? getLatestHealthCheck() {
    return _healthCheckHistory.isEmpty ? null : _healthCheckHistory.last;
  }

  /// 获取成功率
  double getSuccessRate() {
    if (_healthCheckHistory.isEmpty) return 0.0;
    final successful = _healthCheckHistory.where((r) => r.success).length;
    return successful / _healthCheckHistory.length;
  }

  /// 释放资源
  void dispose() {
    _stopHealthCheckTimer();
    _stopRecoveryTimer();
    _eventController.close();
  }
}
