import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Settings Providers
/// App settings, theme, language related

// ============ Current App Settings ============

/// Current App Settings Provider
final currentAppSettingsProvider = FutureProvider.autoDispose<AppSettings?>((ref) async {
  // Simple implementation for now
  return AppSettings(theme: 'light', language: 'en');
});

// ============ App Settings Model ============

class AppSettings {
  final String theme;
  final String language;

  AppSettings({required this.theme, required this.language});
}
