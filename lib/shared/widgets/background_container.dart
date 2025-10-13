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

    if (backgroundImage == null || backgroundImage.isEmpty) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片
        _buildBackgroundImage(backgroundImage),

        // 模糊效果 (需要在遮罩前应用)
        if (settings.enableBackgroundBlur)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),

        // 透明度遮罩 (使用白色半透明来降低背景可见度)
        Container(
          color: Colors.white.withValues(
            alpha: 1 - settings.backgroundOpacity,
          ),
        ),

        // 实际内容
        child,
      ],
    );
  }

  Widget _buildBackgroundImage(String path) {
    Widget imageWidget;
    
    if (path.startsWith('assets/')) {
      imageWidget = Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
        width: double.infinity,
        height: double.infinity,
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
