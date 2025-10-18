# 项目结构说明

本文档详细说明了 Flutter Chat App 的项目结构、架构设计和代码组织方式。

## 目录

- [整体架构](#整体架构)
- [目录结构详解](#目录结构详解)
- [核心模块 (core)](#核心模块-core)
- [功能模块 (features)](#功能模块-features)
- [共享组件 (shared)](#共享组件-shared)
- [文件命名规范](#文件命名规范)
- [开发指南](#开发指南)

## 整体架构

项目采用 **Feature-First + Clean Architecture** 混合架构：

**架构原则**:
1. **Feature-First**: 按业务功能组织代码，高内聚低耦合
2. **Clean Architecture**: 分层设计 (Presentation → Domain → Data)
3. **状态管理**: Riverpod 2.x + Provider 模式

**技术栈**:
- Flutter 3.0+、Riverpod 2.x、go_router
- dio、shared_preferences、flutter_secure_storage
- freezed、json_serializable
- flutter_markdown、flutter_math_fork

## 目录结构详解

```
chat-app/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── core/                  # 核心功能层
│   ├── features/              # 功能模块层
│   └── shared/                # 共享组件层
├── test/                      # 测试代码
├── assets/                    # 资源文件
├── docs/                      # 项目文档
├── scripts/                   # 构建脚本
└── [platform]/                # 平台代码 (android/ios/macos/web/windows/linux)
```

## 核心模块 (core)

`lib/core/` 包含应用核心基础设施。

### core/constants/
- `app_constants.dart` - 全局常量、API 端点、默认配置

### core/error/
- `error_handler.dart` - 全局错误处理、日志记录

### core/network/
- `api_exception.dart` - API 异常定义
- `dio_client.dart` - Dio HTTP 客户端配置
- `openai_api_client.dart` - OpenAI 兼容 API 客户端

### core/providers/
- `providers.dart` - 全局 Riverpod Provider 定义

### core/routing/
- `app_router.dart` - GoRouter 路由配置

### core/services/
系统级服务：
- `desktop_service.dart` - 桌面平台功能
- `log_service.dart` - 日志服务
- `menu_service.dart` - 应用菜单
- `network_service.dart` - 网络状态监控
- `permission_service.dart` - 权限管理
- `pwa_service.dart` - PWA 支持

### core/storage/
- `storage_service.dart` - 本地存储服务 (SharedPreferences + Secure Storage)

### core/utils/
通用工具类（按类别分组）：

**数据处理**:
- `batch_operations.dart` - 批量操作
- `data_export_import.dart` - 数据导入导出
- `message_utils.dart` - 消息处理

**导出功能**:
- `markdown_export.dart` - Markdown 导出
- `pdf_export.dart` - PDF 导出

**平台适配**:
- `desktop_utils.dart` / `desktop_utils_io.dart` / `desktop_utils_stub.dart` - 桌面工具
- `platform_utils.dart` / `platform_utils_web.dart` - 平台检测

**UI 辅助**:
- `keyboard_utils.dart` - 键盘工具
- `shortcuts.dart` - 快捷键
- `native_menu.dart` - 原生菜单

**业务逻辑**:
- `token_counter.dart` - Token 计数
- `model_capabilities.dart` - 模型能力检测
- `image_upload_validator.dart` - 图片验证
- `image_utils.dart` - 图片处理

**调试工具**:
- `debug_helper.dart` - 调试辅助
- `performance_utils.dart` - 性能监控

## 功能模块 (features)

`lib/features/` 包含所有业务功能模块。

### 标准模块结构

```
features/[feature_name]/
├── data/                      # 数据层
│   └── [feature]_repository.dart
├── domain/                    # 领域层
│   ├── [model].dart
│   └── [model].g.dart         # 生成代码
└── presentation/              # 表现层
    ├── [feature]_screen.dart
    ├── widgets/               # 功能组件
    └── providers/             # 状态管理
```

### features/chat/ - 聊天功能

**核心功能**:
- 对话创建、编辑、删除
- 消息发送和接收（流式响应）
- 对话分组和标签管理
- 消息搜索和筛选
- 图片上传和查看
- 模型参数配置
- 系统提示词设置

**关键文件**:
- `data/chat_repository.dart` - 聊天数据仓库
- `data/message_pagination_manager.dart` - 消息分页
- `domain/conversation.dart` - 对话模型
- `domain/message.dart` - 消息模型
- `presentation/chat_screen.dart` - 聊天页面
- `presentation/home_screen.dart` - 主页面
- `presentation/widgets/modern_sidebar.dart` - 侧边栏

### features/agent/ - Agent 系统

**核心功能**:
- Agent 创建和管理
- 内置工具集成（计算器、搜索、文件操作）
- 5 个预配置内置 Agent（通用助手、数学专家、研究助手、文件管理员、编程助手）
- 工具调用执行
- Agent 与聊天集成

**关键文件**:
- `data/agent_repository.dart` - Agent 数据仓库
- `data/tool_executor.dart` - 工具执行器
- `data/default_agents.dart` - 内置 Agent 配置
- `data/tools/` - 内置工具实现
  - `calculator_tool.dart` - 计算器工具
  - `search_tool.dart` - 搜索工具
  - `file_operation_tool.dart` - 文件操作工具
- `domain/agent_tool.dart` - Agent 工具模型
- `presentation/providers/agent_provider.dart` - Agent Provider

**内置 Agent**:
1. **通用助手** - 计算器 + 搜索，适合日常使用
2. **数学专家** - 计算器，专注数学问题
3. **研究助手** - 搜索 + 文件操作，适合学术研究
4. **文件管理员** - 文件操作，专注文件管理
5. **编程助手** - 文件操作 + 搜索，适合代码开发

### features/mcp/ - MCP 集成

**核心功能**:
- MCP 服务器管理（HTTP/Stdio）
- 工具调用
- 资源访问
- 提示词管理
- 连接状态监控

**关键文件**:
- `data/mcp_client_base.dart` - MCP 客户端基类
- `data/http_mcp_client.dart` - HTTP 客户端
- `data/stdio_mcp_client.dart` - Stdio 客户端
- `data/mcp_client_factory.dart` - 客户端工厂
- `domain/mcp_config.dart` - MCP 配置模型

### features/models/ - 模型管理

**核心功能**:
- 模型列表管理
- 模型参数配置
- 默认模型设置

### features/prompts/ - 提示词模板

**核心功能**:
- 模板创建、编辑、删除
- 分类和标签管理
- 变量占位符支持
- 模板快速使用

### features/settings/ - 设置

**核心功能**:
- API 配置管理
- 主题和外观设置
- 数据导入导出
- 应用信息

**关键文件**:
- `presentation/modern_settings_screen.dart` - 现代化设置页面
- `presentation/mixins/` - 设置混入
- `presentation/widgets/` - 设置组件

### features/token_usage/ - Token 统计

**核心功能**:
- Token 使用记录
- 按会话/模型统计
- 成本分析

### features/logs/ - 日志查看

**核心功能**:
- 日志列表展示
- 日志筛选和导出

## 共享组件 (shared)

`lib/shared/` 包含跨功能模块的共享组件。

### shared/themes/
- `app_theme.dart` - 亮色/暗色主题定义、颜色方案、文字样式

### shared/utils/
- `responsive_utils.dart` - 响应式布局工具

### shared/widgets/

通用 UI 组件：
- `background_container.dart` - 背景容器（支持图片和渐变）
- `glass_container.dart` - 毛玻璃效果容器
- `markdown_message.dart` / `enhanced_markdown_message.dart` - Markdown 渲染
- `platform_dialog.dart` - 跨平台对话框
- `network_status_widget.dart` - 网络状态指示器
- `loading_widget.dart` - 加载指示器
- `message_actions.dart` - 消息操作

## 文件命名规范

### Dart 文件
- **文件名**: `snake_case` (✅ `chat_repository.dart`)
- **类名**: `PascalCase` (✅ `class ChatRepository`)
- **变量/函数**: `camelCase` (✅ `sendMessage()`)
- **常量**: `lowerCamelCase` (✅ `const maxTokens = 4096`)
- **私有成员**: 前缀 `_` (✅ `_apiClient`)

### 测试文件
- 测试文件: `*_test.dart` (✅ `chat_repository_test.dart`)

### 生成文件
- Freezed: `*.freezed.dart`
- JSON Serializable: `*.g.dart`

### 目录命名
- 使用 `snake_case` (✅ `token_usage/`, ❌ `tokenUsage/`)

## 开发指南

### 数据流向

```
用户交互 (UI)
    ↓
Widget 事件处理
    ↓
Provider 状态更新
    ↓
Repository 业务逻辑
    ↓
Data Source (API/Storage)
    ↓
Repository 数据转换
    ↓
Provider 状态通知
    ↓
Widget 重建 (UI 更新)
```

### 新功能开发步骤

#### 1. 规划功能模块
确定是创建新模块还是扩展现有模块。

#### 2. 创建目录结构
```bash
mkdir -p lib/features/new_feature/{data,domain,presentation}
mkdir -p lib/features/new_feature/presentation/{widgets,providers}
```

#### 3. 定义数据模型
```dart
// lib/features/new_feature/domain/my_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_model.freezed.dart';
part 'my_model.g.dart';

@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
  }) = _MyModel;
  
  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

#### 4. 实现 Repository
```dart
// lib/features/new_feature/data/my_repository.dart
class MyRepository {
  final StorageService _storage;
  
  MyRepository(this._storage);
  
  Future<List<MyModel>> getAll() async {
    // 实现逻辑
  }
}
```

#### 5. 创建 Provider
```dart
// lib/features/new_feature/presentation/providers/my_provider.dart
final myRepositoryProvider = Provider<MyRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return MyRepository(storage);
});
```

#### 6. 构建 UI
```dart
// lib/features/new_feature/presentation/my_screen.dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(myRepositoryProvider);
    // 构建界面
  }
}
```

#### 7. 添加路由
```dart
// lib/core/routing/app_router.dart
GoRoute(
  path: '/my-feature',
  builder: (context, state) => const MyScreen(),
)
```

#### 8. 生成代码
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 9. 测试
```bash
flutter test
flutter analyze
```

### 状态管理最佳实践

```dart
// 1. 简单状态 - 使用 Provider
final simpleProvider = Provider<String>((ref) => 'Hello');

// 2. 异步数据 - 使用 FutureProvider
final dataProvider = FutureProvider<List<Item>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getAll();
});

// 3. 流数据 - 使用 StreamProvider
final streamProvider = StreamProvider<int>((ref) {
  return Stream.periodic(Duration(seconds: 1), (i) => i);
});

// 4. 可变状态 - 使用 StateNotifierProvider
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});
```

### 测试结构

```
test/
├── unit/                      # 单元测试
│   └── features/
│       └── chat/
│           └── chat_repository_test.dart
├── widget/                    # Widget 测试
│   └── message_bubble_test.dart
└── integration/               # 集成测试
    └── chat_flow_test.dart
```

### 资源文件组织

```
assets/
├── backgrounds/               # 背景图片
│   ├── gradient_1.jpg
│   └── ...
├── icons/                     # 应用图标
│   └── app_icon.svg
└── images/                    # 其他图片资源
```

## 相关文档

- [AGENTS.md](../AGENTS.md) - 开发规范和贡献指南
- [README.md](../README.md) - 项目概览和快速开始
- [docs/architecture.md](architecture.md) - 架构详细说明
- [docs/api.md](api.md) - API 文档
- [docs/mcp-integration.md](mcp-integration.md) - MCP 集成指南
- [docs/agent-functionality-verification.md](agent-functionality-verification.md) - Agent 功能验证
- [docs/built-in-agents.md](built-in-agents.md) - 内置 Agent 说明
- [docs/agent-development.md](agent-development.md) - Agent 开发指南
