import '../domain/model.dart';
import '../../../core/network/openai_api_client.dart';
import '../../../core/services/log_service.dart';

class ModelsRepository {
  final OpenAIApiClient _apiClient;
  final _log = LogService();

  ModelsRepository(this._apiClient);

  Future<List<AiModel>> getAvailableModels() async {
    try {
      _log.info('获取可用模型列表');
      final modelIds = await _apiClient.getAvailableModels();
      _log.info('获取到 ${modelIds.length} 个模型');
      return modelIds.map((id) => _createModelFromId(id)).toList();
    } catch (e) {
      _log.error('获取模型列表失败', e);
      return _getDefaultModels();
    }
  }

  AiModel _createModelFromId(String id) {
    final contextLength = _getContextLength(id);
    final supportsFunctions =
        id.contains('gpt-4') || id.contains('gpt-3.5-turbo');
    final supportsVision =
        id.contains('vision') || id == 'gpt-4-turbo' || id == 'gpt-4o';

    return AiModel(
      id: id,
      name: id,
      description: _getModelDescription(id),
      contextLength: contextLength,
      supportsFunctions: supportsFunctions,
      supportsVision: supportsVision,
    );
  }

  int _getContextLength(String modelId) {
    if (modelId.contains('16k')) return 16384;
    if (modelId.contains('32k')) return 32768;
    if (modelId.contains('gpt-4-turbo')) return 128000;
    if (modelId.contains('gpt-4o')) return 128000;
    if (modelId.contains('gpt-4')) return 8192;
    if (modelId.contains('gpt-3.5-turbo')) return 4096;
    return 4096;
  }

  String _getModelDescription(String modelId) {
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
    return 'OpenAI model';
  }

  List<AiModel> _getDefaultModels() {
    return [
      const AiModel(
        id: 'gpt-4-turbo-preview',
        name: 'GPT-4 Turbo',
        description: 'Most capable model with 128K context',
        contextLength: 128000,
        supportsFunctions: true,
        supportsVision: true,
      ),
      const AiModel(
        id: 'gpt-4',
        name: 'GPT-4',
        description: 'Advanced reasoning model',
        contextLength: 8192,
        supportsFunctions: true,
        supportsVision: false,
      ),
      const AiModel(
        id: 'gpt-3.5-turbo',
        name: 'GPT-3.5 Turbo',
        description: 'Fast and efficient model',
        contextLength: 4096,
        supportsFunctions: true,
        supportsVision: false,
      ),
      const AiModel(
        id: 'gpt-3.5-turbo-16k',
        name: 'GPT-3.5 Turbo 16K',
        description: 'Extended context GPT-3.5',
        contextLength: 16384,
        supportsFunctions: true,
        supportsVision: false,
      ),
    ];
  }
}
