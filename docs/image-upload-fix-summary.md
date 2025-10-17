# 图片上传400错误修复总结

## 问题描述

用户在使用 `deepseek-chat` 模型时上传图片,接口返回 400 错误。

## 根本原因

**DeepSeek 模型不支持图片输入**

从错误日志可以看到:
```
model: deepseek-chat
messages: [{role: user, content: [{type: text, text: 什么}, {type: image_url, ...}]}]
```

DeepSeek 系列模型(deepseek-chat, deepseek-coder, deepseek-reasoner)都是纯文本模型,不支持多模态输入。

## 已实施的修复

### 1. 模型能力检查

创建了 `ModelCapabilities` 工具类来判断模型是否支持图片:

```dart
// lib/core/utils/model_capabilities.dart

支持图片的模型:
- gpt-4o, gpt-4o-mini
- gpt-4-turbo, gpt-4-vision
- claude-3-* 系列
- gemini-1.5, gemini-2.0

不支持图片的模型:
- gpt-3.5-turbo
- gpt-4 (原始版本)
- deepseek-chat, deepseek-coder, deepseek-reasoner
- qwen, baichuan
```

### 2. 请求前验证

在 `ChatRepository` 中添加了图片发送前的检查:

```dart
// 检查模型是否支持图片
if (images != null && images.isNotEmpty) {
  if (!ModelCapabilities.supportsImages(config.model)) {
    return Message(
      hasError: true,
      errorMessage: '模型 ${config.model} 不支持图片输入，'
          '请使用支持多模态的模型(如 gpt-4o、gpt-4-turbo 等)',
    );
  }
}
```

### 3. ResponseBody 解析错误修复

修复了尝试访问 `error.response?.data['error']` 时的 NoSuchMethodError:

```dart
// 安全地提取错误消息
String errorMessage = 'Server error occurred';
try {
  final data = error.response?.data;
  if (data is Map) {
    errorMessage = data['error']?['message'] ?? 
        data['message'] ?? 
        'Server error occurred';
  }
} catch (e) {
  // 忽略解析错误,使用默认消息
}
```

### 4. 详细的诊断日志

添加了 400 错误的详细日志记录:
- 请求 URL 和方法
- 请求头
- 响应数据类型
- 模型信息

### 5. 图片验证工具

创建了 `ImageUploadValidator` 工具:
- 验证图片文件格式和大小
- 检查 base64 编码
- 验证消息结构
- 提供详细的验证报告

## 解决方案

### 方案 1: 切换到支持图片的模型(推荐)

在设置中切换模型:
1. 打开设置 → API 配置
2. 选择或添加支持多模态的模型:
   - **推荐**: `gpt-4o` (最新,性能好,支持图片)
   - 备选: `gpt-4-turbo`, `gpt-4-vision`
   - Claude: `claude-3-opus`, `claude-3-sonnet`

### 方案 2: 移除图片后发送

如果必须使用 DeepSeek:
1. 不要上传图片
2. 使用纯文本描述
3. DeepSeek 在纯文本任务上表现优秀

## 用户提示改进

### 当前行为

✅ 应用现在会:
1. 在发送前检查模型能力
2. 如果模型不支持图片,显示清晰的错误消息
3. 不会发送无效的请求到 API
4. 记录详细的诊断信息

### 错误消息示例

```
模型 deepseek-chat 不支持图片输入，
请使用支持多模态的模型(如 gpt-4o、gpt-4-turbo 等)
```

## 未来改进建议

### 1. UI 层面的预防

在聊天界面显示当前模型的能力:
```dart
if (!ModelCapabilities.supportsImages(currentModel)) {
  // 禁用图片上传按钮
  // 显示提示: "当前模型不支持图片"
}
```

### 2. 智能模型切换

当用户尝试上传图片时:
```dart
if (hasImages && !currentModelSupportsImages) {
  showDialog(
    title: '模型不支持图片',
    content: '当前模型不支持图片输入,是否切换到 gpt-4o?',
    actions: [切换, 取消],
  );
}
```

### 3. 模型能力标签

在模型选择界面显示标签:
- 🖼️ 支持图片
- 📝 仅文本
- 🛠️ 支持工具调用

## 相关文件

- `lib/core/utils/model_capabilities.dart` - 模型能力判断
- `lib/core/utils/image_upload_validator.dart` - 图片验证工具
- `lib/features/chat/data/chat_repository.dart` - 请求前验证
- `lib/core/network/dio_client.dart` - 错误处理改进
- `docs/image-upload-troubleshooting.md` - 详细故障排查指南

## 测试验证

### 测试场景 1: 使用不支持图片的模型

1. 选择 `deepseek-chat` 模型
2. 尝试上传图片
3. **预期结果**: 显示错误消息,不发送请求

### 测试场景 2: 使用支持图片的模型

1. 选择 `gpt-4o` 模型
2. 上传图片
3. **预期结果**: 成功发送并接收响应

### 测试场景 3: 图片验证

1. 上传超大图片 (>10MB)
2. **预期结果**: 显示警告但允许继续

## 常见问题

### Q: 为什么 DeepSeek 不支持图片?
A: DeepSeek 是专注于代码和文本的模型,没有视觉理解能力。它在代码生成和推理方面很强,但不支持多模态输入。

### Q: 如何知道某个模型是否支持图片?
A: 查看 `ModelCapabilities.supportsImages()` 方法,或参考文档中的模型列表。

### Q: 已经发送的带图片的历史消息怎么办?
A: 切换模型后,历史消息中的图片仍然会被包含在请求中。如果新模型不支持图片,需要开始新对话。

### Q: 可以添加新的模型支持吗?
A: 可以,在 `model_capabilities.dart` 中更新 `_multimodalModels` 列表。

## 总结

✅ **修复完成**:
- ResponseBody 解析错误已修复
- 添加了模型能力检查
- 提供了清晰的错误提示
- 增强了诊断日志

✅ **用户体验改善**:
- 明确告知模型不支持图片
- 提供解决方案建议
- 避免无效的 API 请求

✅ **下次遇到 400 错误**:
1. 检查控制台日志
2. 确认模型是否支持图片
3. 参考 `docs/image-upload-troubleshooting.md`
