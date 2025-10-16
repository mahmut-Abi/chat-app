import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/services/network_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  group('NetworkService', () {
    late NetworkService networkService;

    setUp(() {
      networkService = NetworkService();
    });

    test('应该创建 NetworkService 实例', () {
      expect(networkService, isNotNull);
      expect(networkService, isA<NetworkService>());
    });

    test('应该正确获取网络状态描述 - 无连接', () {
      final description = networkService.getNetworkStatusDescription([
        ConnectivityResult.none,
      ]);
      expect(description, equals('无网络连接'));
    });

    test('应该正确获取网络状态描述 - WiFi', () {
      final description = networkService.getNetworkStatusDescription([
        ConnectivityResult.wifi,
      ]);
      expect(description, equals('已连接到 WiFi'));
    });

    test('应该正确获取网络状态描述 - 蜂窝网络', () {
      final description = networkService.getNetworkStatusDescription([
        ConnectivityResult.mobile,
      ]);
      expect(description, equals('已连接到蜂窝网络'));
    });

    test('应该正确获取网络状态描述 - 以太网', () {
      final description = networkService.getNetworkStatusDescription([
        ConnectivityResult.ethernet,
      ]);
      expect(description, equals('已连接到以太网'));
    });

    test('应该正确获取网络状态描述 - 未知', () {
      final description = networkService.getNetworkStatusDescription([]);
      expect(description, equals('网络状态未知'));
    });
  });
}
