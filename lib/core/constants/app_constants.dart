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
    'Ollama',
    'Custom',
  ];
}

class ApiProviders {
  static const String openai = 'OpenAI';
  static const String azure = 'Azure OpenAI';
  static const String ollama = 'Ollama';
  static const String custom = 'Custom';
}
