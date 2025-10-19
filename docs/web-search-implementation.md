# 大模型网络搜索实现指南

## 概述

在 AI 应用中，网络搜索功能有两种实现方式：

1. **Agent Tool 方式**：应用层实现，AI 通过 Agent 工具调用搜索 API
2. **原生 API 方式**：模型层实现，DeepSeek 等模型内置的网络搜索能力

## 两种方式的区别

### 方式一：Agent Tool（当前项目已实现）

**工作流程**：
```
用户 → AI 模型 → 判断需要搜索 → 调用 Agent Tool → 搜索 API → 返回结果 → AI 整合回答
```

**特点**：
- ✅ 完全可控：你决定何时搜索、使用什么搜索 API
- ✅ 灵活扩展：可以集成任何搜索服务（Google、Bing、DuckDuckGo 等）
- ✅ 成本透明：搜索 API 调用次数和费用清晰可见
- ✅ 自定义处理：可以对搜索结果进行预处理、过滤
- ❌ 需要开发：要自己实现搜索工具和 API 集成
- ❌ Token 消耗多：搜索结果要作为上下文传给 AI

**当前实现位置**：
- `lib/features/agent/data/tools/search_tool.dart` - 搜索工具实现
- `lib/features/agent/domain/agent_tool.dart` - 工具定义

### 方式二：原生 API（DeepSeek 等模型支持）

**工作流程**：
```
用户 → AI 模型（内部搜索） → 直接返回整合结果
```

**特点**：
- ✅ 开箱即用：无需额外开发
- ✅ Token 优化：模型内部处理，不占用上下文
- ✅ 响应更快：减少了中间调用环节
- ✅ 更智能：模型知道何时需要搜索
- ❌ 黑盒操作：不知道何时搜索、搜索了什么
- ❌ 成本不透明：搜索费用包含在 API 调用中
- ❌ 依赖模型：只有支持的模型才能用
- ❌ 无法定制：不能选择搜索源或过滤结果

**支持的模型**：
- DeepSeek V3
- OpenAI GPT-4 with browsing
- Claude with web search (部分)
- Google Gemini with search

## DeepSeek 网络搜索的使用

### API 参数配置

DeepSeek 的网络搜索是通过特殊的 API 参数启用的：

```dart
// 在发送请求时添加以下参数
final requestBody = {
  'model': 'deepseek-chat',  // 或 'deepseek-reasoner'
  'messages': messages,
  'web_search': true,  // ⭐ 启用网络搜索
  'stream': true,
};
```

## 总结

| 维度 | Agent Tool | 原生 API |
|------|-----------|----------|
| **实现难度** | 中等 | 简单 |
| **灵活性** | 高 | 低 |
| **响应速度** | 较慢 | 快 |
| **成本控制** | 精确 | 模糊 |
| **模型依赖** | 无 | 强 |
| **Token 消耗** | 高 | 低 |
| **推荐场景** | 企业/定制 | 个人/快速 |

**建议**：
- 🚀 如果你现在想快速体验 DeepSeek 网络搜索，实现原生 API 方式
- 🛠️ 如果你需要灵活性和可控性，继续使用和完善 Agent Tool
- 🎯 最佳方案：同时支持两种方式，让用户选择
