import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/api_config.dart';
import '../../../../core/providers/providers.dart';

class ApiConfigEditScreen extends ConsumerStatefulWidget {
  final ApiConfig? config;

  const ApiConfigEditScreen({super.key, this.config});

  @override
  ConsumerState<ApiConfigEditScreen> createState() =>
      _ApiConfigEditScreenState();
}

class _ApiConfigEditScreenState extends ConsumerState<ApiConfigEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _providerController;
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _organizationController;
  late TextEditingController _proxyUrlController;
  late TextEditingController _proxyUsernameController;
  late TextEditingController _proxyPasswordController;
  late TextEditingController _defaultModelController;

  late bool _isActive;
  late double _temperature;
  late int _maxTokens;
  late double _topP;
  late double _frequencyPenalty;
  late double _presencePenalty;
  late bool _enableWebSearch;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _nameController = TextEditingController(text: config?.name ?? '');
    _providerController = TextEditingController(text: config?.provider ?? 'openai');
    _baseUrlController = TextEditingController(text: config?.baseUrl ?? 'https://api.openai.com/v1');
    _apiKeyController = TextEditingController(text: config?.apiKey ?? '');
    _organizationController = TextEditingController(text: config?.organization ?? '');
    _proxyUrlController = TextEditingController(text: config?.proxyUrl ?? '');
    _proxyUsernameController = TextEditingController(text: config?.proxyUsername ?? '');
    _proxyPasswordController = TextEditingController(text: config?.proxyPassword ?? '');
    _defaultModelController = TextEditingController(text: config?.defaultModel ?? 'gpt-3.5-turbo');
    _isActive = config?.isActive ?? true;
    _temperature = config?.temperature ?? 0.7;
    _maxTokens = config?.maxTokens ?? 2000;
    _topP = config?.topP ?? 1.0;
    _frequencyPenalty = config?.frequencyPenalty ?? 0.0;
    _presencePenalty = config?.presencePenalty ?? 0.0;
    _enableWebSearch = config?.enableWebSearch ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _organizationController.dispose();
    _proxyUrlController.dispose();
    _proxyUsernameController.dispose();
    _proxyPasswordController.dispose();
    _defaultModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? '创建 API 配置' : '编辑 API 配置'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicSection(),
            const SizedBox(height: 24),
            _buildConnectionSection(),
            const SizedBox(height: 24),
            _buildProxySection(),
            const SizedBox(height: 24),
            _buildModelParametersSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSection() => Card(
    color: Theme.of(context).cardColor.withOpacity(0.7),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('基本信息', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '配置名称 *', hintText: '例如: My OpenAI API', border: OutlineInputBorder(), prefixIcon: Icon(Icons.label)),
            validator: (value) => (value == null || value.isEmpty) ? '请输入配置名称' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _providerController.text,
            items: ['openai', 'azure', 'ollama'].map((provider) => DropdownMenuItem(value: provider, child: Text(_getProviderName(provider)))).toList(),
            onChanged: (value) { if (value != null) { _providerController.text = value; _updateBaseUrlForProvider(value); }},
            decoration: const InputDecoration(labelText: 'AI 提供商 *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.cloud_queue)),
          ),
          const SizedBox(height: 16),
          SwitchListTile(title: const Text('启用此配置'), subtitle: const Text('启用后可在聊天中使用'), value: _isActive, onChanged: (value) { setState(() { _isActive = value; }); }),
        ],
      ),
    ),
  );

  Widget _buildConnectionSection() => Card(
    color: Theme.of(context).cardColor.withOpacity(0.7),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('连接信息', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _baseUrlController,
            decoration: const InputDecoration(labelText: 'API 基础 URL *', hintText: 'https://api.openai.com/v1', border: OutlineInputBorder(), prefixIcon: Icon(Icons.public)),
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入 API 基础 URL';
              if (!value.startsWith('http')) return '请输入有效的 URL (以 http:// 或 https:// 开头)';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key *', hintText: '你的 API Key', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.vpn_key),
              suffixIcon: IconButton(icon: const Icon(Icons.visibility_off), onPressed: () {}),
            ),
            obscureText: true,
            validator: (value) => (value == null || value.isEmpty) ? '请输入 API Key' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _organizationController,
            decoration: const InputDecoration(labelText: '组织 ID (可选)', hintText: '如果需要指定组织', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
          ),
        ],
      ),
    ),
  );

  Widget _buildProxySection() => Card(
    color: Theme.of(context).cardColor.withOpacity(0.7),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('代理设置 (可选)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('如需代理访问 API，请在此配置', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextFormField(controller: _proxyUrlController, decoration: const InputDecoration(labelText: '代理 URL', hintText: 'http://proxy.example.com:8080', border: OutlineInputBorder(), prefixIcon: Icon(Icons.router))),
          const SizedBox(height: 16),
          TextFormField(controller: _proxyUsernameController, decoration: const InputDecoration(labelText: '代理用户名', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 16),
          TextFormField(controller: _proxyPasswordController, decoration: const InputDecoration(labelText: '代理密码', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)), obscureText: true),
        ],
      ),
    ),
  );

  Widget _buildModelParametersSection() => Card(
    color: Theme.of(context).cardColor.withOpacity(0.7),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('模型参数', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(controller: _defaultModelController, decoration: const InputDecoration(labelText: '默认模型', hintText: '例如: gpt-3.5-turbo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.model_training))),
          const SizedBox(height: 24),
          _buildSlider(label: '温度 (Temperature)', value: _temperature, min: 0.0, max: 2.0, divisions: 20, onChanged: (v) => setState(() => _temperature = v), description: '值越低越确定，值越高越随机'),
          const SizedBox(height: 16),
          _buildSlider(label: 'Top P', value: _topP, min: 0.0, max: 1.0, divisions: 10, onChanged: (v) => setState(() => _topP = v), description: '控制多样性 (nucleus sampling)'),
          const SizedBox(height: 16),
          _buildSlider(label: '频率罚分 (Frequency Penalty)', value: _frequencyPenalty, min: -2.0, max: 2.0, divisions: 20, onChanged: (v) => setState(() => _frequencyPenalty = v), description: '降低重复频率'),
          const SizedBox(height: 16),
          _buildSlider(label: '存在罚分 (Presence Penalty)', value: _presencePenalty, min: -2.0, max: 2.0, divisions: 20, onChanged: (v) => setState(() => _presencePenalty = v), description: '促进提及新话题'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Max Tokens', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('最大生成 token 数', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: _maxTokens.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (value) { setState(() { _maxTokens = int.tryParse(value) ?? 2000; }); },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(title: const Text('启用网络搜索'), subtitle: const Text('允许模型访问网络搜索结果'), value: _enableWebSearch, onChanged: (value) { setState(() { _enableWebSearch = value; }); }),
        ],
      ),
    ),
  );

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String description,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(value.toStringAsFixed(2), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      const SizedBox(height: 4),
      Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
    ],
  );

  Widget _buildActionButtons() => Row(
    children: [
      Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消'))),
      const SizedBox(width: 16),
      Expanded(child: FilledButton(onPressed: _saveConfig, child: const Text('保存'))),
    ],
  );

  void _updateBaseUrlForProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'azure':
        _baseUrlController.text = 'https://{resource-name}.openai.azure.com/';
        break;
      case 'ollama':
        _baseUrlController.text = 'http://localhost:11434/v1';
        break;
      default:
        _baseUrlController.text = 'https://api.openai.com/v1';
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

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final config = ApiConfig(
        id: widget.config?.id ?? _uuid.v4(),
        name: _nameController.text,
        provider: _providerController.text,
        baseUrl: _baseUrlController.text,
        apiKey: _apiKeyController.text,
        organization: _organizationController.text.isEmpty ? null : _organizationController.text,
        proxyUrl: _proxyUrlController.text.isEmpty ? null : _proxyUrlController.text,
        proxyUsername: _proxyUsernameController.text.isEmpty ? null : _proxyUsernameController.text,
        proxyPassword: _proxyPasswordController.text.isEmpty ? null : _proxyPasswordController.text,
        isActive: _isActive,
        defaultModel: _defaultModelController.text,
        temperature: _temperature,
        maxTokens: _maxTokens,
        topP: _topP,
        frequencyPenalty: _frequencyPenalty,
        presencePenalty: _presencePenalty,
        enableWebSearch: _enableWebSearch,
      );
      final settingsRepo = ref.read(settingsRepositoryProvider);
      if (widget.config == null) {
        await settingsRepo.createApiConfig(
        name: config.name,
        provider: config.provider,
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
        organization: config.organization,
        proxyUrl: config.proxyUrl,
        proxyUsername: config.proxyUsername,
        proxyPassword: config.proxyPassword,
        defaultModel: config.defaultModel,
        temperature: config.temperature,
        maxTokens: config.maxTokens,
        topP: config.topP,
        frequencyPenalty: config.frequencyPenalty,
        presencePenalty: config.presencePenalty,
      );
      } else {
        await settingsRepo.saveApiConfig(config);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }
}
