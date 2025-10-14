import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 高级功能区域
class AdvancedSettingsSection extends StatelessWidget {
  const AdvancedSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud),
          title: const Text('MCP 配置'),
          subtitle: const Text('配置 Model Context Protocol 服务器'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/mcp'),
        ),
        ListTile(
          leading: const Icon(Icons.token),
          title: const Text('Token 消耗记录'),
          subtitle: const Text('查看所有对话的 Token 消耗'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/token-usage'),
        ),
      ],
    );
  }
}
