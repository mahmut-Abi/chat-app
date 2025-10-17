import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/providers.dart';
import '../domain/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/openai_api_client.dart';
import 'widgets/api_config_basic_section.dart';
import 'widgets/api_config_proxy_section.dart';
import 'widgets/api_config_model_section.dart';
import '../../models/domain/model.dart';

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

  late String _selectedProvider;
  String? _selectedModel;
  List<String> _availableModels = [];
  bool _isLoadingModels = false;
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

    _selectedProvider = config?.provider ?? 'OpenAI';
    _selectedModel = config?.defaultModel ?? 'gpt-3.5-turbo';
    _availableModels = [_selectedModel!]; // 初始化至少包含当前模型
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
            ApiConfigBasicSection(
              nameController: _nameController,
              baseUrlController: _baseUrlController,
              apiKeyController: _apiKeyController,
              organizationController: _organizationController,
              selectedProvider: _selectedProvider,
              onProviderChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                    _updateBaseUrlForProvider(value);
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ApiConfigProxySection(
              enableProxy: _enableProxy,
              proxyUrlController: _proxyUrlController,
              proxyUsernameController: _proxyUsernameController,
              proxyPasswordController: _proxyPasswordController,
              onProxyChanged: (value) {
                setState(() => _enableProxy = value ?? false);
              },
            ),
            const SizedBox(height: 24),
            ApiConfigModelSection(
              selectedModel: _selectedModel,
              availableModels: _availableModels,
              isLoadingModels: _isLoadingModels,
              temperature: _temperature,
              maxTokens: _maxTokens,
              topP: _topP,
              frequencyPenalty: _frequencyPenalty,
              presencePenalty: _presencePenalty,
              onModelChanged: (value) => setState(() => _selectedModel = value),
              onFetchModels: _fetchAvailableModels,
              onTemperatureChanged: (value) {
                setState(() => _temperature = value);
              },
              onMaxTokensChanged: (value) {
                setState(() => _maxTokens = value.round());
              },
              onTopPChanged: (value) {
                setState(() => _topP = value);
              },
              onFrequencyPenaltyChanged: (value) {
                setState(() => _frequencyPenalty = value);
              },
              onPresencePenaltyChanged: (value) {
                setState(() => _presencePenalty = value);
              },
            ),
            const SizedBox(height: 32),
            _buildActionButtons(),
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
      case 'DeepSeek':
        _baseUrlController.text = 'https://api.deepseek.com/v1';
        break;
      case '智谱 AI (GLM)':
        _baseUrlController.text = 'https://open.bigmodel.cn/api/paas/v4';
        break;
      case '月之暗面 (Moonshot)':
        _baseUrlController.text = 'https://api.moonshot.cn/v1';
        break;
      case '百川智能 (Baichuan)':
        _baseUrlController.text = 'https://api.baichuan-ai.com/v1';
        break;
      case '阿里云 (Qwen)':
        _baseUrlController.text =
            'https://dashscope.aliyuncs.com/compatible-mode/v1';
        break;
      case '讯飞星火 (Spark)':
        _baseUrlController.text = 'https://spark-api.xf-yun.com/v1';
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

    setState(() => _isTesting = true);

    try {
      final dioClient = DioClient(
        baseUrl: _baseUrlController.text,
        apiKey: _apiKeyController.text,
        proxyUrl: _enableProxy ? _proxyUrlController.text : null,
        proxyUsername: _enableProxy ? _proxyUsernameController.text : null,
        proxyPassword: _enableProxy ? _proxyPasswordController.text : null,
      );
      final apiClient = OpenAIApiClient(dioClient, _selectedProvider);
      final result = await apiClient.testConnection();

      // 测试成功后自动获取模型列表
      if (result.success && mounted) {
        try {
          final models = await apiClient.getAvailableModels();
          if (mounted) {
            setState(() {
              _availableModels = models;
              // 如果没有选中模型或不在列表中，选择第一个
              if (models.isNotEmpty &&
                  (_selectedModel == null ||
                      !models.contains(_selectedModel))) {
                _selectedModel = models.first;
              }
            });
          }
        } catch (_) {
          // 获取模型失败不影响测试连接结果
        }
      }

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
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _fetchAvailableModels() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先填写必填项')));
      return;
    }

    setState(() => _isLoadingModels = true);

    try {
      final dioClient = DioClient(
        baseUrl: _baseUrlController.text,
        apiKey: _apiKeyController.text,
        proxyUrl: _enableProxy ? _proxyUrlController.text : null,
        proxyUsername: _enableProxy ? _proxyUsernameController.text : null,
        proxyPassword: _enableProxy ? _proxyPasswordController.text : null,
      );
      final apiClient = OpenAIApiClient(dioClient, _selectedProvider);
      final models = await apiClient.getAvailableModels();

      // 保存模型到缓存，以便在聊天中使用
      final modelsRepo = ref.read(modelsRepositoryProvider);
      final tempConfig = ApiConfig(
        id: widget.config?.id ?? 'temp',
        name: _nameController.text,
        provider: _selectedProvider,
        baseUrl: _baseUrlController.text,
        apiKey: _apiKeyController.text,
        defaultModel: '',
        isActive: false,
      );
      final aiModels = models.map((modelId) {
        return AiModel(
          id: modelId,
          name: modelId,
          apiConfigId: tempConfig.id,
          apiConfigName: tempConfig.name,
          description: '',
          contextLength: 4096,
          supportsFunctions: false,
          supportsVision: false,
        );
      }).toList();
      await modelsRepo.cacheModels(aiModels);

      if (mounted) {
        setState(() {
          _availableModels = models;
          // 自动选择模型: 如果当前没有选中模型或不在列表中，选择第一个
          if (models.isNotEmpty &&
              (_selectedModel == null || !models.contains(_selectedModel))) {
            _selectedModel = models.first;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功获取 ${models.length} 个模型，已自动选择: $_selectedModel'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('获取模型失败'),
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
        setState(() => _isLoadingModels = false);
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
      defaultModel: _selectedModel ?? 'gpt-3.5-turbo',
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
