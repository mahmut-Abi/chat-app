import 'package:flutter/material.dart';
import '../../domain/api_config.dart';

/// API 配置区域
class ApiConfigSection extends StatelessWidget {
  final List<ApiConfig> apiConfigs;
  final VoidCallback onAddConfig;
  final Function(ApiConfig) onEditConfig;
  final Function(ApiConfig) onDeleteConfig;
  final Function(ApiConfig) onTestConnection;

  const ApiConfigSection({
    super.key,
    required this.apiConfigs,
    required this.onAddConfig,
    required this.onEditConfig,
    required this.onDeleteConfig,
    required this.onTestConnection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...apiConfigs.map((config) => _buildApiConfigTile(context, config)),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('添加 API 配置'),
          onTap: onAddConfig,
        ),
      ],
    );
  }

  Widget _buildApiConfigTile(BuildContext context, ApiConfig config) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          _getProviderIcon(config.provider),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(config.name),
        subtitle: Text(
          '${_getProviderName(config.provider)} • ${config.isActive ? "激活" : "未激活"}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.wifi),
              tooltip: '测试连接',
              onPressed: () => onTestConnection(config),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('编辑'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () =>
                      Future.delayed(Duration.zero, () => onEditConfig(config)),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      '删除',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () => Future.delayed(
                    Duration.zero,
                    () => onDeleteConfig(config),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return Icons.auto_awesome;
      case 'azure':
        return Icons.cloud;
      case 'ollama':
        return Icons.computer;
      default:
        return Icons.api;
    }
  }

  String _getProviderName(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return 'OpenAI';
      case 'azure':
        return 'Azure OpenAI';
      case 'ollama':
        return 'Ollama';
      default:
        return provider;
    }
  }
}
