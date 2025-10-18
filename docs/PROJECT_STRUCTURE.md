# 项目结构说明

本文档详细说明 Flutter Chat App 的项目结构和组织方式。

## 📁 目录结构

```
chat-app/
├── lib/                          # 主要源代码目录
│   ├── main.dart                 # 应用入口
│   ├── core/                     # 核心功能模块
│   │   ├── constants/           # 常量定义
│   │   ├── error/               # 错误处理
│   │   ├── network/             # 网络层
│   │   ├── providers/           # 全局 Providers
│   │   ├── routing/             # 路由配置
│   │   ├── services/            # 核心服务
│   │   │   ├── app_initialization_service.dart  # 应用初始化
│   │   │   ├── log_service.dart                 # 日志服务
│   │   │   ├── network_service.dart             # 网络服务
│   │   │   └── permission_service.dart          # 权限服务
│   │   ├── storage/             # 本地存储
│   │   └── utils/               # 工具函数
│   │
│   ├── features/                # 功能模块（按功能组织）
│   │   ├── agent/              # Agent 系统
│   │   │   ├── data/           # 数据层
│   │   │   │   ├── agent_repository.dart        # Agent 仓库
│   │   │   │   ├── default_agents.dart          # 默认 Agent 配置
│   │   │   │   └── tool_executor.dart           # 工具执行器
│   │   │   ├── domain/         # 领域层
│   │   │   │   ├── agent_config.dart            # Agent 配置模型
│   │   │   │   └── agent_tool.dart              # 工具模型
│   │   │   └── presentation/   # 展示层
│   │   │       ├── providers/                   # Agent Providers
│   │   │       └── widgets/                     # Agent UI 组件
│   │   │
│   │   ├── chat/               # 聊天功能
│   │   │   ├── data/           # 数据层
│   │   │   ├── domain/         # 领域层
│   │   │   └── presentation/   # 展示层
│   │   │
│   │   ├── conversation/       # 对话管理
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── mcp/                # MCP 协议支持
│   │   │   ├── data/
│   │   │   │   ├── default_mcp_servers.dart     # 默认 MCP 配置
│   │   │   │   └── mcp_repository.dart          # MCP 仓库
│   │   │   ├── domain/
│   │   │   │   └── mcp_config.dart              # MCP 配置模型
│   │   │   └── presentation/
│   │   │
│   │   └── settings/           # 设置功能
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │
│   └── shared/                 # 共享组件
│       ├── themes/             # 主题配置
│       ├── widgets/            # 通用 UI 组件
│       └── utils/              # 共享工具
│
├── assets/                     # 资源文件
│   ├── backgrounds/           # 背景图片
│   ├── icons/                 # 图标
│   └── images/                # 其他图片
│
├── test/                      # 测试文件
│   ├── features/             # 功能测试
│   │   └── agent/           # Agent 测试
│   ├── integration/         # 集成测试
│   ├── unit/                # 单元测试
│   └── widget/              # Widget 测试
│
├── docs/                      # 文档目录
│   ├── README.md             # 文档索引
│   ├── FEATURES.md           # 功能详解
│   ├── agent-user-guide.md   # Agent 使用指南
│   ├── mcp-quick-start.md    # MCP 快速开始
│   ├── architecture.md       # 架构设计
│   └── api.md                # API 文档
│
├── scripts/                   # 脚本文件
│   ├── build_and_run.sh      # 构建运行脚本
│   └── hooks/                # Git 钩子
│
├── android/                   # Android 平台代码
├── ios/                       # iOS 平台代码
├── web/                       # Web 平台代码
├── windows/                   # Windows 平台代码
├── macos/                     # macOS 平台代码
├── linux/                     # Linux 平台代码
│
├── pubspec.yaml              # Flutter 项目配置
├── analysis_options.yaml     # 代码分析配置
├── README.md                 # 项目说明
├── AGENTS.md                 # Agent 开发文档
├── LICENSE                   # 许可证
└── .gitignore               # Git 忽略配置
```

## 🏗️ 架构模式

### Clean Architecture

项目采用清晰的分层架构：

```
┌─────────────────────────────────────┐
│       Presentation Layer            │  ← UI、Widgets、Providers
├─────────────────────────────────────┤
│         Domain Layer                │  ← Models、Entities、Use Cases
├─────────────────────────────────────┤
│          Data Layer                 │  ← Repositories、Data Sources
└─────────────────────────────────────┘
```

### Feature-First 组织

按功能（Feature）组织代码，每个功能模块包含：

