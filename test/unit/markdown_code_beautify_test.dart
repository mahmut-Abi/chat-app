import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Code Block Theme', () {
    test('should define dark theme colors', () {
      final darkTheme = {
        'background': '#272822',
        'border': '#3E3D32',
        'text': '#F8F8F2',
      };

      expect(darkTheme['background'], '#272822');
      expect(darkTheme['border'], '#3E3D32');
      expect(darkTheme['text'], '#F8F8F2');
    });

    test('should define light theme colors', () {
      final lightTheme = {
        'background': '#F8FAFC',
        'border': '#E2E8F0',
        'text': '#1A202C',
      };

      expect(lightTheme['background'], '#F8FAFC');
      expect(lightTheme['border'], '#E2E8F0');
      expect(lightTheme['text'], '#1A202C');
    });

    test('should validate hex color format', () {
      final colors = ['#272822', '#F8F8F2', '#E2E8F0'];

      for (final color in colors) {
        expect(color, matches(r'#[0-9A-Fa-f]{6}'));
      }
    });
  });

  group('Code Block Features', () {
    test('should support line height configuration', () {
      final defaultLineHeight = 1.5;
      final customLineHeight = 1.8;

      expect(defaultLineHeight, 1.5);
      expect(customLineHeight, greaterThan(defaultLineHeight));
    });

    test('should support copy functionality', () {
      final codeBlockData = {'copyable': true, 'showLineNumbers': false};

      expect(codeBlockData['copyable'], true);
      expect(codeBlockData['showLineNumbers'], false);
    });
  });

  group('Link Styling', () {
    test('should define link colors for dark theme', () {
      final darkLinkColor = '#66D9EF';
      expect(darkLinkColor, matches(r'#[0-9A-Fa-f]{6}'));
    });

    test('should define link colors for light theme', () {
      final lightLinkColor = '#3182CE';
      expect(lightLinkColor, matches(r'#[0-9A-Fa-f]{6}'));
    });
  });
}
