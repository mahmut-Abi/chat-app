import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/core/services/log_service.dart';
import 'package:chat_app/core/storage/storage_service.dart';

@GenerateMocks([StorageService])
import 'log_service_test.mocks.dart';

void main() {
  group('LogService', () {
    late LogService logService;
    late MockStorageService mockStorage;

    setUp(() {
      logService = LogService();
      mockStorage = MockStorageService();
    });

    tearDown(() async {
      await logService.clearLogs();
      logService.clearPerformanceTimers();
    });

    group('日志记录', () {
      test('应该记录 debug 日志', () {
        // Act
        logService.debug('测试 debug 消息');

        // Assert
        final logs = logService.getAllLogs();
        expect(logs.length, 1);
        expect(logs.first.level, LogLevel.debug);
        expect(logs.first.message, '测试 debug 消息');
      });

      test('应该记录 info 日志', () {
        // Act
        logService.info('测试 info 消息');

        // Assert
        final logs = logService.getAllLogs();
        expect(logs.first.level, LogLevel.info);
        expect(logs.first.message, '测试 info 消息');
      });

      test('应该记录 warning 日志', () {
        // Act
        logService.warning('测试 warning 消息');

        // Assert
        final logs = logService.getAllLogs();
        expect(logs.first.level, LogLevel.warning);
      });

      test('应该记录 error 日志', () {
        // Act
        logService.error('测试 error 消息');

        // Assert
        final logs = logService.getAllLogs();
        expect(logs.first.level, LogLevel.error);
      });

      test('应该记录额外信息', () {
        // Arrange
        final extra = {'key': 'value', 'count': 123};

        // Act
        logService.info('消息', extra);

        // Assert
        final logs = logService.getAllLogs();
        expect(logs.first.extra, equals(extra));
      });

      test('应该生成唯一的日志 ID', () {
        // Act
        logService.info('消息1');
        logService.info('消息2');

        // Assert
        final logs = logService.getAllLogs();
        expect(logs[0].id, isNot(equals(logs[1].id)));
      });
    });

    group('上下文管理', () {
      test('应该进入和退出上下文', () {
        // Act
        logService.enterContext('模块A');
        final context1 = logService.currentContext;
        logService.exitContext();
        final context2 = logService.currentContext;

        // Assert
        expect(context1, '模块A');
        expect(context2, isEmpty);
      });

      test('应该支持嵌套上下文', () {
        // Act
        logService.enterContext('模块A');
        logService.enterContext('模块B');
        logService.enterContext('模块C');

        // Assert
        expect(logService.currentContext, '模块A > 模块B > 模块C');
      });

      test('应该在日志中包含上下文', () {
        // Act
        logService.enterContext('测试模块');
        logService.info('测试消息');

        // Assert
        final logs = logService.getAllLogs();
        expect(logs.first.message, contains('[测试模块]'));
      });
    });

    group('性能计时', () {
      test('应该记录性能计时', () async {
        // Act
        logService.startPerformanceTimer('操作1');
        await Future.delayed(const Duration(milliseconds: 10));
        logService.stopPerformanceTimer('操作1');

        // Assert
        final logs = logService.getLogsByLevel(LogLevel.info);
        expect(logs.any((log) => log.message.contains('性能指标: 操作1')), isTrue);
      });

      test('应该清理性能计时器', () {
        // Act
        logService.startPerformanceTimer('操作1');
        logService.clearPerformanceTimers();
        logService.stopPerformanceTimer('操作1');

        // Assert
        final logs = logService.getLogsByLevel(LogLevel.warning);
        expect(logs.any((log) => log.message.contains('性能计时器不存在')), isTrue);
      });
    });

    group('日志查询', () {
      setUp(() async {
        await logService.clearLogs();
        logService.debug('Debug 消息');
        logService.info('Info 消息');
        logService.warning('Warning 消息');
        logService.error('Error 消息');
      });

      test('应该获取所有日志', () {
        // Act
        final logs = logService.getAllLogs();

        // Assert
        expect(logs.length, greaterThanOrEqualTo(4));
      });

      test('应该按级别过滤日志', () {
        // Act
        final errorLogs = logService.getLogsByLevel(LogLevel.error);

        // Assert
        expect(errorLogs.every((log) => log.level == LogLevel.error), isTrue);
      });

      test('应该搜索日志', () {
        // Act
        final results = logService.searchLogs('Warning');

        // Assert
        expect(results.length, greaterThan(0));
        expect(results.first.message, contains('Warning'));
      });

      test('应该获取最近的错误日志', () {
        // Act
        final errors = logService.getRecentErrors(limit: 5);

        // Assert
        expect(errors.every((log) => log.level == LogLevel.error), isTrue);
      });
    });

    group('日志统计', () {
      setUp(() async {
        await logService.clearLogs();
        logService.debug('Debug 1');
        logService.info('Info 1');
        logService.info('Info 2');
        logService.warning('Warning 1');
        logService.error('Error 1');
      });

      test('应该生成正确的统计信息', () {
        // Act
        final stats = logService.getStatistics();

        // Assert
        expect(stats['total'], greaterThanOrEqualTo(5));
        expect(stats['debug'], greaterThanOrEqualTo(1));
        expect(stats['info'], greaterThanOrEqualTo(2));
        expect(stats['warning'], greaterThanOrEqualTo(1));
        expect(stats['error'], greaterThanOrEqualTo(1));
      });
    });

    group('日志导出', () {
      setUp(() async {
        await logService.clearLogs();
        logService.info('测试消息1');
        logService.error('测试错误');
      });

      test('应该导出为文本格式', () {
        // Act
        final exported = logService.exportLogs(format: LogExportFormat.text);

        // Assert
        expect(exported, contains('应用日志'));
        expect(exported, contains('测试消息1'));
      });

      test('应该导出为 JSON 格式', () {
        // Act
        final exported = logService.exportLogs(format: LogExportFormat.json);

        // Assert
        expect(exported, contains('"logs"'));
        expect(exported, contains('测试消息1'));
      });

      test('应该导出为 CSV 格式', () {
        // Act
        final exported = logService.exportLogs(format: LogExportFormat.csv);

        // Assert
        expect(exported, contains('ID,Timestamp,Level,Message'));
        expect(exported, contains('测试消息1'));
      });

      test('应该按级别过滤导出', () {
        // Act
        final exported = logService.exportLogs(
          format: LogExportFormat.text,
          levelFilter: LogLevel.error,
        );

        // Assert
        expect(exported, contains('测试错误'));
        expect(exported, isNot(contains('测试消息1')));
      });
    });

    group('日志持久化', () {
      test('应该初始化日志服务', () async {
        // Arrange
        when(mockStorage.getSetting('app_logs')).thenReturn(null);
        when(mockStorage.saveSetting(any, any)).thenAnswer((_) async {});

        // Act
        await logService.init(mockStorage);

        // Assert
        verify(mockStorage.getSetting('app_logs')).called(1);
      });

      test('应该清空日志', () async {
        // Arrange
        logService.info('测试消息');
        when(mockStorage.saveSetting(any, any)).thenAnswer((_) async {});

        // Act
        await logService.clearLogs();

        // Assert
        final logs = logService.getAllLogs();
        expect(logs, isEmpty);
      });
    });

    group('LogEntry', () {
      test('应该正确序列化和反序列化', () {
        // Arrange
        final entry = LogEntry(
          id: '123',
          timestamp: DateTime(2025, 1, 17),
          level: LogLevel.info,
          message: '测试消息',
        );

        // Act
        final json = entry.toJson();
        final restored = LogEntry.fromJson(json);

        // Assert
        expect(restored.id, entry.id);
        expect(restored.level, entry.level);
        expect(restored.message, entry.message);
      });

      test('应该正确转换为 CSV 行', () {
        // Arrange
        final entry = LogEntry(
          id: '123',
          timestamp: DateTime(2025, 1, 17),
          level: LogLevel.info,
          message: '测试消息',
        );

        // Act
        final csv = entry.toCsvRow();

        // Assert
        expect(csv, contains('123'));
        expect(csv, contains('info'));
        expect(csv, contains('测试消息'));
      });

      test('应该正确处理带堆栈跟踪的日志', () {
        // Arrange
        final entry = LogEntry(
          id: '123',
          timestamp: DateTime(2025, 1, 17),
          level: LogLevel.error,
          message: '错误消息',
          stackTrace: 'Stack trace here',
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['stackTrace'], 'Stack trace here');
      });
    });
  });
}
