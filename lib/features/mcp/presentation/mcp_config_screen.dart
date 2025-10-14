import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/mcp_config.dart';
import '../../../core/providers/providers.dart';

class McpConfigScreen extends ConsumerStatefulWidget {
  final McpConfig? config;

  const McpConfigScreen({super.key, this.config});

  @override
  ConsumerState<McpConfigScreen> createState() => _McpConfigScreenState();
}

class _McpConfigScreenState extends ConsumerState<McpConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _endpointController;
  late TextEditingController _descriptionController;
  late TextEditingController _argsController;
  late TextEditingController _envController;

  late McpConnectionType _connectionType;
  late bool _enabled;

  @override
  void initState() {
    super.initState();

    final config = widget.config;
    _nameController = TextEditingController(text: config?.name ?? '');
    _endpointController = TextEditingController(text: config?.endpoint ?? '');
    _descriptionController = TextEditingController(
      text: config?.description ?? '',
    );
    _argsController = TextEditingController(
      text: config?.args?.join(' ') ?? '',
    );
    _envController = TextEditingController(
      text:
          config?.env?.entries.map((e) => '${e.key}=${e.value}').join('\n') ??
          '',
    );

    _connectionType = config?.connectionType ?? McpConnectionType.http;
    _enabled = config?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _descriptionController.dispose();
    _argsController.dispose();
    _envController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? '添加 MCP 服务器' : '编辑 MCP 服务器'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicSection(),
            const SizedBox(height: 24),
            if (_connectionType == McpConnectionType.stdio)
              _buildStdioSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('基本配置', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '服务器名称 *',
                hintText: '例如: 我的 MCP 服务器',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入服务器名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<McpConnectionType>(
              initialValue: _connectionType,
              decoration: const InputDecoration(
                labelText: '连接类型',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
              items: const [
                DropdownMenuItem(
                  value: McpConnectionType.http,
                  child: Row(
                    children: [
                      Icon(Icons.http, size: 20),
                      SizedBox(width: 8),
                      Text('HTTP'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: McpConnectionType.stdio,
                  child: Row(
                    children: [
                      Icon(Icons.terminal, size: 20),
                      SizedBox(width: 8),
                      Text('Stdio (命令行)'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _connectionType = value;
                    if (value == McpConnectionType.http) {
                      _endpointController.text = 'http://localhost:3000';
                    } else {
                      _endpointController.text = '/path/to/mcp-server';
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointController,
              decoration: InputDecoration(
                labelText: _connectionType == McpConnectionType.http
                    ? 'HTTP URL *'
                    : '命令路径 *',
                hintText: _connectionType == McpConnectionType.http
                    ? 'http://localhost:3000'
                    : '/path/to/mcp-server',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  _connectionType == McpConnectionType.http
                      ? Icons.link
                      : Icons.code,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入端点地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述 (可选)',
                hintText: '描述该服务器的功能',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用服务器'),
              subtitle: const Text('启用后自动连接该服务器'),
              value: _enabled,
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStdioSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stdio 配置', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '仅在连接类型为 Stdio 时有效',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _argsController,
              decoration: const InputDecoration(
                labelText: '命令行参数 (可选)',
                hintText: '用空格分隔,例如: --port 3000 --debug',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _envController,
              decoration: const InputDecoration(
                labelText: '环境变量 (可选)',
                hintText:
                    '每行一个,格式: KEY=VALUE\n例如:\nNODE_ENV=production\nPORT=3000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.eco),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(onPressed: _saveConfig, child: const Text('保存')),
        ),
      ],
    );
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // 解析参数和环境变量
      List<String>? args;
      if (_argsController.text.isNotEmpty) {
        args = _argsController.text
            .split(' ')
            .where((s) => s.isNotEmpty)
            .toList();
      }

      Map<String, String>? env;
      if (_envController.text.isNotEmpty) {
        env = {};
        for (final line in _envController.text.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && trimmed.contains('=')) {
            final parts = trimmed.split('=');
            if (parts.length == 2) {
              env[parts[0].trim()] = parts[1].trim();
            }
          }
        }
      }

      final config = McpConfig(
        id: widget.config?.id ?? _uuid.v4(),
        name: _nameController.text,
        connectionType: _connectionType,
        endpoint: _endpointController.text,
        args: args,
        env: env,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        enabled: _enabled,
        createdAt: widget.config?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(mcpRepositoryProvider);
      if (widget.config == null) {
        await repository.addConfig(config);
      } else {
        await repository.updateConfig(config);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }
}
