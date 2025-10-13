import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';

/// iOS 玻璃质感容器 - 支持 iOS 26+ 的毛玻璃效果
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool enableShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.15,
    this.borderRadius,
    this.border,
    this.padding,
    this.backgroundColor,
    this.enableShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isIOS) {
      // 非 iOS 平台使用半透明背景和轻微模糊
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur * 0.5, sigmaY: blur * 0.5),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color:
                  backgroundColor ??
                  (isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.7)),
              borderRadius: borderRadius,
              border:
                  border ??
                  Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
            ),
            child: child,
          ),
        ),
      );
    }

    // iOS 平台使用完整的玻璃质感效果
    final effectiveBackgroundColor =
        backgroundColor ??
        (isDark
            ? Colors.black.withValues(alpha: opacity)
            : Colors.white.withValues(alpha: opacity));

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        decoration: enableShadow
            ? BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // 使用渐变色增强玻璃质感
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveBackgroundColor,
                  effectiveBackgroundColor.withValues(alpha: opacity * 0.8),
                ],
              ),
              borderRadius: borderRadius,
              border: border ?? Border.all(color: borderColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 毛玻璃卡片 - 预设样式的玻璃容器
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: GlassContainer(
        blur: 25.0,
        opacity: 0.2,
        borderRadius: BorderRadius.circular(16),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
