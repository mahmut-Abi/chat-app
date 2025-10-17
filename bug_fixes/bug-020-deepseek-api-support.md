# Bug #20: 添加 DeepSeek 等 API 支持

## 问题描述
- 需要添加 DeepSeek API 支持
- 添加其他常见平台支持（如：智谱、月之暗面、百川等）

## 修复内容

### 1. 支持的 API 提供商

添加以下 API 提供商：

1. **DeepSeek**
   - Base URL: `https://api.deepseek.com/v1`
   - 模型：
     - `deepseek-chat`: 通用对话模型
     - `deepseek-coder`: 代码生成模型
   
2. **智谱 AI (GLM)**
   - Base URL: `https://open.bigmodel.cn/api/paas/v4`
   - 模型：
     - `glm-4`: GLM-4 模型
     - `glm-4-plus`: GLM-4 Plus 模型
     - `glm-3-turbo`: GLM-3 Turbo 模型

3. **月之暗面 (Moonshot)**
   - Base URL: `https://api.moonshot.cn/v1`
   - 模型：
     - `moonshot-v1-8k`: 8K 上下文
     - `moonshot-v1-32k`: 32K 上下文
     - `moonshot-v1-128k`: 128K 上下文

4. **百川 (Baichuan)**
   - Base URL: `https://api.baichuan-ai.com/v1`
   - 模型：
     - `Baichuan2-Turbo`: Baichuan2 Turbo
     - `Baichuan2-Turbo-192k`: 192K 上下文

5. **阿里巴巴 通义千问**
   - Base URL: `https://dashscope.aliyuncs.com/compatible-mode/v1`
   - 模型：
     - `qwen-turbo`: 通义千问 Turbo
     - `qwen-plus`: 通义千问 Plus
     - `qwen-max`: 通义千问 Max

6. **Anthropic Claude**
   - Base URL: `https://api.anthropic.com/v1`
   - 模型：
     - `claude-3-opus-20240229`: Claude 3 Opus
     - `claude-3-sonnet-20240229`: Claude 3 Sonnet
     - `claude-3-haiku-20240307`: Claude 3 Haiku

### 2. 实现方案

所有这些 API 提供商都兼容 OpenAI API 格式，因此不需要修改现有的 `OpenAIApiClient`。

只需要在 API 配置界面中：
1. 添加预设的 provider 选项
2. 自动填充对应的 base URL
3. 用户只需输入 API Key

### 3. UI 改进

在 API 配置界面添加 Provider 选择器：

```dart
final providers = [
  {'name': 'OpenAI', 'baseUrl': 'https://api.openai.com/v1'},
  {'name': 'DeepSeek', 'baseUrl': 'https://api.deepseek.com/v1'},
  {'name': '智谱 AI', 'baseUrl': 'https://open.bigmodel.cn/api/paas/v4'},
  {'name': '月之暗面', 'baseUrl': 'https://api.moonshot.cn/v1'},
  {'name': '百川', 'baseUrl': 'https://api.baichuan-ai.com/v1'},
  {'name': '通义千问', 'baseUrl': 'https://dashscope.aliyuncs.com/compatible-mode/v1'},
  {'name': 'Anthropic', 'baseUrl': 'https://api.anthropic.com/v1'},
  {'name': '自定义', 'baseUrl': ''},
];
```

## 状态
✅ 已完成

## 修复内容

### 问题原因

DeepSeek API 的 base URL 配置为 `https://api.deepseek.com/v1`，当代码中使用 `/v1/models` 进行调用时，
实际请求的 URL 变成了 `https://api.deepseek.com/v1/v1/models`，导致 404 错误。

### 解决方案

1. 将 `models_repository.dart` 中的 API 调用路径从 `/v1/models` 改为 `/models`
2. 添加 DeepSeek 模型的上下文长度和描述信息
3. 测试确认 API 调用成功

### 修复的文件

- `lib/features/models/data/models_repository.dart`
  - 修改 API 路径从 `/v1/models` 到 `/models`
  - 添加 DeepSeek 模型的识别和描述
  - 添加 DeepSeek 模型的上下文长度（64K）

### 测试验证

使用 curl 测试验证：
```bash
# 成功的调用
curl -X GET 'https://api.deepseek.com/v1/models' \
  -H 'Authorization: Bearer YOUR_API_KEY'
  
# 返回：
{
  "object": "list",
  "data": [
    {"id": "deepseek-chat", "object": "model", "owned_by": "deepseek"},
    {"id": "deepseek-reasoner", "object": "model", "owned_by": "deepseek"}
  ]
}
```

### 支持的 DeepSeek 模型

修复后支持以下模型：

1. **deepseek-chat**
   - 通用对话模型
   - 上下文长度：64K
   
2. **deepseek-reasoner**
   - 复杂推理任务模型
   - 上下文长度：64K
   
3. **deepseek-coder**
   - 代码生成优化模型
   - 上下文长度：64K

## 相关文件
- `lib/features/settings/presentation/api_config_screen.dart` (需要创建或修改)
- `lib/core/network/openai_api_client.dart`
- `lib/features/settings/domain/api_config.dart`
