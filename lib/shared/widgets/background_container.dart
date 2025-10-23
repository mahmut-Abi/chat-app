import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';

/// 背景容器 - 提供全局背景图片支持
///
/// 优化说明：
/// 1. 使用 ConsumerStatefulWidget 避免不必要的重建
/// 2. 仅在背景相关设置变化时才重建
class BackgroundContainer extends ConsumerStatefulWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  @override
  ConsumerState<BackgroundContainer> createState() =>
      _BackgroundContainerState();
}

class _BackgroundContainerState extends ConsumerState<BackgroundContainer> {
  String? _currentBackgroundImage;
  double _currentOpacity = 0.8;
  Widget? _cachedBackgroundStack;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // 仅在背景相关设置变化时更新状态
        final needsRebuild =
            _currentBackgroundImage != settings.backgroundImage ||
            _currentOpacity != settings.backgroundOpacity;

        if (needsRebuild) {
          LogService().debug('BackgroundContainer rebuild', {
            'hasImage': settings.backgroundImage != null,
            'opacity': settings.backgroundOpacity,
          });
          _currentBackgroundImage = settings.backgroundImage;
          _currentOpacity = settings.backgroundOpacity;
          _cachedBackgroundStack = null; // 清除缓存
        }

        return _buildWithBackground(context);
      },
      loading: () => widget.child,
      error: (error, stack) => widget.child,
    );
  }

  Widget _buildWithBackground(BuildContext context) {
    // 没有背景图片时,使用主题背景色
    if (_currentBackgroundImage == null || _currentBackgroundImage!.isEmpty) {
      // 为了确保 iOS 转场效果，总是提供一个 Container 包装
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: widget.child,
      );
    }

    // 使用缓存的背景Stack
    _cachedBackgroundStack ??= _buildBackgroundStack();

    // 为了确保 iOS 转场效果，在最底层添加 ColoredBox
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 使用RepaintBoundary优化重绘性能
          RepaintBoundary(child: _cachedBackgroundStack!),
          widget.child,
        ],
      ),
    );
  }

  /// 构建背景Stack（会被缓存）
  Widget _buildBackgroundStack() {
    // backgroundOpacity 含义：
    // 0.0 = 背景完全不可见（内容完全不透明）
    // 1.0 = 背景完全可见（内容完全透明）
    // 0.8 = 背景 80% 可见（内容层 20% 不透明度作为遮罩）
    final contentOverlayOpacity = 1.0 - _currentOpacity;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片
        _buildBackgroundImage(_currentBackgroundImage!),
        // 内容遮罩层（用于调节背景可见度）
        if (contentOverlayOpacity > 0)
          Container(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withOpacity(contentOverlayOpacity),
          ),
      ],
    );
  }

  Widget _buildBackgroundImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        },
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        },
      );
    }
  }
}
