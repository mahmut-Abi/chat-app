import 'dart:convert';
import '../services/log_service.dart';

/// JSON 编解码辅助工具
/// 提供安全的 JSON 操作，支持多种数据格式
class JsonCodecHelper {
  static final _log = LogService();

  /// 安全解析 JSON 数据（支持 String/Map 双格式）
  ///
  /// 该方法支持两种格式的输入:
  /// - String: JSON 字符串，将进行 decode
  /// - Map<String, dynamic>: 直接返回（已是 Map 格式）
  ///
  /// 返回值: 成功时返回 Map，失败时返回 null
  static Map<String, dynamic>? safeParse(dynamic data) {
    try {
      if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } catch (e) {
      _log.warning('JSON 解析失败', {'type': data.runtimeType, 'error': e.toString()});
      return null;
    }
  }

  /// 验证并转换 Map 列表
  ///
  /// 该方法用于将动态类型的列表转换为指定的对象类型
  static List<T>? safeParseList<T>(
    dynamic listData,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      if (listData is! List<dynamic>) {
        _log.warning('列表解析失败: 不是 List 类型', {'type': listData.runtimeType});
        return null;
      }

      final result = <T>[];
      for (final item in listData) {
        if (item is Map<String, dynamic>) {
          try {
            result.add(fromJson(item));
          } catch (itemError) {
            _log.warning('列表项解析失败，跳过该项', {'error': itemError.toString()});
          }
        }
      }
      return result;
    } catch (e) {
      _log.error('列表解析异常', e);
      return null;
    }
  }

  /// 安全编码对象为 JSON
  static String safeEncode(dynamic object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      _log.error('JSON 编码失败', e);
      return '{}';
    }
  }

  /// 验证 JSON 格式的字符串
  static bool isValidJson(String data) {
    try {
      jsonDecode(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
