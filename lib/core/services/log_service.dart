import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 日志级别
enum LogLevel { debug, info, warning, error }

/// 日志导出格式
enum LogExportFormat { text, json, csv }

/// 日志记录
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? extra;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.stackTrace,
    this.extra,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    if (stackTrace != null) 'stackTrace': stackTrace,
    if (extra != null) 'extra': extra,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    level: LogLevel.values.firstWhere(
      (e) => e.name == json['level'],
      orElse: () => LogLevel.info,
    ),
    message: json['message'] as String,
    stackTrace: json['stackTrace'] as String?,
    extra: json['extra'] as Map<String, dynamic>?,
  );

  /// 转换为 CSV 行
  String toCsvRow() {
    final msg = message.replaceAll('"', '""').replaceAll('\n', ' ');
    final stack = stackTrace?.replaceAll('"', '""').replaceAll('\n', ' ') ?? '';
    return '"$id","${timestamp.toIso8601String()}","${level.name}","$msg","$stack"';
  }
}

/// 日志服务
///
/// 提供统一的日志记录、存储和查询功能。
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;

  // 日志上下文堆栈，用于追踪操作层次
  final List<String> _contextStack = [];

  // 性能监控：开始时间戳
  final Map<String, DateTime> _performanceTimers = {};

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  final List<LogEntry> _logs = [];
  final int _maxLogs = 5000; // 最多保存 5000 条日志
  StorageService? _storage;
  bool _isInitialized = false;

  LogService._internal();

  /// 进入日志上下文
  void enterContext(String context) {
    _contextStack.add(context);
    debug('进入上下文: $context');
  }

  /// 退出日志上下文
  void exitContext() {
    if (_contextStack.isNotEmpty) {
      final context = _contextStack.removeLast();
      debug('退出上下文: $context');
    }
  }

  /// 获取当前上下文路径
  String get currentContext {
    return _contextStack.isEmpty ? '' : _contextStack.join(' > ');
  }

  /// 开始性能计时
  void startPerformanceTimer(String label) {
    _performanceTimers[label] = DateTime.now();
    debug('开始计时: $label');
  }

  /// 结束性能计时并记录结果
  void stopPerformanceTimer(String label) {
    final startTime = _performanceTimers.remove(label);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      info('性能指标: $label', {
        'duration_ms': duration.inMilliseconds,
        'duration_readable': '${duration.inMilliseconds}ms',
      });
    } else {
      warning('性能计时器不存在: $label');
    }
  }

  /// 清理所有性能计时器
  void clearPerformanceTimers() {
    _performanceTimers.clear();
  }

  /// 初始化日志服务
  Future<void> init(StorageService storage) async {
    if (_isInitialized) return;

    _storage = storage;
    await _loadLogsFromStorage();
    _isInitialized = true;
    info('日志服务初始化完成');
  }

  /// 加载存储的日志
  Future<void> _loadLogsFromStorage() async {
    if (_storage == null) return;

    try {
      final data = _storage!.getSetting('app_logs');
      if (data != null && data is List) {
        _logs.clear();
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            try {
              _logs.add(LogEntry.fromJson(item));
            } catch (e) {
              debugPrint('无法解析日志记录: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('加载日志失败: $e');
    }
  }

  /// 保存日志到存储
  Future<void> _saveLogsToStorage() async {
    if (_storage == null) return;

    try {
      final data = _logs.map((log) => log.toJson()).toList();
      await _storage!.saveSetting('app_logs', data);
    } catch (e) {
      debugPrint('保存日志失败: $e');
    }
  }

  /// 记录 Debug 日志
  void debug(String message, [Map<String, dynamic>? extra]) {
    final contextMsg = currentContext.isEmpty
        ? message
        : '[$currentContext] $message';
    if (kDebugMode) {
      _logger.d(contextMsg);
    }
    _addLog(LogLevel.debug, contextMsg, extra: extra);
  }

  /// 记录 Info 日志
  void info(String message, [Map<String, dynamic>? extra]) {
    final contextMsg = currentContext.isEmpty
        ? message
        : '[$currentContext] $message';
    _logger.i(contextMsg);
    _addLog(LogLevel.info, contextMsg, extra: extra);
  }

  /// 记录 Warning 日志
  void warning(String message, [Map<String, dynamic>? extra]) {
    final contextMsg = currentContext.isEmpty
        ? message
        : '[$currentContext] $message';
    _logger.w(contextMsg);
    _addLog(LogLevel.warning, contextMsg, extra: extra);
  }

  /// 记录 Error 日志
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    final contextMsg = currentContext.isEmpty
        ? message
        : '[$currentContext] $message';
    _logger.e(contextMsg, error: error, stackTrace: stackTrace);
    _addLog(
      LogLevel.error,
      contextMsg,
      stackTrace: stackTrace?.toString(),
      extra: error != null ? {'error': error.toString()} : null,
    );
  }

  /// 添加日志记录
  void _addLog(
    LogLevel level,
    String message, {
    String? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    final log = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      stackTrace: stackTrace,
      extra: extra,
    );

    _logs.insert(0, log);

    // 限制日志数量
    if (_logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs, _logs.length);
    }

    // 异步保存
    _saveLogsToStorage();
  }

  /// 获取所有日志
  List<LogEntry> getAllLogs() => List.unmodifiable(_logs);

  /// 根据级别过滤日志
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// 根据时间范围过滤日志
  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _logs
        .where(
          (log) => log.timestamp.isAfter(start) && log.timestamp.isBefore(end),
        )
        .toList();
  }

  /// 搜索日志
  List<LogEntry> searchLogs(String query) {
    final lowerQuery = query.toLowerCase();
    return _logs
        .where((log) => log.message.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 获取日志统计信息
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{
      'total': _logs.length,
      'debug': 0,
      'info': 0,
      'warning': 0,
      'error': 0,
    };

    for (final log in _logs) {
      stats[log.level.name] = (stats[log.level.name] as int) + 1;
    }

    return stats;
  }

  /// 获取最近的错误日志
  List<LogEntry> getRecentErrors({int limit = 10}) {
    return _logs
        .where((log) => log.level == LogLevel.error)
        .take(limit)
        .toList();
  }

  /// 清空日志
  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogsToStorage();
    info('日志已清空');
  }

  /// 导出日志
  String exportLogs({
    LogExportFormat format = LogExportFormat.text,
    LogLevel? levelFilter,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    var logs = _logs;

    // 应用过滤
    if (levelFilter != null) {
      logs = logs.where((log) => log.level == levelFilter).toList();
    }
    if (startTime != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startTime)).toList();
    }
    if (endTime != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endTime)).toList();
    }

    switch (format) {
      case LogExportFormat.text:
        return _exportAsText(logs);
      case LogExportFormat.json:
        return _exportAsJson(logs);
      case LogExportFormat.csv:
        return _exportAsCsv(logs);
    }
  }

  /// 导出为文本格式
  String _exportAsText(List<LogEntry> logs) {
    final buffer = StringBuffer();
    buffer.writeln('========== 应用日志 ==========');
    buffer.writeln('导出时间: ${DateTime.now()}');
    buffer.writeln('总记录数: ${logs.length}');
    buffer.writeln('=====================================\n');

    for (final log in logs) {
      buffer.writeln('[${log.level.name.toUpperCase()}] ${log.timestamp}');
      buffer.writeln(log.message);
      if (log.stackTrace != null) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(log.stackTrace);
      }
      if (log.extra != null) {
        buffer.writeln('Extra: ${log.extra}');
      }
      buffer.writeln('-------------------------------------\n');
    }

    return buffer.toString();
  }

  /// 导出为 JSON 格式
  String _exportAsJson(List<LogEntry> logs) {
    final data = {
      'exportTime': DateTime.now().toIso8601String(),
      'totalCount': logs.length,
      'logs': logs.map((log) => log.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 导出为 CSV 格式
  String _exportAsCsv(List<LogEntry> logs) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Timestamp,Level,Message,StackTrace');
    for (final log in logs) {
      buffer.writeln(log.toCsvRow());
    }
    return buffer.toString();
  }

  /// 导出日志到文件
  Future<File> exportLogsToFile({
    LogExportFormat format = LogExportFormat.text,
    LogLevel? levelFilter,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final content = exportLogs(
      format: format,
      levelFilter: levelFilter,
      startTime: startTime,
      endTime: endTime,
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final extension = format == LogExportFormat.json
        ? 'json'
        : format == LogExportFormat.csv
        ? 'csv'
        : 'txt';
    final file = File('${dir.path}/logs_$timestamp.$extension');
    await file.writeAsString(content);

    info('日志已导出到文件: ${file.path}');
    return file;
  }

  /// 清理旧日志（保留最近 N 天）
  Future<void> cleanOldLogs({int days = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final initialCount = _logs.length;
    _logs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
    final removedCount = initialCount - _logs.length;

    if (removedCount > 0) {
      await _saveLogsToStorage();
      info('已清理 $removedCount 条旧日志（超过 $days 天）');
    }
  }

  /// 导出日志为文本（向后兼容）
  String exportLogsAsText() {
    return exportLogs(format: LogExportFormat.text);
  }
}
