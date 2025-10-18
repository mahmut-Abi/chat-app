import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../features/settings/domain/api_config.dart';
import '../utils/background_image_cache.dart';

/// 页面背景 Widget
/// 
/// 为每个页面提供独立的背景图片，使用缓存优化性能
/// 支持页面转场时背景图片的流畅显示
class PageBackground extends ConsumerWidget {
  final Widget child;
  
  const PageBackground({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    
    return settingsAsync.when(
      data: (settings) => _buildWithBackground(context, settings),
      loading: () => _buildFallback(context),
      error: (_, __) => _buildFallback(context),
    );
  }
  
  Widget _buildWithBackground(BuildContext context, AppSettings settings) {
    final backgroundImage = BackgroundImageCache.getImage(settings.backgroundImage);
    
    if (backgroundImage == null) {
      // 没有背景图片，使用纯色背景
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      );
    }
    
    // 有背景图片，使用图片 + 半透明遮罩
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: backgroundImage,
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(
          alpha: 1.0 - settings.backgroundOpacity,
        ),
        child: child,
      ),
    );
  }
  
  Widget _buildFallback(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}
