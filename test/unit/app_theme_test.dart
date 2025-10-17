import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/shared/themes/app_theme.dart';

void main() {
  group('AppTheme - Bug #2 字体大小修复验证', () {
    test('验证默认字体大小', () {
      final theme = AppTheme.getLightTheme();
      expect(theme.textTheme, isNotNull);
      expect(theme.textTheme.bodyMedium?.fontSize, equals(14.0));
    });

    test('验证自定义字体大小 - 增大', () {
      const customFontSize = 18.0;
      final theme = AppTheme.getLightTheme(null, customFontSize);

      expect(theme.textTheme, isNotNull);

      // 验证缩放比例
      final scale = customFontSize / AppTheme.defaultFontSize;
      expect(theme.textTheme.bodyMedium?.fontSize, equals(14.0 * scale));
      expect(theme.textTheme.bodyLarge?.fontSize, equals(16.0 * scale));
      expect(theme.textTheme.bodySmall?.fontSize, equals(12.0 * scale));
    });

    test('验证自定义字体大小 - 减小', () {
      const customFontSize = 10.0;
      final theme = AppTheme.getDarkTheme(null, customFontSize);

      expect(theme.textTheme, isNotNull);

      // 验证缩放比例
      final scale = customFontSize / AppTheme.defaultFontSize;
      expect(theme.textTheme.bodyMedium?.fontSize, equals(14.0 * scale));
      expect(theme.textTheme.titleLarge?.fontSize, equals(22.0 * scale));
      expect(theme.textTheme.labelSmall?.fontSize, equals(11.0 * scale));
    });

    test('验证所有文本样式都应用了字体大小', () {
      const customFontSize = 16.0;
      final theme = AppTheme.getLightTheme(null, customFontSize);
      final scale = customFontSize / AppTheme.defaultFontSize;

      // 验证所有重要的文本样式
      expect(theme.textTheme.displayLarge?.fontSize, equals(57.0 * scale));
      expect(theme.textTheme.displayMedium?.fontSize, equals(45.0 * scale));
      expect(theme.textTheme.displaySmall?.fontSize, equals(36.0 * scale));
      expect(theme.textTheme.headlineLarge?.fontSize, equals(32.0 * scale));
      expect(theme.textTheme.headlineMedium?.fontSize, equals(28.0 * scale));
      expect(theme.textTheme.headlineSmall?.fontSize, equals(24.0 * scale));
      expect(theme.textTheme.titleLarge?.fontSize, equals(22.0 * scale));
      expect(theme.textTheme.titleMedium?.fontSize, equals(16.0 * scale));
      expect(theme.textTheme.titleSmall?.fontSize, equals(14.0 * scale));
      expect(theme.textTheme.bodyLarge?.fontSize, equals(16.0 * scale));
      expect(theme.textTheme.bodyMedium?.fontSize, equals(14.0 * scale));
      expect(theme.textTheme.bodySmall?.fontSize, equals(12.0 * scale));
      expect(theme.textTheme.labelLarge?.fontSize, equals(14.0 * scale));
      expect(theme.textTheme.labelMedium?.fontSize, equals(12.0 * scale));
      expect(theme.textTheme.labelSmall?.fontSize, equals(11.0 * scale));
    });

    test('验证 light 和 dark 主题使用相同的字体大小', () {
      const customFontSize = 16.0;
      final lightTheme = AppTheme.getLightTheme(null, customFontSize);
      final darkTheme = AppTheme.getDarkTheme(null, customFontSize);

      expect(
        lightTheme.textTheme.bodyMedium?.fontSize,
        equals(darkTheme.textTheme.bodyMedium?.fontSize),
      );
      expect(
        lightTheme.textTheme.titleLarge?.fontSize,
        equals(darkTheme.textTheme.titleLarge?.fontSize),
      );
    });
  });
}
