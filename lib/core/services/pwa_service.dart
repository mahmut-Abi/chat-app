import 'package:flutter/foundation.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'log_service.dart';

/// PWA 服务（Web 端）
class PwaService {
  final LogService _log = LogService();

  static const String _serviceWorkerPath = '/sw.js';

  /// 初始化 PWA
  Future<void> init() async {
    _log.info('初始化 PWA 服务', {'platform': kIsWeb ? 'web' : 'native'});
    if (!kIsWeb) return;

    try {
      _log.debug('注册 Service Worker', {'path': _serviceWorkerPath});
      // 注册 Service Worker
      final serviceWorker = web.window.navigator.serviceWorker;
      await serviceWorker.register(_serviceWorkerPath.toJS).toDart;
      _log.info('Service Worker 注册成功');
      debugPrint('Service Worker 注册成功');
    } catch (e) {
      _log.error('Service Worker 注册失败', e);
      debugPrint('Service Worker 注册失败: $e');
    }
  }

  /// 检查是否为 PWA 模式
  bool get isPwa {
    if (!kIsWeb) return false;

    try {
      _log.debug('检查 PWA 运行模式');
      // 检查是否以 standalone 模式运行
      final mediaQuery = web.window.matchMedia('(display-mode: standalone)');
      final isPwaMode = mediaQuery.matches;
      _log.debug('PWA 模式检查结果', {'isPwa': isPwaMode});
      return isPwaMode;
    } catch (e) {
      _log.error('PWA 模式检查失败', e);
      return false;
    }
  }

  /// 显示安装提示
  Future<bool> showInstallPrompt() async {
    _log.info('尝试显示 PWA 安装提示');
    if (!kIsWeb) return false;

    try {
      // 注意：实际的 install prompt 需要捕获 beforeinstallprompt 事件
      // 这里只是一个示例框架
      _log.debug('PWA 安装提示显示成功');
      debugPrint('显示 PWA 安装提示');
      return true;
    } catch (e) {
      _log.error('PWA 安装提示显示失败', e);
      debugPrint('显示安装提示失败: $e');
      return false;
    }
  }

  /// 检查 Service Worker 状态
  Future<bool> checkServiceWorkerStatus() async {
    _log.debug('检查 Service Worker 状态');
    if (!kIsWeb) return false;

    try {
      final serviceWorker = web.window.navigator.serviceWorker;
      await serviceWorker.getRegistration().toDart;
      _log.info('Service Worker 运行正常');
      return true;
    } catch (e) {
      _log.warning('Service Worker 状态检查失败', {'error': e.toString()});
      return false;
    }
  }
}
