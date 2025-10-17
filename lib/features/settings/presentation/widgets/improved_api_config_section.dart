import 'package:flutter/material.dart';
import '../../domain/api_config.dart';
import '../../../../core/services/log_service.dart';

/// 改进的 API 配置区域
class ImprovedApiConfigSection extends StatelessWidget {
  final List<ApiConfig> apiConfigs;
  final VoidCallback onAddConfig;
  final Function(ApiConfig) onEditConfig;
  final Function(ApiConfig) onDeleteConfig;
  final Function(ApiConfig) onTestConnection;

  const ImprovedApiConfigSection({
    super.key,
    required this.apiConfigs,
    required this.onAddConfig,
    required this.onEditConfig,
    required this.onDeleteConfig,
    required this.onTestConnection,
  });

  @override
  Widget build(BuildContext context) {
    final log = LogService();

    return Column(
      children: [
        _buildInfoBanner(context),
        const SizedBox(height: 8),
        if (apiConfigs.isEmpty) _buildEmptyState(context),
        ...apiConfigs.map((config) {
          log.debug('渲染 API 配置项', {'configId': config.id});
          return _buildApiConfigCard(context, config);
        }),
        const SizedBox(height: 8),
        _buildAddButton(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.api_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无 API 配置',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加你的第一个 API 配置',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApiConfigCard(BuildContext context, ApiConfig config) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildProviderAvatar(context, config.provider),
        title: Row(
          children: [
            Expanded(
              child: Text(
                config.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _getProviderName(config.provider),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: _buildActions(context, config),
      ),
    );
  }

  Widget _buildProviderAvatar(BuildContext context, String provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getProviderIcon(provider),
        color: isActive ? colorScheme.onPrimary : colorScheme.primary,
        size: 24,
      ),
    );
  }

  Widget _buildActions(BuildContext context, ApiConfig config) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.wifi_outlined),
          tooltip: '测试连接',
          onPressed: () => onTestConnection(config),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Text('编辑'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '删除',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              onEditConfig(config);
            } else if (value == 'delete') {
              onDeleteConfig(config);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: onAddConfig,
        icon: const Icon(Icons.add),
        label: const Text('添加 API 配置'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '配置你的 AI 提供商，支持 OpenAI、Azure 和 Ollama',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
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
