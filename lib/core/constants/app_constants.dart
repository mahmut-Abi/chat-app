class AppConstants {
  // API
  static const String defaultApiUrl = 'https://api.openai.com/v1';
  static const int defaultTimeout = 30000;
  static const int streamTimeout = 120000;

  // Storage Keys
  static const String apiConfigKey = 'api_config';
  static const String conversationsKey = 'conversations';
  static const String settingsKey = 'settings';
  static const String themeKey = 'theme_mode';

  // Limits
  static const int maxMessageLength = 10000;
  static const int maxConversationHistory = 100;

  // Default Model Parameters
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 2048;
  static const double defaultTopP = 1.0;
  static const double defaultFrequencyPenalty = 0.0;
  static const double defaultPresencePenalty = 0.0;

  // Supported API Providers
  static const List<String> supportedProviders = [
    'OpenAI',
    'Azure OpenAI',
    'DeepSeek',
    '智谱 AI (GLM)',
    '月之暗面 (Moonshot)',
    '百川智能 (Baichuan)',
    '阿里云 (Qwen)',
    '讯飞星火 (Spark)',
    'Ollama',
    'Custom',
  ];
}

class ApiProviders {
  static const String openai = 'OpenAI';
  static const String azure = 'Azure OpenAI';
  static const String deepseek = 'DeepSeek';
  static const String zhipu = '智谱 AI (GLM)';
  static const String moonshot = '月之暗面 (Moonshot)';
  static const String baichuan = '百川智能 (Baichuan)';
  static const String qwen = '阿里云 (Qwen)';
  static const String spark = '讯飞星火 (Spark)';
  static const String ollama = 'Ollama';
  static const String custom = 'Custom';

  // API Base URLs
  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1';
  static const String zhipuBaseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  static const String moonshotBaseUrl = 'https://api.moonshot.cn/v1';
  static const String baichuanBaseUrl = 'https://api.baichuan-ai.com/v1';
  static const String qwenBaseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1';
  static const String sparkBaseUrl = 'https://spark-api.xf-yun.com/v1';
}
