import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../domain/api_config.dart';

/// 统一的设置管理服务，整合多个 Mixin 的功能
class SettingsService {
  final WidgetRef ref;
  final BuildContext context;

  SettingsService(this.ref, this.context);

  /// 更新应用设置
  Future<void> updateAppSettings(
    AppSettings Function(AppSettings) updater,
  ) async {
    final currentSettings = await ref.read(appSettingsProvider.future);
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(updater(currentSettings));
  }

  /// 刷新活跃 API 配置
  void refreshActiveApiConfig() {
    ref.invalidate(activeApiConfigProvider);
  }

  /// 刷新 Agent 配置
  void refreshAgentConfigs() {
    ref.invalidate(agentConfigsProvider);
  }
}
