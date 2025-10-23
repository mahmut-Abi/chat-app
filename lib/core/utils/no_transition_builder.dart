import 'package:flutter/material.dart';

/// 桌面端无转场动画构建器
/// 桌面应用通常不需要页面转场动画
class NoTransitionBuilder extends PageTransitionsBuilder {
  const NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 使用 FadeTransition 避免在背景透明时页面重叠
    // 为旧页面添加淡出效果
    if (secondaryAnimation.status == AnimationStatus.forward ||
        secondaryAnimation.status == AnimationStatus.completed) {
      return FadeTransition(
        opacity: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(secondaryAnimation),
        child: child,
      );
    }
    // 新页面直接显示（无动画）
    return child;
  }
}
