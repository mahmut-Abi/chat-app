 import 'package:flutter/foundation.dart' show kIsWeb;
 import 'dart:io' if (dart.library.html) 'dart:html' as platform;
 
 /// 跨平台的平台检查工具,支持 Web
 class PlatformUtils {
   static bool get isIOS {
     if (kIsWeb) return false;
     try {
       return platform.Platform.isIOS;
     } catch (_) {
       return false;
     }
   }
 
   static bool get isAndroid {
     if (kIsWeb) return false;
     try {
       return platform.Platform.isAndroid;
     } catch (_) {
       return false;
     }
   }
 
   static bool get isMacOS {
     if (kIsWeb) return false;
     try {
       return platform.Platform.isMacOS;
     } catch (_) {
       return false;
     }
   }
 
   static bool get isWindows {
     if (kIsWeb) return false;
     try {
       return platform.Platform.isWindows;
     } catch (_) {
       return false;
     }
   }
 
   static bool get isLinux {
     if (kIsWeb) return false;
     try {
       return platform.Platform.isLinux;
     } catch (_) {
       return false;
     }
   }
 
   static bool get isMobile => isIOS || isAndroid;
   static bool get isDesktop => isMacOS || isWindows || isLinux;
 }
