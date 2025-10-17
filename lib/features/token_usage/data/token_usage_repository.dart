import '../domain/token_record.dart';
import '../../../core/storage/storage_service.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/log_service.dart';

/// Token 使用记录仓库
class TokenUsageRepository {
  final StorageService _storage;
  final _log = LogService();
  static const String _keyPrefix = 'token_record_';
  static const String _summaryKey = 'token_usage_summary';

  TokenUsageRepository(this._storage);

  /// 添加 Token 记录
  Future<void> addRecord(TokenRecord record) async {
    _log.debug('保存 Token 记录', {
      'recordId': record.id,
      'totalTokens': record.totalTokens,
      'model': record.model,
    });

    await _storage.saveSetting('$_keyPrefix${record.id}', record.toJson());
    await _updateSummary();
  }

  /// 获取所有记录
  Future<List<TokenRecord>> getAllRecords() async {
    _log.debug('获取所有 Token 记录');
    try {
      final keys = await _storage.getAllKeys();
      final recordKeys = keys.where((k) => k.startsWith(_keyPrefix)).toList();

      final records = <TokenRecord>[];
      for (final key in recordKeys) {
        final data = _storage.getSetting(key);
        if (data != null && data is Map<String, dynamic>) {
          try {
            records.add(TokenRecord.fromJson(data));
          } catch (e) {
            _log.error('解析 Token 记录失败', {'key': key, 'error': e});
          }
        }
      }

      // 按时间降序排序
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (e) {
      _log.error('获取 Token 记录失败', e);
      return [];
    }
  }

  /// 获取指定对话的记录
  Future<List<TokenRecord>> getRecordsByConversation(
    String conversationId,
  ) async {
    final all = await getAllRecords();
    return all.where((r) => r.conversationId == conversationId).toList();
  }

  /// 获取指定日期范围的记录
  Future<List<TokenRecord>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllRecords();
    return all
        .where((r) => r.timestamp.isAfter(start) && r.timestamp.isBefore(end))
        .toList();
  }

  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    _log.debug('删除 Token 记录', {'recordId': recordId});
    await _storage.deleteSetting('$_keyPrefix$recordId');
    await _updateSummary();
  }

  /// 清空所有记录
  Future<void> clearAll() async {
    _log.info('清空所有 Token 记录');
    final keys = await _storage.getAllKeys();
    final recordKeys = keys.where((k) => k.startsWith(_keyPrefix)).toList();

    for (final key in recordKeys) {
      await _storage.deleteSetting(key);
    }
    await _storage.deleteSetting(_summaryKey);
  }

  /// 获取汇总统计
  Future<TokenUsageSummary> getSummary() async {
    final records = await getAllRecords();

    if (records.isEmpty) {
      return TokenUsageSummary(
        totalTokens: 0,
        recordCount: 0,
        modelStats: {},
        dailyStats: {},
      );
    }

    // 计算总量
    int totalTokens = 0;
    final Map<String, int> modelStats = {};
    final Map<String, int> dailyStats = {};

    for (final record in records) {
      totalTokens += record.totalTokens;

      // 按模型统计
      modelStats[record.model] =
          (modelStats[record.model] ?? 0) + record.totalTokens;

      // 按日期统计
      final dateKey =
          '${record.timestamp.year}-${record.timestamp.month.toString().padLeft(2, '0')}-${record.timestamp.day.toString().padLeft(2, '0')}';
      dailyStats[dateKey] = (dailyStats[dateKey] ?? 0) + record.totalTokens;
    }

    return TokenUsageSummary(
      totalTokens: totalTokens,
      recordCount: records.length,
      modelStats: modelStats,
      dailyStats: dailyStats,
    );
  }

  /// 更新汇总统计
  Future<void> _updateSummary() async {
    final summary = await getSummary();
    await _storage.saveSetting(_summaryKey, {
      'totalTokens': summary.totalTokens,
      'recordCount': summary.recordCount,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }
}

/// Token 使用汇总
class TokenUsageSummary {
  final int totalTokens;
  final int recordCount;
  final Map<String, int> modelStats; // 各模型消耗统计
  final Map<String, int> dailyStats; // 每日消耗统计

  TokenUsageSummary({
    required this.totalTokens,
    required this.recordCount,
    required this.modelStats,
    required this.dailyStats,
  });
}
