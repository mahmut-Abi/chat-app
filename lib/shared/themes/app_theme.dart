import 'package:flutter/material.dart';
import '../../core/utils/no_transition_builder.dart';

class AppTheme {
  // 默认字体大小
  static const double defaultFontSize = 14.0;

  // 预设主题颜色
  static const Map<String, Color> predefinedColors = {
    'indigo': Color(0xFF6366F1),
    'purple': Color(0xFF8B5CF6),
    'blue': Color(0xFF3B82F6),
    'cyan': Color(0xFF06B6D4),
    'teal': Color(0xFF14B8A6),
    'green': Color(0xFF10B981),
    'orange': Color(0xFFF97316),
    'red': Color(0xFFEF4444),
    'pink': Color(0xFFEC4899),
  };

  static ThemeData getLightTheme([
    Color? seedColor,
    double fontSize = defaultFontSize,
  ]) {
    final color = seedColor ?? predefinedColors['indigo']!;
    final textTheme = _buildTextTheme(fontSize);
    return ThemeData(
      useMaterial3: true,
      textTheme: textTheme,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: _OpaquePageTransitionsBuilder(
            const CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.android: _OpaquePageTransitionsBuilder(
            const FadeUpwardsPageTransitionsBuilder(),
          ),
          TargetPlatform.macOS: const NoTransitionBuilder(),
          TargetPlatform.windows: const NoTransitionBuilder(),
          TargetPlatform.linux: const NoTransitionBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: Brightness.light,
      ).copyWith(primary: color, secondary: color),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme([
    Color? seedColor,
    double fontSize = defaultFontSize,
  ]) {
    final color = seedColor ?? predefinedColors['indigo']!;
    final textTheme = _buildTextTheme(fontSize);
    return ThemeData(
      useMaterial3: true,
      textTheme: textTheme,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: _OpaquePageTransitionsBuilder(
            const CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.android: _OpaquePageTransitionsBuilder(
            const FadeUpwardsPageTransitionsBuilder(),
          ),
          TargetPlatform.macOS: const NoTransitionBuilder(),
          TargetPlatform.windows: const NoTransitionBuilder(),
          TargetPlatform.linux: const NoTransitionBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: Brightness.dark,
      ).copyWith(primary: color, secondary: color),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // 为了向后兼容
  static ThemeData get lightTheme => getLightTheme();
  static ThemeData get darkTheme => getDarkTheme();

  // 构建动态字体大小的 TextTheme
  static TextTheme _buildTextTheme(double fontSize) {
    final scale = fontSize / defaultFontSize;
    return TextTheme(
      displayLarge: TextStyle(fontSize: 57 * scale),
      displayMedium: TextStyle(fontSize: 45 * scale),
      displaySmall: TextStyle(fontSize: 36 * scale),
      headlineLarge: TextStyle(fontSize: 32 * scale),
      headlineMedium: TextStyle(fontSize: 28 * scale),
      headlineSmall: TextStyle(fontSize: 24 * scale),
      titleLarge: TextStyle(fontSize: 22 * scale),
      titleMedium: TextStyle(fontSize: 16 * scale),
      titleSmall: TextStyle(fontSize: 14 * scale),
      bodyLarge: TextStyle(fontSize: 16 * scale),
      bodyMedium: TextStyle(fontSize: 14 * scale),
      bodySmall: TextStyle(fontSize: 12 * scale),
      labelLarge: TextStyle(fontSize: 14 * scale),
      labelMedium: TextStyle(fontSize: 12 * scale),
      labelSmall: TextStyle(fontSize: 11 * scale),
    );
  }
}

/// 为移动端转场动画添加不透明背景
/// 避免在透明背景时页面重叠
class _OpaquePageTransitionsBuilder extends PageTransitionsBuilder {
  final PageTransitionsBuilder _delegate;

  const _OpaquePageTransitionsBuilder(this._delegate);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 使用委托构建器执行转场动画
    final transition = _delegate.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );

    // 在转场动画外层添加不透明背景层
    // 避免新旧页面重叠时透过背景看到彼此
    return Stack(
      fit: StackFit.expand,
      children: [
        // 不透明背景层
        ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        // 转场动画内容
        transition,
      ],
    );
  }
}
