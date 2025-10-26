/// 上下上辅优化骍证测试
/// 
/// 有效测试: JsonCodecHelper 、AppError 、SimpleCache

import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/core/utils/json_codec_helper.dart';
import 'package:your_app/core/error/app_error.dart';
import 'package:your_app/core/utils/cache_helper.dart';

void main() {
  group('优化工具测试', () {
    group('JsonCodecHelper', () {
      test('safeParse 应該正確解析 JSON 字符串', () {
        final result = JsonCodecHelper.safeParse('{"key": "value"}');
        expect(result, {'key': 'value'});
      });

      test('safeParse 应該正確处理 Map', () {
        final data = {'key': 'value'};
        final result = JsonCodecHelper.safeParse(data);
        expect(result, data);
      });

      test('safeParse 应該在错误时返回 null', () {
        expect(JsonCodecHelper.safeParse(123), null);
        expect(JsonCodecHelper.safeParse([1, 2, 3]), null);
      });

      test('isValidJson 应該正確骍证', () {
        expect(JsonCodecHelper.isValidJson('{"a": 1}'), true);
        expect(JsonCodecHelper.isValidJson('{invalid}'), false);
      });
    });

    group('AppError', () {
      test('AppError 应該管理不同错误类型', () {
        final error = AppError(
          type: AppErrorType.network,
          message: 'Network error',
        );
        expect(error.type, AppErrorType.network);
      });

      test('userFriendlyMessage 应該不为空', () {
        final error = AppError(
          type: AppErrorType.timeout,
          message: 'Test',
        );
        expect(error.userFriendlyMessage, isNotEmpty);
      });
    });

    group('SimpleCache', () {
      test('消息缓存应該正常', () async {
        final cache = SimpleCache<String, int>();
        cache.set('key', 42);
        
        var count = 0;
        final result = await cache.get('key', () async {
          count++;
          return 99;
        });

        expect(result, 42);
        expect(count, 0);
      });
    });
  });
}
