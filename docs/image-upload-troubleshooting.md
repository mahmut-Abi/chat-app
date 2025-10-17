# 图片上传问题诊断指南

## 问题现象

当上传图片后,接口返回 400 错误。

## 可能的原因

### 1. 模型不支持多模态输入

**症状**: 日志中显示 "模型不支持图片输入"

**原因**: 不是所有模型都支持图片输入。例如:
- ❌ 不支持: `gpt-3.5-turbo`, `gpt-4`, `deepseek-chat`, `deepseek-coder`
- ✅ 支持: `gpt-4o`, `gpt-4-turbo`, `gpt-4-vision`, `claude-3-*`, `gemini-*`

**解决方法**:
1. 在聊天设置中切换到支持多模态的模型
2. 推荐使用 `gpt-4o` 或 `gpt-4-turbo`

### 2. 图片文件过大

**症状**: 
- 日志中显示 "Base64 数据过大"
- 请求超时
- 400 错误,错误消息提到 token limit

**原因**: 
- 图片文件 > 5MB 可能导致 base64 编码后数据过大
- base64 编码会增加约 33% 的数据量
- OpenAI API 对单个请求的大小有限制(通常 ~20MB)

**解决方法**:
1. 压缩图片:
   ```bash
   # macOS
   sips -Z 1920 input.jpg --out output.jpg
   
   # 使用在线工具
   # TinyPNG, Squoosh, etc.
   ```
2. 降低图片分辨率
3. 转换为更高效的格式(WebP, JPEG)

### 3. 图片格式不受支持

**症状**: 日志中显示 "不是支持的图片格式"

**支持的格式**:
- ✅ JPEG (.jpg, .jpeg)
- ✅ PNG (.png)
- ✅ GIF (.gif)
- ✅ WebP (.webp)
- ❌ HEIC, TIFF, BMP (不直接支持)

**解决方法**:
```bash
# 转换为JPEG
convert input.heic output.jpg
```

### 4. Base64 编码错误

**症状**: 
- 日志中显示 "Base64 编码失败"
- 400 错误,提到 invalid base64

**可能原因**:
- 文件损坏
- 编码过程中内存不足
- 特殊字符处理问题

**解决方法**:
1. 尝试重新保存图片
2. 使用标准图片编辑器重新导出
3. 检查文件权限

### 5. 消息结构错误

**症状**: 400 错误,API 返回 "invalid message format"

**正确的消息结构**:
```dart
{
  "role": "user",
  "content": [
    {
      "type": "text",
      "text": "描述图片"
    },
    {
      "type": "image_url",
      "image_url": {
        "url": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
      }
    }
  ]
}
```

## 使用诊断工具

### 1. 图片验证

在上传图片前,可以使用验证工具检查:

```dart
import 'package:chat_app/core/utils/image_upload_validator.dart';

final validation = await ImageUploadValidator.validateImage(imageFile);
ImageUploadValidator.printReport(validation);

if (!validation.isValid) {
  print('图片验证失败: ${validation.summary}');
}
```

### 2. 消息内容验证

```dart
final content = [
  {'type': 'text', 'text': 'Hello'},
  {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,...'}},
];

final validation = ImageUploadValidator.validateMessageContent(content);
ImageUploadValidator.printReport(validation);
```

### 3. 查看详细日志

应用已配置详细的日志记录。当发生 400 错误时,检查控制台输出:

```
=== 图片上传验证报告 ===
文件存在: OK
图片格式有效: OK
文件大小: 2048.50 KB
MIME 类型: image/jpeg
Base64 编码成功: OK
Base64 长度: 2796544 字符
Data URL 构建成功: OK

总体状态: 有效
===========================
```

## 调试步骤

1. **检查模型是否支持图片**
   - 查看日志中的模型名称
   - 确认是否在支持列表中

2. **检查图片大小**
   ```bash
   ls -lh image.jpg
   ```
   - 如果 > 5MB,建议压缩

3. **验证图片文件**
   ```bash
   file image.jpg
   # 应输出: image.jpg: JPEG image data...
   ```

4. **查看完整的API响应**
   - 启用 debug 模式
   - 检查 `400 Bad Request 详细信息` 日志

5. **测试简化场景**
   - 尝试只发送图片,不带文本
   - 尝试只发送文本,不带图片
   - 尝试使用更小的图片

## 常见错误消息

### "invalid_request_error: model does not support images"

→ 模型不支持图片,请切换到支持多模态的模型

### "invalid_request_error: image too large"

→ 图片过大,请压缩后重试

### "invalid_request_error: invalid base64"

→ Base64 编码有问题,尝试重新保存图片

### "rate_limit_error"

→ API 频率限制,请等待几秒后重试

## 最佳实践

1. **图片优化**
   - 上传前压缩图片
   - 推荐分辨率: 1920x1080 或更低
   - 推荐格式: JPEG (质量 80-90%)

2. **模型选择**
   - 优先使用 `gpt-4o` (性能好,支持图片)
   - 备选: `gpt-4-turbo`, `claude-3-sonnet`

3. **错误处理**
   - 捕获 400 错误并给用户友好提示
   - 提供重试机制
   - 记录详细日志以便排查

4. **用户提示**
   - 在界面上显示当前模型是否支持图片
   - 限制图片大小和数量
   - 提供图片压缩选项

## 相关代码位置

- 图片验证工具: `lib/core/utils/image_upload_validator.dart`
- 模型能力判断: `lib/core/utils/model_capabilities.dart`
- 消息构建逻辑: `lib/features/chat/data/chat_repository.dart`
- API 错误处理: `lib/core/network/dio_client.dart`
- 详细错误日志: `lib/core/network/openai_api_client.dart`

## 联系支持

如果问题仍然存在:
1. 收集完整的日志输出
2. 记录使用的模型名称
3. 提供图片的基本信息(大小、格式、分辨率)
4. 记录完整的错误消息
