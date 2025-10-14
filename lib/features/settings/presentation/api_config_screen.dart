import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/providers.dart';
import '../domain/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/openai_api_client.dart';

class ApiConfigScreen extends ConsumerStatefulWidget {
  final ApiConfig? config;

  const ApiConfigScreen({super.key, this.config});

  @override
  ConsumerState<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends ConsumerState<ApiConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _organizationController;
  late TextEditingController _proxyUrlController;
  late TextEditingController _proxyUsernameController;
  late TextEditingController _proxyPasswordController;
  late TextEditingController _modelController;

  late String _selectedProvider;
  late double _temperature;
  late int _maxTokens;
  late double _topP;
  late double _frequencyPenalty;
  late double _presencePenalty;
  bool _enableProxy = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();

    final config = widget.config;
    _nameController = TextEditingController(text: config?.name ?? '');
    _baseUrlController = TextEditingController(
      text: config?.baseUrl ?? 'https://api.openai.com/v1',
    );
    _apiKeyController = TextEditingController(text: config?.apiKey ?? '');
    _organizationController = TextEditingController(
      text: config?.organization ?? '',
    );
    _proxyUrlController = TextEditingController(text: config?.proxyUrl ?? '');
    _proxyUsernameController = TextEditingController(
      text: config?.proxyUsername ?? '',
    );
    _proxyPasswordController = TextEditingController(
      text: config?.proxyPassword ?? '',
    );
    _modelController = TextEditingController(
      text: config?.defaultModel ?? 'gpt-3.5-turbo',
    );

    _selectedProvider = config?.provider ?? 'OpenAI';
    _temperature = config?.temperature ?? 0.7;
    _maxTokens = config?.maxTokens ?? 2000;
    _topP = config?.topP ?? 1.0;
    _frequencyPenalty = config?.frequencyPenalty ?? 0.0;
    _presencePenalty = config?.presencePenalty ?? 0.0;
    _enableProxy = config?.proxyUrl?.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _organizationController.dispose();
    _proxyUrlController.dispose();
    _proxyUsernameController.dispose();
    _proxyPasswordController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? '添加 API 配置' : '编辑 API 配置'),
        actions: [
          TextButton.icon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('测试连接'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicSection(),
            const SizedBox(height: 24),
            _buildProxySection(),
            const SizedBox(height: 24),
            _buildModelSection(),
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
                labelText: '配置名称 *',
                hintText: '例如: 我的 OpenAI',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入配置名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: '提供商',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud),
              ),
              items: ['OpenAI', 'Azure OpenAI', 'Ollama', 'Custom']
                  .map(
                    (provider) => DropdownMenuItem(
                      value: provider,
                      child: Text(provider),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                    _updateBaseUrlForProvider(value);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL *',
                hintText: 'https://api.openai.com/v1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入 Base URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key *',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入 API Key';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _organizationController,
              decoration: const InputDecoration(
                labelText: 'Organization ID (可选)',
                hintText: 'org-...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProxySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('代理设置', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Switch(
                  value: _enableProxy,
                  onChanged: (value) {
                    setState(() {
                      _enableProxy = value;
                    });
                  },
                ),
              ],
            ),
            if (_enableProxy) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _proxyUrlController,
                decoration: const InputDecoration(
                  labelText: '代理 URL',
                  hintText: 'http://proxy.example.com:8080',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_lock),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proxyUsernameController,
                decoration: const InputDecoration(
                  labelText: '代理用户名 (可选)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proxyPasswordController,
                decoration: const InputDecoration(
                  labelText: '代理密码 (可选)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModelSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('模型参数', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: '默认模型',
                hintText: 'gpt-3.5-turbo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.psychology),
              ),
            ),
            const SizedBox(height: 16),
            Text('Temperature: ${_temperature.toStringAsFixed(2)}'),
            Slider(
              value: _temperature,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _temperature.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _temperature = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Max Tokens: $_maxTokens'),
            Slider(
              value: _maxTokens.toDouble(),
              min: 100,
              max: 8000,
              divisions: 79,
              label: _maxTokens.toString(),
              onChanged: (value) {
                setState(() {
                  _maxTokens = value.toInt();
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Top P: ${_topP.toStringAsFixed(2)}'),
            Slider(
              value: _topP,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: _topP.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _topP = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Frequency Penalty: ${_frequencyPenalty.toStringAsFixed(2)}'),
            Slider(
              value: _frequencyPenalty,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _frequencyPenalty.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _frequencyPenalty = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Presence Penalty: ${_presencePenalty.toStringAsFixed(2)}'),
            Slider(
              value: _presencePenalty,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _presencePenalty.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _presencePenalty = value;
                });
              },
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

  void _updateBaseUrlForProvider(String provider) {
    switch (provider) {
      case 'OpenAI':
        _baseUrlController.text = 'https://api.openai.com/v1';
        break;
      case 'Azure OpenAI':
        _baseUrlController.text = 'https://YOUR_RESOURCE.openai.azure.com/';
        break;
      case 'Ollama':
        _baseUrlController.text = 'http://localhost:11434/v1';
        break;
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final dioClient = DioClient(
        baseUrl: _baseUrlController.text,
        apiKey: _apiKeyController.text,
        proxyUrl: _enableProxy ? _proxyUrlController.text : null,
      );
      final apiClient = OpenAIApiClient(dioClient);
      final result = await apiClient.testConnection();

      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = ApiConfig(
      id: widget.config?.id ?? _uuid.v4(),
      name: _nameController.text,
      provider: _selectedProvider,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      organization: _organizationController.text.isEmpty
          ? null
          : _organizationController.text,
      proxyUrl: _enableProxy && _proxyUrlController.text.isNotEmpty
          ? _proxyUrlController.text
          : null,
      proxyUsername: _enableProxy && _proxyUsernameController.text.isNotEmpty
          ? _proxyUsernameController.text
          : null,
      proxyPassword: _enableProxy && _proxyPasswordController.text.isNotEmpty
          ? _proxyPasswordController.text
          : null,
      defaultModel: _modelController.text,
      temperature: _temperature,
      maxTokens: _maxTokens,
      topP: _topP,
      frequencyPenalty: _frequencyPenalty,
      presencePenalty: _presencePenalty,
      isActive: widget.config?.isActive ?? true,
    );

    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.saveApiConfig(config);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
