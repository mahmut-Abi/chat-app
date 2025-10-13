import 'package:flutter/foundation.dart';
import '../utils/desktop_utils.dart';
import '../utils/desktop_utils_io.dart' if (dart.library.html) '../utils/desktop_utils_stub.dart';

/// 桌面端服务
class DesktopService {
  SystemTrayListener? _trayListener;
  WindowEventListener? _windowListener;
  
  VoidCallback? onNewConversation;
  VoidCallback? onShowWindow;
  VoidCallback? onQuit;
  
  /// 初始化桌面服务
  Future<void> init() async {
    if (!DesktopUtils.isDesktop) return;
    
    await DesktopUtils.initWindowManager();
    await DesktopUtils.initSystemTray();
    
    // 设置托盘监听器
    _trayListener = SystemTrayListener(
      onShowWindow: () async {
        await DesktopUtils.showWindow();
        onShowWindow?.call();
      },
      onNewConversation: () {
        onNewConversation?.call();
      },
      onQuit: () async {
        await DesktopUtils.quitApp();
        onQuit?.call();
      },
    );
    
    // 设置窗口监听器
    _windowListener = WindowEventListener(
      onCloseCallback: () async {
        // 关闭时最小化到托盘而不是退出
        await DesktopUtils.minimizeToTray();
      },
      onMinimizeCallback: () async {
        // 最小化时隐藏窗口
        await DesktopUtils.hideWindow();
      },
    );
  }
  
  /// 显示窗口
  Future<void> showWindow() async {
    await DesktopUtils.showWindow();
  }
  
  /// 隐藏窗口
  Future<void> hideWindow() async {
    await DesktopUtils.hideWindow();
  }
  
  /// 最小化到托盘
  Future<void> minimizeToTray() async {
    await DesktopUtils.minimizeToTray();
  }
  
  /// 退出应用
  Future<void> quit() async {
    await DesktopUtils.quitApp();
  }
  
  /// 释放资源
  void dispose() {
    _trayListener = null;
    _windowListener = null;
  }
}
