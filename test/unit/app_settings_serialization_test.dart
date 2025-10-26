import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/settings/domain/api_config.dart';

void main() {
  group('AppSettings 序列化测试', () {
    test('所有字段都能正确序列化和反序列化', () {
      // 创建一个包含所有字段的 AppSettings
      final settings = const AppSettings(
        themeMode: 'dark',
        language: 'zh',
        fontSize: 16.0,
        enableMarkdown: true,
        enableCodeHighlight: true,
        enableLatex: true,
        themeColor: 'blue',
        customThemeColor: 0xFF0000FF,
        backgroundImage: 'assets/bg.jpg',
        backgroundOpacity: 0.5,
      );

      // 转换为 JSON
      final json = settings.toJson();

      // 验证所有字段都在 JSON 中
      expect(json['themeMode'], 'dark');
      expect(json['language'], 'zh');
      expect(json['fontSize'], 16.0);
      expect(json['enableMarkdown'], true);
      expect(json['enableCodeHighlight'], true);
      expect(json['enableLatex'], true);
      expect(json['themeColor'], 'blue');
      expect(json['customThemeColor'], 0xFF0000FF);
      expect(json['backgroundImage'], 'assets/bg.jpg');
      expect(json['backgroundOpacity'], 0.5);

      // 从 JSON 反序列化
      final deserializedSettings = AppSettings.fromJson(json);

      // 验证反序列化的设置与原始设置相同
      expect(deserializedSettings.themeMode, settings.themeMode);
      expect(deserializedSettings.language, settings.language);
      expect(deserializedSettings.fontSize, settings.fontSize);
      expect(deserializedSettings.enableMarkdown, settings.enableMarkdown);
      expect(
        deserializedSettings.enableCodeHighlight,
        settings.enableCodeHighlight,
      );
      expect(deserializedSettings.enableLatex, settings.enableLatex);
      expect(deserializedSettings.themeColor, settings.themeColor);
      expect(deserializedSettings.customThemeColor, settings.customThemeColor);
      expect(deserializedSettings.backgroundImage, settings.backgroundImage);
      expect(
        deserializedSettings.backgroundOpacity,
        settings.backgroundOpacity,
      );
    });

    test('copyWith 方法能正确更新字段', () {
      final original = const AppSettings(
        themeMode: 'light',
        fontSize: 14.0,
        backgroundImage: 'old.jpg',
      );

      // 测试更新单个字段
      final updated1 = original.copyWith(themeMode: 'dark');
      expect(updated1.themeMode, 'dark');
      expect(updated1.fontSize, 14.0);
      expect(updated1.backgroundImage, 'old.jpg');

      // 测试更新多个字段
      final updated2 = original.copyWith(
        fontSize: 16.0,
        backgroundOpacity: 0.8,
      );
      expect(updated2.fontSize, 16.0);
      expect(updated2.backgroundOpacity, 0.8);
      expect(updated2.themeMode, 'light');

      // 测试清除背景图片
      final updated3 = original.copyWith(clearBackgroundImage: true);
      expect(updated3.backgroundImage, null);

      // 测试设置新背景图片
      final updated4 = original.copyWith(backgroundImage: 'new.jpg');
      expect(updated4.backgroundImage, 'new.jpg');
    });

    test('默认值能正确应用', () {
      final defaultSettings = const AppSettings();

      expect(defaultSettings.themeMode, 'system');
      expect(defaultSettings.language, 'en');
      expect(defaultSettings.fontSize, 14.0);
      expect(defaultSettings.enableMarkdown, true);
      expect(defaultSettings.enableCodeHighlight, true);
      expect(defaultSettings.enableLatex, false);
      expect(defaultSettings.themeColor, null);
      expect(defaultSettings.customThemeColor, null);
      expect(defaultSettings.backgroundImage, null);
      expect(defaultSettings.backgroundOpacity, 0.8);
    });
  });
}
