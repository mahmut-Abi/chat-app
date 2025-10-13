import 'dart:io';
 import 'package:flutter/foundation.dart';
 import 'package:flutter/material.dart';
 
 // 条件导入：仅在桌面平台导入实际实现，否则导入 stub
 import 'desktop_utils_stub.dart'
   if (dart.library.io) 'desktop_utils_io.dart';
 
 /// 桌面端工具类
 class DesktopUtils {
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

   /// 初始化窗口管理
   static Future<void> initWindowManager() async {
     if (!isDesktop) return;
     await initWindowManagerImpl();
   }
 
   /// 初始化系统托盘
   static Future<void> initSystemTray() async {
     if (!isDesktop) return;
     await initSystemTrayImpl();
   }
 
   /// 显示窗口
   static Future<void> showWindow() async {
     if (!isDesktop) return;
     await showWindowImpl();
   }
 
   /// 隐藏窗口
   static Future<void> hideWindow() async {
     if (!isDesktop) return;
     await hideWindowImpl();
   }
 
   /// 最小化到托盘
   static Future<void> minimizeToTray() async {
     if (!isDesktop) return;
     await minimizeToTrayImpl();
   }
 
   /// 退出应用
   static Future<void> quitApp() async {
     if (!isDesktop) return;
     await quitAppImpl();
   }
 }
