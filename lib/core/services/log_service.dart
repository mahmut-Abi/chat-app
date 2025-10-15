import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';

/// 日志级别
enum LogLevel { debug, info, warning, error }

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
}

/// 日志服务
///
/// 提供统一的日志记录、存储和查询功能。
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;

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
  final int _maxLogs = 1000; // 最多保存 1000 条日志
  StorageService? _storage;

  LogService._internal();

  /// 初始化日志服务
  Future<void> init(StorageService storage) async {
    _storage = storage;
    await _loadLogsFromStorage();
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
    _logger.d(message);
    _addLog(LogLevel.debug, message, extra: extra);
  }

  /// 记录 Info 日志
  void info(String message, [Map<String, dynamic>? extra]) {
    _logger.i(message);
    _addLog(LogLevel.info, message, extra: extra);
  }

  /// 记录 Warning 日志
  void warning(String message, [Map<String, dynamic>? extra]) {
    _logger.w(message);
    _addLog(LogLevel.warning, message, extra: extra);
  }

  /// 记录 Error 日志
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _addLog(
      LogLevel.error,
      message,
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

  /// 清空日志
  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogsToStorage();
  }

  /// 导出日志为文本
  String exportLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('========== 应用日志 ==========');
    buffer.writeln('导出时间: ${DateTime.now()}');
    buffer.writeln('总记录数: ${_logs.length}');
    buffer.writeln('=====================================\n');

    for (final log in _logs) {
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
}
