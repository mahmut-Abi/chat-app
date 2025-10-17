import '../services/log_service.dart';

/// 模型能力判断工具
///
/// 用于判断不同模型是否支持某些特性，如图片、工具调用等
class ModelCapabilities {
  static final _log = LogService();

  /// 支持多模态（图片）的模型列表
  static const List<String> _multimodalModels = [
    // OpenAI
    'gpt-4-vision',
    'gpt-4-turbo',
    'gpt-4o',
    'gpt-4o-mini',
    // Claude
    'claude-3',
    'claude-3-opus',
    'claude-3-sonnet',
    'claude-3-haiku',
    // Gemini
    'gemini-pro-vision',
    'gemini-1.5',
    'gemini-2.0',
  ];

  /// 不支持图片的模型列表
  static const List<String> _textOnlyModels = [
    'gpt-3.5-turbo',
    'gpt-4', // 原始 gpt-4，不支持 vision
    'deepseek-chat',
    'deepseek-coder',
    'deepseek-reasoner',
    'qwen',
    'baichuan',
  ];

  /// 检查模型是否支持图片输入
  ///
  /// [modelId] 模型id
  /// 返回 true 如果支持图片
  static bool supportsImages(String modelId) {
    final lowerModelId = modelId.toLowerCase();

    // 检查是否在明确不支持的列表中
    for (final model in _textOnlyModels) {
      if (lowerModelId.contains(model.toLowerCase())) {
        _log.debug('模型不支持图片', {'modelId': modelId});
        return false;
      }
    }

    // 检查是否在明确支持的列表中
    for (final model in _multimodalModels) {
      if (lowerModelId.contains(model.toLowerCase())) {
        _log.debug('模型支持图片', {'modelId': modelId});
        return true;
      }
    }

    // 默认不支持，但给出警告
    _log.warning('未知模型的图片支持情况', {'modelId': modelId, 'assumption': '假设不支持'});
    return false;
  }

  /// 获取模型能力说明
  static String getCapabilitiesDescription(String modelId) {
    final supportsImg = supportsImages(modelId);
    return supportsImg ? '该模型支持图片输入' : '该模型仅支持文本输入，不支持图片';
  }
}
