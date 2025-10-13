import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:ui';
import '../../core/providers/providers.dart';
import 'package:flutter/foundation.dart';

class BackgroundContainer extends ConsumerWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final backgroundImage = settings.backgroundImage;

    if (backgroundImage == null) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片
        _buildBackgroundImage(backgroundImage),

        // 透明度遮罩
        Container(
          color: Theme.of(context)
              .scaffoldBackgroundColor
              .withValues(alpha: 1 - settings.backgroundOpacity),
        ),

        // 模糊效果
        if (settings.enableBackgroundBlur)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),

        // 实际内容
        child,
      ],
    );
  }

  Widget _buildBackgroundImage(String path) {
    // iOS 平台需要特殊处理
    Widget imageWidget;
    
    if (path.startsWith('assets/')) {
      imageWidget = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('背景图片加载失败 (asset): $path, 错误: $error');
          }
          return const SizedBox.shrink();
        },
      );
    } else {
      imageWidget = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('背景图片加载失败 (file): $path, 错误: $error');
          }
          return const SizedBox.shrink();
        },
      );
    }
    
    return imageWidget;
  }
}
