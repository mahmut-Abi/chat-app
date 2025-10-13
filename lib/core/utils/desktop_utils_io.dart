// Desktop implementation using window_manager and tray_manager
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

Future<void> initWindowManagerImpl() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<void> initSystemTrayImpl() async {
  try {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/icons/tray_icon.ico'
          : 'assets/icons/tray_icon.png',
    );

    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: '显示窗口',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'new_conversation',
          label: '新建对话',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: '退出',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
    await trayManager.setToolTip('Chat App');
  } catch (e) {
    debugPrint('初始化系统托盘失败: $e');
  }
}

Future<void> showWindowImpl() async {
  await windowManager.show();
  await windowManager.focus();
}

Future<void> hideWindowImpl() async {
  await windowManager.hide();
}

Future<void> minimizeToTrayImpl() async {
  await windowManager.hide();
}

Future<void> quitAppImpl() async {
  await windowManager.destroy();
}

// 系统托盘监听器
class SystemTrayListener extends TrayListener {
  final VoidCallback? onShowWindow;
  final VoidCallback? onNewConversation;
  final VoidCallback? onQuit;

  SystemTrayListener({
    this.onShowWindow,
    this.onNewConversation,
    this.onQuit,
  });

  @override
  void onTrayIconMouseDown() {
    onShowWindow?.call();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        onShowWindow?.call();
        break;
      case 'new_conversation':
        onNewConversation?.call();
        break;
      case 'quit':
        onQuit?.call();
        break;
    }
  }
}

// 窗口事件监听器
class WindowEventListener extends WindowListener {
  final VoidCallback? onCloseCallback;
  final VoidCallback? onMinimizeCallback;

  WindowEventListener({
    this.onCloseCallback,
    this.onMinimizeCallback,
  });

  @override
  void onWindowClose() {
    onCloseCallback?.call();
  }

  @override
  void onWindowMinimize() {
    onMinimizeCallback?.call();
  }

  @override
  void onWindowFocus() {
    // 窗口获得焦点时的处理
  }

  @override
  void onWindowBlur() {
    // 窗口失去焦点时的处理
  }
}
