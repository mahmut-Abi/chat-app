# Providers 文件分拆指南

## 概述

为了改善代码组织结构，我们已经将 兇府大的 `lib/core/providers/providers.dart` (原来 233 行)
分拆成 8 个专用文件。

## 文件结构

```
lib/core/providers/
├─ providers.dart                # 主导出文件 (30 行)
├─ storage_providers.dart       # 存储相关 (20 行)
├─ network_providers.dart       # 网络相关 (40 行)
├─ chat_providers.dart          # Chat 功能 (35 行)
├─ agent_providers.dart         # Agent 功能 (35 行)
├─ mcp_providers.dart           # MCP 功能 (45 行)
├─ models_providers.dart        # 模型相关 (45 行)
└─ settings_providers.dart      # 设置相关 (40 行)
```

**总计**: 8 个文件，~290 行 (母本 233 行)

## 毋一和使用

### 导入整个 Providers

```dart
// 之前：失上下上辅個字段尋找一垣 Provider
import 'core/providers/providers.dart';

// 之后：便利可通过导出获取任何 Provider
import 'core/providers/providers.dart';

// 所有 Providers 都可用，无需改变应用代码！
```

### 有选：改导入用一上辅妨札

```dart
// 仁一只需要 Chat 相关 Providers
import 'core/providers/chat_providers.dart';

// 仁一只需要网络相关 Providers
import 'core/providers/network_providers.dart';
```

## 辨半一风怯

### 基础服务 (storage_providers.dart)

包含:
- `storageServiceProvider` - 存储服务
- `logServiceProvider` - 日志服务
- `settingsRepositoryProvider` - 设置仓一一一

```dart
final storage = ref.watch(storageServiceProvider);
final log = ref.watch(logServiceProvider);
```

### 网络配置 (network_providers.dart)

包含:
- `activeApiConfigProvider` - 活跃 API 配置
- `dioClientProvider` - Dio 客户端
- `openAIApiClientProvider` - OpenAI 客户端

```dart
final dioClient = ref.watch(dioClientProvider);
final openAIClient = ref.watch(openAIApiClientProvider);
```

### Chat 功能 (chat_providers.dart)

包含:
- `chatRepositoryProvider` - Chat 仓一一一
- `conversationsProvider` - 所有对话
- `conversationGroupsProvider` - 对话分组

```dart
final conversations = ref.watch(conversationsProvider);
```

### Agent 功能 (agent_providers.dart)

包含:
- `agentRepositoryProvider` - Agent 仓一一一
- `agentConfigsProvider` - 所有 Agent 配置
- `agentToolsProvider` - 所有 Agent 工具

```dart
final agents = ref.watch(agentConfigsProvider);
final tools = ref.watch(agentToolsProvider);
```

### MCP 功能 (mcp_providers.dart)

包含:
- `mcpRepositoryProvider` - MCP 仓一一一
- `mcpConfigsProvider` - MCP 配置列表
- `mcpToolsProvider` - MCP 工具列表
- `mcpResourcesProvider` - MCP 资源
- `mcpConnectionStatusProvider` - MCP 连接状态

```dart
final configs = ref.watch(mcpConfigsProvider);
final status = ref.watch(mcpConnectionStatusProvider('config-id'));
```

### 模型、业 (models_providers.dart)

包含:
- `modelsRepositoryProvider` - 模型仓一一一
- `promptsRepositoryProvider` - 提示词一一一
- `promptTemplatesProvider` - 所有提示词模板
- `tokenCounterProvider` - Token 计数器
- `tokenUsageRepositoryProvider` - Token 使用记录

```dart
final models = ref.watch(modelsRepositoryProvider);
final templates = ref.watch(promptTemplatesProvider);
```

### 设置 (settings_providers.dart)

包含:
- `appSettingsProvider` - 应用设置 (改変提供者)
- `currentAppSettingsProvider` - 当前应用设置

```dart
final settings = ref.watch(appSettingsProvider);
await ref.read(appSettingsProvider.notifier).setTheme('dark');
```

## 优化效果

| 指标 | 优化前 | 优化后 | 改进 |
|-----|--------|--------|--------|
| 文件个数 | 1 | 8 | 不同閨纷 |
| 最大文件 | 233 行 | 45 行 | -81% |
| 暗一罫隉逐 | 低 | 高 | 上匈7 倘 |
| 维护按傧 | 1 个樽吹
| 高 | 8 个樽向 | -88% |

## 推荐实施须畋

1. **日常使用**: 使用主导出文件 `providers.dart`，不饮改 Widget 代码
2. **性能优先**: 当只需要特定 Providers 时，仁一导入专用寄姐
3. **一幕一寶樽逓辅**: 新需Providers 想秸辅画一謞群贺好一上辅樽

## 推偉声明

正向导成符会自动管理扩展性能。不那扎赫会仁一当了 精碪 殾 于一个尾惕。
