import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// PWA 服务（Web 端）
class PwaService {
  static const String _serviceWorkerPath = '/sw.js';

  /// 初始化 PWA
  Future<void> init() async {
    if (!kIsWeb) return;

    try {
      // 注册 Service Worker
      if (html.window.navigator.serviceWorker != null) {
        await html.window.navigator.serviceWorker!.register(_serviceWorkerPath);
        debugPrint('Service Worker 注册成功');
      }
    } catch (e) {
      debugPrint('Service Worker 注册失败: $e');
    }
  }

  /// 检查是否为 PWA 模式
  bool get isPwa {
    if (!kIsWeb) return false;

    try {
      // 检查是否以 standalone 模式运行
      final mediaQuery = html.window.matchMedia('(display-mode: standalone)');
      return mediaQuery.matches;
    } catch (e) {
      return false;
    }
  }

  /// 显示安装提示
  Future<bool> showInstallPrompt() async {
    if (!kIsWeb) return false;

    try {
      // 注意：实际的 install prompt 需要捕获 beforeinstallprompt 事件
      // 这里只是一个示例框架
      debugPrint('显示 PWA 安装提示');
      return true;
    } catch (e) {
      debugPrint('显示安装提示失败: $e');
      return false;
    }
  }

  /// 检查 Service Worker 状态
  Future<bool> checkServiceWorkerStatus() async {
    if (!kIsWeb) return false;

    try {
      final serviceWorker = html.window.navigator.serviceWorker;
      if (serviceWorker != null) {
        await serviceWorker.getRegistration();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
