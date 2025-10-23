import 'dart:io';
import 'package:flutter/material.dart';

/// 背景图片缓存管理器
///
/// 用于缓存全局背景图片，避免重复加载
/// 当背景图片路径改变时，自动清除旧缓存
class BackgroundImageCache {
  static ImageProvider? _cachedImage;
  static String? _currentPath;

  /// 获取缓存的背景图片
  ///
  /// 如果路径为空，返回 null
  /// 如果路径改变，清除旧缓存并创建新缓存
  /// 如果路径未变，返回已缓存的图片
  static ImageProvider? getImage(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }

    // 如果路径改变，清除旧缓存
    if (_currentPath != path) {
      _cachedImage = null;
      _currentPath = path;
    }

    // 创建新缓存
    if (_cachedImage == null) {
      _cachedImage = path.startsWith('assets/')
          ? AssetImage(path) as ImageProvider
          : FileImage(File(path));
    }

    return _cachedImage;
  }

  /// 清除缓存
  ///
  /// 当用户更换背景图片或删除背景图片时调用
  static void clearCache() {
    _cachedImage = null;
    _currentPath = null;
  }

  /// 预加载图片
  ///
  /// 在应用启动时或切换背景图片时调用，提升首次显示速度
  static Future<void> preloadImage(BuildContext context, String path) async {
    final image = getImage(path);
    if (image != null) {
      await precacheImage(image, context);
    }
  }
}
