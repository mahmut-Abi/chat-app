import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'log_service.dart';

class NetworkService {
  final _log = LogService();
  final _connectivity = Connectivity();

  // 检查网络连接状态
  Future<bool> checkNetworkConnection() async {
    try {
      _log.info('检查网络连接状态');

      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        _log.warning('没有网络连接');
        return false;
      }

      // 检查实际的网络连通性（尝试连接到可靠的服务器）
      final hasConnection = await _checkInternetConnection();

      if (hasConnection) {
        _log.info('网络连接正常', {'type': connectivityResult.toString()});
      } else {
        _log.warning('网络连接异常', {'type': connectivityResult.toString()});
      }

      return hasConnection;
    } catch (e) {
      _log.error('检查网络连接失败', {'error': e.toString()});
      return false;
    }
  }

  // 检查实际的互联网连接
  Future<bool> _checkInternetConnection() async {
    try {
      // 尝试连接到可靠的服务器（使用 DNS 查询）
      final result = await InternetAddress.lookup('www.google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      _log.error('检查互联网连接失败', {'error': e.toString()});
      return false;
    }
  }

  // 获取网络连接类型
  Future<String> getConnectionType() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return '蜂窝网络';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        return '以太网';
      } else if (connectivityResult.contains(ConnectivityResult.none)) {
        return '无连接';
      }
      return '未知';
    } catch (e) {
      _log.error('获取连接类型失败', {'error': e.toString()});
      return '未知';
    }
  }

  // 监听网络状态变化
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  // 获取网络状态描述
  String getNetworkStatusDescription(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      return '无网络连接';
    } else if (results.contains(ConnectivityResult.wifi)) {
      return '已连接到 WiFi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return '已连接到蜂窝网络';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return '已连接到以太网';
    }
    return '网络状态未知';
  }
}
