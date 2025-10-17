import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../core/providers/providers.dart';
import 'package:flutter/foundation.dart';
import '../../features/settings/domain/api_config.dart';

class BackgroundContainer extends ConsumerWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) => _buildWithBackground(context, settings),
      loading: () => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
      error: (error, stack) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
    );
  }

  Widget _buildWithBackground(BuildContext context, AppSettings settings) {
    final backgroundImage = settings.backgroundImage;

    if (kDebugMode) {
      print('BackgroundContainer: backgroundImage = $backgroundImage');
      print('BackgroundContainer: opacity = ${settings.backgroundOpacity}');
    }

    // 没有背景图片时,使用主题背景色
    if (backgroundImage == null || backgroundImage.isEmpty) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      );
    }

    // 计算内容层的透明度
    // backgroundOpacity 表示内容的不透明度 (0.8 = 80% 不透明, 20% 透明)
    final maskOpacity = 1.0 - settings.backgroundOpacity;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片
        Positioned.fill(child: _buildBackgroundImage(backgroundImage)),

        // 透明度遮罩
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
