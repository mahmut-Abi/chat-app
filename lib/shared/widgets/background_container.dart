import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../core/providers/providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // 仅在背景相关设置变化时更新状态
        if (_currentBackgroundImage != settings.backgroundImage ||
            _currentOpacity != settings.backgroundOpacity) {
          _currentBackgroundImage = settings.backgroundImage;
          _currentOpacity = settings.backgroundOpacity;
        }
        return _buildWithBackground(context);
      },
      loading: () => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: widget.child,
      ),
      error: (error, stack) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: widget.child,
      ),
    );
  }

  Widget _buildWithBackground(BuildContext context) {
    // 没有背景图片时,使用主题背景色
    if (_currentBackgroundImage == null || _currentBackgroundImage!.isEmpty) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: widget.child,
      );
    }

    // backgroundOpacity 含义：
    // 0.0 = 背景完全不可见（内容完全不透明）
    // 1.0 = 背景完全可见（内容完全透明）
    // 0.8 = 背景 80% 可见（内容层 20% 不透明度作为遮罩）
    final contentOverlayOpacity = 1.0 - _currentOpacity;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片
        Positioned.fill(child: _buildBackgroundImage(_currentBackgroundImage!)),

        // 内容遮罩层（用于调节背景可见度）
        if (contentOverlayOpacity > 0)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(
                alpha: contentOverlayOpacity,
              ),
            ),
          ),

        // 实际内容
        widget.child,
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