- **data/**: 数据访问层
- **domain/**: 业务逻辑层
- **presentation/**: UI 展示层

### 依赖注入

使用 Riverpod 进行依赖管理和状态管理。

## 📦 核心模块说明

### Core Module

**职责**: 提供应用级别的基础服务

**主要组件**:
- `StorageService`: 本地存储服务
- `LogService`: 日志服务
- `NetworkService`: 网络状态管理
- `PermissionService`: 权限管理
- `AppInitializationService`: 应用初始化

### Agent Feature

**职责**: Agent 系统的完整实现

**关键文件**:
- `agent_config.dart`: Agent 配置数据模型
- `agent_tool.dart`: 工具定义和类型
- `agent_repository.dart`: Agent 数据访问
- `default_agents.dart`: 内置 Agent 配置
- `tool_executor.dart`: 工具执行引擎

**工具类型**:
- Calculator: 数学计算
- Search: 网络搜索
- FileOperation: 文件操作
- CodeExecution: 代码执行（规划中）
- Custom: 自定义工具

### MCP Feature

**职责**: Model Context Protocol 集成

**关键文件**:
- `mcp_config.dart`: MCP 服务器配置
- `mcp_repository.dart`: MCP 数据管理
- `default_mcp_servers.dart`: 预置 MCP 服务器

**连接模式**:
- HTTP: RESTful API 模式
- Stdio: 进程通信模式

### Chat Feature

**职责**: 核心聊天功能

**主要功能**:
- 流式对话
- 多模态输入
- Markdown 渲染
- LaTeX 公式支持

### Conversation Feature

**职责**: 对话管理

**主要功能**:
- 分组管理
- 标签系统
- 搜索功能
- 数据导出

### Settings Feature

**职责**: 应用设置

**主要功能**:
- API 配置
- 主题设置
- 偏好管理

## 🔄 数据流

### Agent 执行流程

```
User Input
    ↓
Chat Screen
    ↓
Agent Provider
    ↓
Agent Repository
    ↓
Tool Executor
    ↓
Tool Implementation
    ↓
Result
    ↓
UI Update
```

### MCP 调用流程

```
AI Request
    ↓
MCP Provider
    ↓
MCP Repository
    ↓
HTTP/Stdio Client
    ↓
MCP Server
    ↓
Tool Response
    ↓
AI Processing
    ↓
User Response
```

## 🛠️ 关键技术

### 状态管理
- **Riverpod**: 全局状态管理
- **Provider**: 依赖注入
- **FutureProvider**: 异步数据
- **StateNotifier**: 复杂状态

### 数据持久化
- **Hive**: 本地 NoSQL 数据库
- **SharedPreferences**: 简单键值对
- **SecureStorage**: 敏感数据加密

### 网络通信
- **Dio**: HTTP 客户端
- **Retrofit**: RESTful API
- **WebSocket**: 实时通信（规划中）

### UI 框架
- **Material Design**: UI 设计语言
- **Custom Widgets**: 自定义组件
- **Responsive**: 响应式布局

## 📝 命名规范

### 文件命名
- 使用 `snake_case`
- 示例: `agent_repository.dart`

### 类命名
- 使用 `PascalCase`
- 示例: `AgentRepository`

### 变量/方法命名
- 使用 `camelCase`
- 示例: `getAllAgents()`

### 常量命名
- 使用 `UPPER_SNAKE_CASE`
- 示例: `MAX_RETRY_COUNT`

### Provider 命名
- 以 `Provider` 结尾
- 示例: `agentRepositoryProvider`

## 🧪 测试策略

### 单元测试
```
test/unit/
├── core/
├── features/
└── shared/
```

### Widget 测试
```
test/widget/
├── chat/
├── settings/
└── components/
```

### 集成测试
```
test/integration/
├── agent_workflow_test.dart
├── chat_flow_test.dart
└── mcp_integration_test.dart
```

## 🚀 构建流程

### 开发环境
```bash
flutter run -d chrome        # Web
flutter run -d macos         # macOS
flutter run -d ios           # iOS
```

### 代码生成
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 测试
```bash
flutter test                 # 所有测试
flutter test test/unit/      # 单元测试
flutter test test/widget/    # Widget 测试
```

### 打包
```bash
flutter build web            # Web
flutter build macos          # macOS
flutter build ios            # iOS
flutter build apk            # Android APK
```

## 📚 相关文档

- [功能特性](FEATURES.md)
- [架构设计](architecture.md)
- [API 文档](api.md)
- [Agent 指南](agent-user-guide.md)
- [MCP 快速开始](mcp-quick-start.md)

## 🤝 贡献指南

### 添加新功能

1. **创建功能目录**
   ```
   lib/features/your_feature/
   ├── data/
   ├── domain/
   └── presentation/
   ```

2. **实现三层架构**
   - Domain: 定义模型和接口
   - Data: 实现数据访问
   - Presentation: 构建 UI

3. **添加测试**
   ```
   test/features/your_feature/
   ├── your_feature_test.dart
   └── ...
   ```

4. **更新文档**
   - 更新相关 .md 文档
   - 添加代码注释

### 代码规范

- 遵循 `analysis_options.yaml` 配置
- 运行 `flutter analyze` 检查
- 使用 `flutter format` 格式化代码
- 提交前运行测试

## 🔍 故障排查

### 常见问题

**问题**: 依赖冲突
```bash
flutter pub get
flutter clean
flutter pub get
```

**问题**: 代码生成错误
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

**问题**: 平台构建失败
```bash
cd ios && pod install     # iOS
flutter build clean       # 清除构建
```

---

**最后更新**: 2025-01-18
