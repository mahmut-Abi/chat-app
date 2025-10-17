import 'lib/core/utils/model_capabilities.dart';

void main() {
  print('测试模型能力检查:');
  print('deepseek-chat: ${ModelCapabilities.supportsImages('deepseek-chat')}');
  print('gpt-4o: ${ModelCapabilities.supportsImages('gpt-4o')}');
  print('gpt-3.5-turbo: ${ModelCapabilities.supportsImages('gpt-3.5-turbo')}');
}
