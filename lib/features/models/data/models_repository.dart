import '../domain/model.dart';
import '../../settings/domain/api_config.dart';
import '../../../core/network/openai_api_client.dart';
import '../../../core/services/log_service.dart';
import '../../../core/storage/storage_service.dart';
import 'package:dio/dio.dart';

class ModelsRepository {
  final _log = LogService();
  final StorageService _storage;

  ModelsRepository(OpenAIApiClient apiClient, this._storage);

  /// 从本地存储加载模型列表
  Future<List<AiModel>> getCachedModels() async {
    try {
      _log.info('从缓存加载模型列表');
      final modelsData = _storage.getAllModels();
      final models = modelsData.map((data) => AiModel.fromJson(data)).toList();
      _log.info('缓存加载成功', {'count': models.length});
      return models;
    } catch (e, stack) {
      _log.error('缓存加载失败', e, stack);
      return [];
    }
  }

  /// 保存模型列表到本地存储
  Future<void> cacheModels(List<AiModel> models) async {
    try {
      _log.info('缓存模型列表', {'count': models.length});
      final modelsData = models.map((model) => model.toJson()).toList();
      await _storage.saveAllModels(modelsData);
      _log.info('模型缓存成功');
    } catch (e, stack) {
      _log.error('模型缓存失败', e, stack);
    }
  }

  /// 刷新所有 API 配置的模型列表，并持久化
  Future<List<AiModel>> refreshModels(List<ApiConfig> apiConfigs) async {
    _log.info('开始刷新模型列表', {'apiCount': apiConfigs.length});

    final allModels = await getAvailableModels(apiConfigs);

    await cacheModels(allModels);

    return allModels;
  }

  /// 根据 API 配置获取模型列表
  Future<List<AiModel>> getModelsForApiConfig(ApiConfig config) async {
    try {
      _log.info('开始获取 API 配置的模型列表', {'apiName': config.name});

      // 使用该 API 配置创建临时客户端
      final dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl,
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            if (config.organization != null)
              'OpenAI-Organization': config.organization!,
          },
        ),
      );

      // 调用 /models 接口
      final response = await dio.get('/models');
      final data = response.data as Map<String, dynamic>;
      final modelsList = data['data'] as List;

      final modelIds = modelsList.map((m) => m['id'] as String).toList();

      _log.info('成功获取模型列表', {'apiName': config.name, 'count': modelIds.length});

      return modelIds.map((id) => _createModelFromId(id, config)).toList();
    } catch (e, stack) {
      _log.error('获取模型列表失败', e, stack);
      rethrow;
    }
  }

  /// 获取所有 API 配置的模型列表
  Future<List<AiModel>> getAvailableModels(List<ApiConfig> apiConfigs) async {
    final allModels = <AiModel>[];


    for (final config in apiConfigs) {
      // 跳过未配置完整的 API
      if (config.baseUrl.isEmpty || config.apiKey.isEmpty) {
        _log.debug('跳过未配置完整的 API', {'apiName': config.name});

        continue;
      }

      try {

        final models = await getModelsForApiConfig(config);

        allModels.addAll(models);
      } catch (e) {

        _log.warning('获取 API 模型失败，继续处理', {
          'apiName': config.name,
          'error': e.toString(),
        });
        // 继续处理其他 API 配置
      }
    }

    return allModels;
  }

  AiModel _createModelFromId(String id, ApiConfig config) {
    final contextLength = _getContextLength(id);
    final supportsFunctions =
        id.contains('gpt-4') || id.contains('gpt-3.5-turbo');
    final supportsVision =
        id.contains('vision') || id == 'gpt-4-turbo' || id == 'gpt-4o';

    return AiModel(
      id: id,
      name: id,
      apiConfigId: config.id,
      apiConfigName: config.name,
      description: _getModelDescription(id),
      contextLength: contextLength,
      supportsFunctions: supportsFunctions,
      supportsVision: supportsVision,
    );
  }

  int _getContextLength(String modelId) {
    // DeepSeek models
    if (modelId.contains('deepseek-chat')) return 64000;
    if (modelId.contains('deepseek-reasoner')) return 64000;
    if (modelId.contains('deepseek-coder')) return 64000;

    // GPT models
    if (modelId.contains('16k')) return 16384;
    if (modelId.contains('32k')) return 32768;
    if (modelId.contains('gpt-4-turbo')) return 128000;
    if (modelId.contains('gpt-4o')) return 128000;
    if (modelId.contains('gpt-4')) return 8192;
    if (modelId.contains('gpt-3.5-turbo')) return 4096;
    return 4096;
  }

  String _getModelDescription(String modelId) {
    // DeepSeek models
    if (modelId.contains('deepseek-chat')) {
      return 'DeepSeek Chat model with 64K context';
    }
    if (modelId.contains('deepseek-reasoner')) {
      return 'DeepSeek Reasoner model for complex reasoning tasks';
    }
    if (modelId.contains('deepseek-coder')) {
      return 'DeepSeek Coder model optimized for programming';
    }

    // GPT models
    if (modelId.contains('gpt-4-turbo')) {
      return 'GPT-4 Turbo with improved performance and 128K context';
    }
    if (modelId.contains('gpt-4o')) {
      return 'Latest GPT-4o model with multimodal capabilities';
    }
    if (modelId.contains('gpt-4')) {
      return 'GPT-4 model with advanced reasoning';
    }
    if (modelId.contains('gpt-3.5-turbo')) {
      return 'Fast and efficient GPT-3.5 model';
    }
    return 'AI model';
  }
}
