import 'package:flutter/material.dart';

/// 响应式布局工具类
///
/// 提供响应式设计的工具方法，支持移动端、平板和桌面端。
class ResponsiveUtils {
  // 断点常量
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  static const double largeDesktopBreakpoint = 1920;

  /// 判断是否为移动端
  ///
  /// 屏幕宽度 < 600px
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// 判断是否为平板
  ///
  /// 屏幕宽度 >= 600px 且 < 1024px
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// 判断是否为桌面端
  ///
  /// 屏幕宽度 >= 1024px
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// 判断是否为大屏桌面
  ///
  /// 屏幕宽度 >= 1920px
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }

  /// 获取屏幕类型
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeDesktopBreakpoint) {
      return ScreenType.largeDesktop;
    } else if (width >= desktopBreakpoint) {
      return ScreenType.desktop;
    } else if (width >= tabletBreakpoint) {
      return ScreenType.smallDesktop;
    } else if (width >= mobileBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.mobile;
    }
  }

  /// 获取响应式值
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// 获取响应式边距
  static double getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// 获取响应式字体大小
  static double getResponsiveFontSize({
    required BuildContext context,
    required double baseSize,
  }) {
    return getResponsiveValue(
      context: context,
      mobile: baseSize,
      tablet: baseSize * 1.1,
      desktop: baseSize * 1.2,
    );
  }

  /// 获取最大容器宽度
  static double getMaxContainerWidth(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return double.infinity;
      case ScreenType.tablet:
        return 768;
      case ScreenType.smallDesktop:
        return 1024;
      case ScreenType.desktop:
        return 1280;
      case ScreenType.largeDesktop:
        return 1440;
    }
  }

  /// 获取列数
  static int getGridColumns(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 1;
      case ScreenType.tablet:
        return 2;
      case ScreenType.smallDesktop:
        return 3;
      case ScreenType.desktop:
        return 4;
      case ScreenType.largeDesktop:
        return 5;
    }
  }
}

/// 屏幕类型枚举
enum ScreenType {
  mobile, // < 600px
  tablet, // 600px - 1024px
  smallDesktop, // 1024px - 1440px
  desktop, // 1440px - 1920px
  largeDesktop, // >= 1920px
}
