import 'package:flutter/foundation.dart';
import '../utils/desktop_utils.dart';
import '../utils/desktop_utils_io.dart'
    if (dart.library.html) '../utils/desktop_utils_stub.dart';
import 'log_service.dart';

/// 桌面端服务
class DesktopService {
  final LogService _log = LogService();

  SystemTrayListener? _trayListener;
  WindowEventListener? _windowListener;

  VoidCallback? onNewConversation;
  VoidCallback? onShowWindow;
  VoidCallback? onQuit;

  /// 初始化桌面服务
  Future<void> init() async {
    _log.info('初始化桌面端服务', {'isDesktop': DesktopUtils.isDesktop});
    if (!DesktopUtils.isDesktop) return;

    _log.debug('初始化窗口管理器');
    await DesktopUtils.initWindowManager();
    _log.debug('初始化系统托盘');
    await DesktopUtils.initSystemTray();

    // 设置托盘监听器
    _log.debug('配置系统托盘监听器');
    _trayListener = SystemTrayListener(
      onShowWindow: () async {
        _log.debug('托盘事件：显示窗口');
        await DesktopUtils.showWindow();
        onShowWindow?.call();
      },
      onNewConversation: () {
        _log.debug('托盘事件：创建新对话');
        onNewConversation?.call();
      },
      onQuit: () async {
        _log.info('托盘事件：退出应用');
        await DesktopUtils.quitApp();
        onQuit?.call();
      },
    );

    // 设置窗口监听器
    _log.debug('配置窗口事件监听器');
    _windowListener = WindowEventListener(
      onCloseCallback: () async {
        _log.debug('窗口事件：关闭窗口，最小化到托盘');
        // 关闭时最小化到托盘而不是退出
        await DesktopUtils.minimizeToTray();
      },
      onMinimizeCallback: () async {
        _log.debug('窗口事件：最小化窗口');
        // 最小化时隐藏窗口
        await DesktopUtils.hideWindow();
      },
    );

    // 注册监听器
    await _registerListeners();
    _log.info('桌面端服务初始化完成');
  }

  /// 注册事件监听器
  Future<void> _registerListeners() async {
    _log.debug('注册事件监听器');
    if (_trayListener != null) {
      _log.debug('注册托盘监听器');
      // trayManager.addListener(_trayListener!);
    }
    if (_windowListener != null) {
      _log.debug('注册窗口监听器');
      // windowManager.addListener(_windowListener!);
    }
  }

  /// 显示窗口
  Future<void> showWindow() async {
    _log.debug('显示窗口');
    await DesktopUtils.showWindow();
  }

  /// 隐藏窗口
  Future<void> hideWindow() async {
    _log.debug('隐藏窗口');
    await DesktopUtils.hideWindow();
  }

  /// 最小化到托盘
  Future<void> minimizeToTray() async {
    _log.debug('最小化到托盘');
    await DesktopUtils.minimizeToTray();
  }

  /// 退出应用
  Future<void> quit() async {
    _log.info('退出应用');
    await DesktopUtils.quitApp();
  }

  /// 释放资源
  void dispose() {
    _log.debug('释放桌面端服务资源');
    // 移除监听器
    if (_trayListener != null) {
      _log.debug('移除托盘监听器');
      // trayManager.removeListener(_trayListener!);
    }
    if (_windowListener != null) {
      _log.debug('移除窗口监听器');
      // windowManager.removeListener(_windowListener!);
    }
    _trayListener = null;
    _windowListener = null;
  }
}
