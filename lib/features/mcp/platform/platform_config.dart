import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Platform detection and configuration
class PlatformConfig {
  /// Detects current running platform
  static PlatformType get currentPlatform {
    if (kIsWeb) return PlatformType.web;
    if (Platform.isIOS) return PlatformType.ios;
    if (Platform.isAndroid) return PlatformType.android;
    if (Platform.isWindows) return PlatformType.windows;
    if (Platform.isMacOS) return PlatformType.macos;
    if (Platform.isLinux) return PlatformType.linux;
    return PlatformType.unknown;
  }

  /// Check if platform is mobile
  static bool get isMobile =>
      currentPlatform == PlatformType.ios ||
      currentPlatform == PlatformType.android;

  /// Check if platform is desktop
  static bool get isDesktop =>
      currentPlatform == PlatformType.windows ||
      currentPlatform == PlatformType.macos ||
      currentPlatform == PlatformType.linux;

  /// Check if platform is web
  static bool get isWeb => currentPlatform == PlatformType.web;

  /// Check if platform supports stdio mode
  static bool get supportsStdioMode => isDesktop;

  /// Check if platform supports HTTP mode
  static bool get supportsHttpMode => true;

  /// Check if platform supports local file system access
  static bool get supportsLocalFileAccess => !isWeb;

  /// Get supported MCP connection types for current platform
  static List<String> get supportedMcpModes {
    if (isWeb) return ['http', 'websocket'];
    if (isMobile) return ['http', 'websocket'];
    return ['http', 'stdio', 'websocket'];
  }

  /// Get default timeout in milliseconds
  static int get defaultTimeoutMs => isMobile ? 15000 : 30000;

  /// Get maximum concurrent connections
  static int get maxConcurrentConnections => isWeb ? 3 : 10;
}

/// Platform type enumeration
enum PlatformType { web, ios, android, windows, macos, linux, unknown }
