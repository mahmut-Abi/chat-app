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

    if (kDebugMode) {
      print('BackgroundContainer: backgroundImage = $backgroundImage');
      print('BackgroundContainer: opacity = ${settings.backgroundOpacity}');
      print('BackgroundContainer: blur = ${settings.enableBackgroundBlur}');
    }

    // 没有背景图片时,使用主题背景色
    if (backgroundImage == null || backgroundImage.isEmpty) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片
        Positioned.fill(child: _buildBackgroundImage(backgroundImage)),

        // 模糊效果 + 透明度遮罩（合并为一层）
        if (settings.enableBackgroundBlur)
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10.0,
                  sigmaY: 10.0,
                  tileMode: TileMode.clamp,
                ),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(
                    alpha: settings.backgroundOpacity,
                  ),
                ),
              ),
            ),
          ),

        // 只有模糊效果关闭时才需要单独的透明度遮罩
        if (!settings.enableBackgroundBlur)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(
                alpha: settings.backgroundOpacity,
              ),
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
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('背景图片加载失败 (asset): $path, 错误: $error');
          }
          return Container(
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
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
          return Container(
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        },
      );
    }

    return imageWidget;
  }
}
