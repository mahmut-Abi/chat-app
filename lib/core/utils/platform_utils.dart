 import 'package:flutter/foundation.dart' show kIsWeb;
  import 'dart:io' if (dart.library.html) 'platform_utils_web.dart';
 
 /// 跨平台的平台检查工具,支持 Web
 class PlatformUtils {
   static bool get isIOS {
     if (kIsWeb) return false;
     return Platform.isIOS;
   }
 
   static bool get isAndroid {
     if (kIsWeb) return false;
     return Platform.isAndroid;
   }
 
   static bool get isMacOS {
     if (kIsWeb) return false;
     return Platform.isMacOS;
   }
 
   static bool get isWindows {
     if (kIsWeb) return false;
     return Platform.isWindows;
   }
 
   static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  static bool get isWeb => kIsWeb;
  
  static bool get isMobile => isIOS || isAndroid;
  static bool get isDesktop => isMacOS || isWindows || isLinux;
}
