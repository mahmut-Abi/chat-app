import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/openai_api_client.dart';
import '../../../../shared/utils/dialog_helper.dart';
import '../../domain/api_config.dart';
import '../screens/api_config_edit_screen.dart';
import '../services/settings_service.dart';

/// 简化后的 API 配置 Mixin
mixin SettingsApiConfigMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  late SettingsService _settingsService;

  @override
  void didChangeDependencies() {
    _settingsService = SettingsService(ref, context);
    super.didChangeDependencies();
  }

  Future<void> addApiConfig(VoidCallback onSuccess) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ApiConfigEditScreen()),
    );

    if (result == true) {
      _settingsService.refreshActiveApiConfig();
      onSuccess();
    }
  }

  Future<void> editApiConfig(ApiConfig config, VoidCallback onSuccess) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ApiConfigEditScreen(config: config),
      ),
    );

    if (result == true) {
      _settingsService.refreshActiveApiConfig();
      onSuccess();
    }
  }

  Future<void> deleteApiConfig(ApiConfig config, VoidCallback onSuccess) async {
    final confirm = await DialogHelper.showConfirmDialog(
      context: context,
      title: '删除 API 配置',
      message: '确定要删除此配置吗？',
      confirmText: '删除',
      isDestructive: true,
    );

    if (confirm == true) {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.deleteApiConfig(config.id);
      _settingsService.refreshActiveApiConfig();
      onSuccess();
    }
  }

  Future<void> testApiConnection(ApiConfig config) async {
    try {
      await DialogHelper.showLoadingDialog(
        context: context,
        message: '正在测试连接...',
      );

      final dioClient = DioClient(
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
        proxyUrl: config.proxyUrl,
      );
      final apiClient = OpenAIApiClient(dioClient, config.provider);
      final result = await apiClient.testConnection();

      if (mounted) {
        Navigator.of(context).pop();
        await DialogHelper.showInfoDialog(
          context: context,
          title: result.success ? '连接成功' : '连接失败',
          message: result.message,
          icon: Icon(
            result.success ? Icons.check_circle : Icons.error,
            color: result.success ? Colors.green : Colors.red,
            size: 48,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        await DialogHelper.showInfoDialog(
          context: context,
          title: '连接失败',
          message: '发生错误: ${e.toString()}',
          icon: const Icon(Icons.error, color: Colors.red, size: 48),
        );
      }
    }
  }
}
