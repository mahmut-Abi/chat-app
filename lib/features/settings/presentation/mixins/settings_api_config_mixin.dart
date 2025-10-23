import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/openai_api_client.dart';
import '../../domain/api_config.dart';

import '../../../../shared/widgets/platform_dialog.dart';

/// API 配置管理相关的 Mixin
mixin SettingsApiConfigMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  Future<void> addApiConfig(VoidCallback onSuccess) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => Container()));

    if (result == true) {
      // 刷新 activeApiConfigProvider
      ref.invalidate(activeApiConfigProvider);
      onSuccess();
    }
  }

  Future<void> editApiConfig(ApiConfig config, VoidCallback onSuccess) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Container(),
      ),
    );

    if (result == true) {
      // 刷新 activeApiConfigProvider
      ref.invalidate(activeApiConfigProvider);
      onSuccess();
    }
  }

  Future<void> deleteApiConfig(ApiConfig config, VoidCallback onSuccess) async {
    final confirm = await _showDeleteConfirmDialog();
    if (confirm == true) {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.deleteApiConfig(config.id);
      // 刷新 activeApiConfigProvider
      ref.invalidate(activeApiConfigProvider);
      onSuccess();
    }
  }

  Future<bool?> _showDeleteConfirmDialog() {
    return showPlatformConfirmDialog(
      context: context,
      title: '删除 API 配置',
      content: '确定要删除此配置吗？',
      confirmText: '删除',
      isDestructive: true,
    );
  }

  Future<void> testApiConnection(ApiConfig config) async {
    showPlatformLoadingDialog(context: context, message: '正在测试连接...');

    try {
      final dioClient = DioClient(
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
        proxyUrl: config.proxyUrl,
      );
      final apiClient = OpenAIApiClient(dioClient, config.provider);
      final result = await apiClient.testConnection();

      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result.success ? '连接成功' : '连接失败'),
            content: Text(result.message),
            icon: Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
              size: 48,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('连接失败'),
            content: Text('发生错误: ${e.toString()}'),
            icon: const Icon(Icons.error, color: Colors.red, size: 48),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }
}
