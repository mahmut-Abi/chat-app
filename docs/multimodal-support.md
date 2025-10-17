# 多模态内容支持文档

## 概述

本文档描述了聊天应用中图片和文件上传功能的实现细节，以及对 OpenAI Vision API 格式的支持。

## 功能特性

### 1. 图片上传支持

- **支持格式**: JPEG、PNG、GIF、WebP
- **API 格式**: OpenAI Vision API (GPT-4 Vision)
- **传输方式**: Base64 编码的 Data URL

### 2. 文件上传支持

- **当前状态**: UI 层已实现文件选择
- **限制**: 标准 OpenAI API 不直接支持文件上传
- **未来计划**: 可通过文本提取或 Assistant API 实现

## 实现细节

### 消息格式

#### 纯文本消息
```json
{
  "role": "user",
  "content": "这是一条文本消息"
}
```

#### 多模态消息（文本 + 图片）
```json
{
  "role": "user",
  "content": [
    {
      "type": "text",
      "text": "请描述这张图片"
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

### 代码结构

#### 数据模型
- `ImageAttachment`: 包含图片路径、base64 数据和 MIME 类型
- `Message`: 包含文本内容和可选的图片附件列表

#### 消息构建
`_buildMessageList` 方法负责将消息转换为 OpenAI API 格式：
- 检测消息是否包含图片
- 如果包含图片，构建多模态 content 数组
- 否则使用简单的字符串格式

## API 兼容性

### OpenAI 官方 API
- ✅ 支持图片上传（GPT-4 Vision）
- ❌ 不支持直接文件上传
- 💡 可使用 Assistant API 处理文件

### 其他 API 提供商
- DeepSeek: 部分模型支持多模态
- 自定义 API: 需确认是否兼容 OpenAI Vision API 格式

## 使用示例

1. 用户点击图片按钮选择图片
2. 图片显示在输入框上方的预览区域
3. 输入文本消息（可选）
4. 点击发送按钮
5. 系统将图片转换为 base64 并发送

## 性能考虑

- OpenAI API 对图片大小有限制（通常为 20MB）
- Base64 编码会增加约 33% 的数据大小
- 建议限制同时上传的图片数量
- 发送后立即清空选择列表释放内存

## 未来改进

### 文件上传
1. **文本文件**: 读取内容并作为文本发送
2. **PDF 文件**: 提取文本内容
3. **Office 文档**: 使用 Assistant API 或转换为文本

### 优化
1. **图片压缩**: 自动压缩大于 1MB 的图片
2. **缓存机制**: 缓存已转换的 base64 数据
3. **批量上传**: 支持拖拽批量上传
