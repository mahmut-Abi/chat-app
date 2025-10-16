import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/model.dart';
import '../../settings/domain/api_config.dart';
import '../../../core/providers/providers.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/background_container.dart';

class ModelsScreen extends ConsumerStatefulWidget {
  const ModelsScreen({super.key});

  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  List<AiModel> _models = [];
  List<ApiConfig> _apiConfigs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 首先加载 API 配置
      final settingsRepo = ref.read(settingsRepositoryProvider);
      _apiConfigs = await settingsRepo.getAllApiConfigs();

      // 检查是否有配置完整的 API
      final validConfigs = _apiConfigs
          .where(
            (config) => config.baseUrl.isNotEmpty && config.apiKey.isNotEmpty,
          )
          .toList();

      if (validConfigs.isEmpty) {
        setState(() {
          _models = [];
          _isLoading = false;
          _errorMessage = '没有可用的 API 配置\n请先在设置中添加 API 配置';
        });
        return;
      }

      // 加载模型列表
      final modelsRepo = ref.read(modelsRepositoryProvider);
      final models = await modelsRepo.getAvailableModels(validConfigs);

      if (mounted) {
        setState(() {
          _models = models;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载模型失败：${e.toString()}';
        });
      }
    }
  }

  /// 按 API 配置分组模型
  Map<String, List<AiModel>> _groupModelsByApiConfig() {
    final grouped = <String, List<AiModel>>{};
    for (final model in _models) {
      grouped.putIfAbsent(model.apiConfigName, () => []).add(model);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('模型管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadModels,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'API 设置',
          ),
        ],
      ),
      body: BackgroundContainer(child: _buildBody(colorScheme)),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载中...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings),
                label: const Text('去设置'),
              ),
            ],
          ),
        ),
      );
    }

    if (_models.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text('没有找到模型', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '请检查 API 配置是否正确',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadModels,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final groupedModels = _groupModelsByApiConfig();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedModels.length,
      itemBuilder: (context, index) {
        final apiName = groupedModels.keys.elementAt(index);
        final models = groupedModels[apiName]!;
        return _buildApiGroup(apiName, models, colorScheme);
      },
    );
  }

  Widget _buildApiGroup(
    String apiName,
    List<AiModel> models,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.api,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      apiName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${models.length} 个模型',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...models.map((model) => _buildModelCard(model, colorScheme)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildModelCard(AiModel model, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (model.description != null)
                        Text(
                          model.description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (model.contextLength != null ||
                model.supportsFunctions ||
                model.supportsVision) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (model.contextLength != null)
                    _buildChip(
                      Icons.text_fields,
                      'Context: ${(model.contextLength! / 1000).toStringAsFixed(0)}K',
                      colorScheme,
                    ),
                  if (model.supportsFunctions)
                    _buildChip(Icons.functions, 'Functions', colorScheme),
                  if (model.supportsVision)
                    _buildChip(Icons.image, 'Vision', colorScheme),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, ColorScheme colorScheme) {
    return Chip(
      avatar: Icon(icon, size: 14, color: colorScheme.primary),
      label: Text(
        label,
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
      ),
      backgroundColor: colorScheme.surfaceContainerHighest,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
