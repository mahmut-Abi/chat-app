# Flutter Chat App

> 类似 Cherry Studio 的跨平台 AI 聊天应用

一个功能丰富的跨平台 AI 聊天应用，采用 Flutter 开发，支持 Web、Desktop（Windows/macOS/Linux）和 Mobile（iOS/Android）平台。提供流畅的对话体验、强大的会话管理功能和灵活的模型配置。

## ✨ 主要功能

### 核心功能
- 🤖 **多模型支持** - 支持 OpenAI、Azure OpenAI、Ollama 等兼容 OpenAI 格式的 API
- 💬 **流式响应** - 实时流式对话，体验更流畅
- 📝 **Markdown 渲染** - 完整支持 Markdown 格式，包含代码高亮和一键复制
- 🧮 **LaTeX 公式** - 支持行内和块级数学公式渲染
- 🎯 **会话管理** - 创建、编辑、删除和搜索对话
- 🔄 **上下文管理** - 智能管理对话历史，支持消息编辑和重新生成

### 高级功能
- 📁 **会话分组** - 使用颜色标识的分组系统组织对话
- 🏷️ **标签系统** - 为对话添加标签，支持多维度筛选
- 🔢 **Token 计数** - 实时显示和统计 token 使用情况
- 📄 **多格式导出** - 支持导出为 Markdown 和 PDF 格式
- ⚙️ **模型配置** - 灵活配置温度、max tokens 等参数
- 🎨 **主题切换** - 支持亮色/暗色主题
- 💾 **数据管理** - 导入/导出所有数据，支持数据迁移
- 🔍 **智能搜索** - 快速搜索对话内容和标题
- 📌 **对话置顶** - 重要对话可以置顶显示
 - 🔌 **MCP 集成** - 支持 Model Context Protocol (HTTP 和 Stdio 模式)
 - 🛠️ **工具调用** - 通过 MCP 服务器扩展 AI 能力
 - 🌐 **上下文增强** - 使用 MCP 提供外部上下文信息
 - 🤖 **Agent 系统** - 创建和管理 AI Agent，支持工具调用
 - 📝 **提示词模板** - 管理和复用提示词模板库
 - 📊 **Token 统计** - 详细的 Token 使用统计和分析

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- 对于 macOS 构建：需要安装 CocoaPods
- 对于 iOS 构建：需要 Xcode 14.0 或更高版本
- 对于 Android 构建：需要 Android SDK，minSdkVersion 21 (Android 5.0)

建议使用 Homebrew 安装 Flutter：
```bash
brew install flutter
brew install cocoapods
```

### 平台支持

✅ **Web** - 完全支持
✅ **macOS** - 完全支持
✅ **iOS** - 完全支持 (iOS 12.0+)
✅ **Android** - 完全支持 (Android 5.0+, API 21+)
⏳ **Windows** - 基础支持
⏳ **Linux** - 基础支持

### 安装依赖

```bash
# 克隆项目
git clone <repository-url>
cd chat-app

# 安装依赖
flutter pub get

# 生成代码（Freezed、JSON serialization）
flutter pub run build_runner build --delete-conflicting-outputs
```

### 运行应用

```bash
# Web 平台
flutter run -d chrome

# macOS 平台
flutter run -d macos

# iOS 平台（需要 Xcode 和 iOS 模拟器/真机）
flutter run -d ios

# Android 平台（需要 Android SDK 和模拟器/真机）
flutter run -d android

# 其他平台
flutter run
```

### 构建发布版本

```bash
# Web
flutter build web --release

# macOS
flutter build macos --release

# iOS
flutter build ios --release

# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Windows
flutter build windows --release
```

## 📖 使用指南

### 1. 配置 API

首次启动应用后：

1. 点击右上角的设置图标 ⚙️
2. 在"API 配置"部分点击"添加 API 配置"
3. 填写配置信息：
   - **配置名称**：如 "OpenAI" 或 "Claude"
   - **提供商**：选择 API 提供商类型
   - **Base URL**：API 基础地址
   - **API Key**：你的 API 密钥
4. 点击保存

支持的提供商：
- OpenAI (https://api.openai.com/v1)
- Azure OpenAI
- Ollama (http://localhost:11434/v1)
- 其他兼容 OpenAI 格式的服务

### 2. 开始对话

1. 点击侧边栏的"新建对话"按钮
2. 在输入框输入消息
3. 点击发送按钮或按 Enter 键
4. AI 将以流式方式回复

### 3. 配置 MCP 服务器（可选）

MCP (Model Context Protocol) 允许 AI 访问外部工具和上下文信息。

**添加 HTTP 模式 MCP 服务器：**

1. 点击侧边栏的 "MCP 配置" 菜单
2. 点击右上角 "+" 按钮
3. 填写配置：
   - 名称：如 "本地 MCP 服务器"
   - 连接类型：HTTP
   - 端点 URL：http://localhost:3000
   - 描述：服务器说明（可选）
4. 点击 "添加" 保存
5. 使用开关启用服务器，点击播放按钮连接

**添加 Stdio 模式 MCP 服务器：**

1. 点击侧边栏的 "MCP 配置" 菜单
2. 点击右上角 "+" 按钮
3. 填写配置：
   - 名称：如 "文件操作工具"
   - 连接类型：Stdio
   - 命令路径：/path/to/mcp-server
   - 命令参数：--verbose --port 3000（可选）
   - 环境变量：添加需要的环境变量（可选）
   - 描述：服务器说明（可选）
4. 点击 "添加" 保存
5. 使用开关启用服务器，点击播放按钮连接

**连接状态说明：**
- 🟢 绿色：已连接
- 🟠 橙色：连接中
- 🔴 红色：连接失败
- ⚪ 灰色：未连接

详细的 MCP 使用文档请参考 [docs/mcp-integration.md](docs/mcp-integration.md)

### 4. 高级功能

#### Agent 系统

1. 点击侧边栏的 "Agent 管理" 菜单
2. 在 "Agent" 标签页中创建新的 Agent
3. 在 "工具" 标签页中管理可用工具
   - 搜索：网络搜索功能
   - 计算器：数学计算
   - 文件操作：读写文件
   - 代码执行：执行代码片段
4. 为 Agent 分配需要的工具

#### 提示词模板

1. 点击侧边栏的 "提示词模板" 菜单
2. 点击右下角 "+" 按钮创建新模板
3. 填写模板信息：
   - 名称：模板名称
   - 分类：模板分类
   - 内容：提示词文本
   - 标签：使用逗号分隔
4. 使用分类筛选器快速查找模板
5. 点击收藏图标可以仅显示收藏的模板

#### Token 统计

1. 点击侧边栏的 "Token 统计" 菜单
2. 查看详细的 Token 使用记录
3. 按会话或模型筛选
4. 选择日期范围查看特定时期的使用情况
5. 查看成本分析

#### 会话分组

- 点击侧边栏顶部的文件夹图标 📁 管理分组
- 创建分组时可选择8种预设颜色
- 使用下拉框筛选特定分组的对话

#### 标签管理

- 右键点击对话项，选择"管理标签"
- 添加或删除标签
- 点击标签chip快速筛选

#### 模型配置

- 在聊天界面点击右上角的调节图标 🎛️
- 配置模型参数：
  - Temperature (0.0 - 2.0)
  - Max Tokens (1 - 32000)
  - Top P (0.0 - 1.0)
  - Frequency Penalty (-2.0 - 2.0)
  - Presence Penalty (-2.0 - 2.0)

#### 导出功能

**导出为 JSON**：
1. 进入设置页面
2. 点击"导出数据"
3. 选择保存位置

**导出为 PDF**：
1. 进入设置页面
2. 点击"导出为 PDF"
3. 选择要导出的对话
4. 生成 PDF 文件

#### LaTeX 数学公式

在消息中使用 LaTeX 语法：

```
行内公式：$E = mc^2$

块级公式：
$$
\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}
$$
```

## 🏗️ 项目结构

```
lib/
├── core/                  # 核心功能
│   ├── network/           # 网络请求封装
│   │   ├── dio_client.dart
│   │   ├── openai_api_client.dart
│   │   └── api_exception.dart
│   ├── storage/           # 本地存储
│   │   └── storage_service.dart
│   ├── utils/             # 工具类
│   │   ├── token_counter.dart
│   │   ├── markdown_export.dart
│   │   ├── pdf_export.dart
│   │   └── data_export_import.dart
│   ├── providers/         # 全局 Providers
│   │   └── providers.dart
│   ├── routing/           # 路由配置
│   │   └── app_router.dart
│   └── constants/         # 常量定义
│       └── app_constants.dart
├── features/              # 功能模块
│   ├── chat/              # 聊天功能
│   │   ├── data/          # 数据层
│   │   │   └── chat_repository.dart
│   │   ├── domain/        # 领域模型
│   │   │   ├── message.dart
│   │   │   ├── conversation.dart
│   │   │   └── function_call.dart
│   │   └── presentation/  # UI 层
│   │       ├── home_screen.dart
│   │       ├── chat_screen.dart
│   │       └── widgets/
│   ├── settings/          # 设置功能
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── mcp/               # MCP 集成
│   │   ├── data/          # MCP 客户端实现
│   │   │   ├── http_mcp_client.dart
│   │   │   ├── stdio_mcp_client.dart
│   │   │   ├── mcp_client_factory.dart
│   │   │   └── mcp_repository.dart
│   │   ├── domain/        # MCP 配置模型
│   │   └── presentation/  # MCP UI 界面
│   ├── agent/             # Agent 系统
│   │   ├── data/          # Agent 实现和工具
│   │   ├── domain/        # Agent 模型
│   │   └── presentation/  # Agent UI
│   ├── prompts/           # 提示词模板
│   │   ├── data/          # 模板仓库
│   │   ├── domain/        # 模板模型
│   │   └── presentation/  # 模板 UI
│   ├── token_usage/       # Token 统计
│   │   ├── domain/        # Token 记录模型
│   │   └── presentation/  # 统计 UI
│   └── models/            # 模型管理
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/                # 共享组件
│   ├── widgets/           # UI 组件
│   │   ├── markdown_message.dart
│   │   ├── enhanced_markdown_message.dart
│   │   └── message_actions.dart
│   └── themes/            # 主题配置
│       └── app_theme.dart
└── main.dart              # 应用入口
```

## 🛠️ 技术栈

### 核心依赖
- **状态管理**: Riverpod 2.x
- **路由**: go_router
- **网络**: dio
- **数据库**: hive + flutter_secure_storage
- **代码生成**: freezed + json_serializable

### UI 组件
- **Markdown**: flutter_markdown
- **代码高亮**: flutter_highlight
- **LaTeX**: flutter_math_fork
- **PDF**: pdf + printing
- **图标**: flutter_svg

### 平台特定
- **桌面**: window_manager, tray_manager
- **文件**: file_picker
- **分享**: share_plus

## 🧪 开发

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行测试并生成覆盖率报告
flutter test --coverage
```

### 代码质量

```bash
# 静态分析
flutter analyze

# 格式化代码
flutter format .
```

### 代码生成

```bash
# 生成 Freezed 和 JSON 序列化代码
flutter pub run build_runner build --delete-conflicting-outputs

# 监听文件变化并自动生成
flutter pub run build_runner watch
```

## 📝 功能特性

### 会话管理
- ✅ 创建、删除、重命名对话
- ✅ 对话搜索
- ✅ 会话分组（支持颜色标识）
- ✅ 标签系统（多标签支持）
- ✅ 会话历史浏览

### 消息功能
- ✅ 流式响应显示
- ✅ Markdown 格式渲染
- ✅ 代码语法高亮
- ✅ LaTeX 数学公式
- ✅ 消息编辑/删除
- ✅ 消息重新生成
- ✅ 消息复制

### 模型配置
- ✅ 多模型切换
- ✅ 温度、max tokens 等参数配置
- ✅ 系统提示词设置
- ✅ 多 API 配置管理

### MCP 集成
- ✅ HTTP 模式连接
- ✅ Stdio 模式连接
- ✅ JSON-RPC 2.0 协议支持
- ✅ 工具调用
- ✅ 上下文管理
- ✅ 连接状态监控
- ✅ 自动心跳检测
- ✅ 进程生命周期管理

### Agent 系统
- ✅ Agent 配置管理
- ✅ 工具创建和管理
- ✅ 内置工具：搜索、计算器、文件操作、代码执行
- ✅ 自定义工具支持
- ✅ Agent 启用/禁用控制

### 提示词模板
- ✅ 模板创建和编辑
- ✅ 分类管理
- ✅ 标签系统
- ✅ 收藏功能
- ✅ 快速使用模板
- ✅ 分类筛选

### Token 统计
- ✅ 详细的 Token 使用记录
- ✅ 按会话统计
- ✅ 按模型统计
- ✅ 日期范围筛选
- ✅ 成本分析

### 数据管理
- ✅ 本地数据持久化
- ✅ 导出为 JSON
- ✅ 导出为 Markdown
- ✅ 导出为 PDF
- ✅ 数据导入
- ✅ Token 计数统计

### 外观定制
- ✅ 亮色/暗色主题
- ✅ 响应式布局
- ✅ 流畅动画效果

## 🔐 安全性

- API Key 使用 `flutter_secure_storage` 加密存储
- 敏感数据不会被明文保存
- 支持完全清除本地数据

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

在提交代码前，请确保：

1. 代码通过 `flutter analyze`
2. 代码已格式化 `flutter format .`
3. 测试通过 `flutter test`
4. 提交信息遵循 Conventional Commits 规范（中文描述）

详细的贡献指南请参考 `AGENTS.md`。

## 📄 许可

MIT License - 详见 `LICENSE` 文件

## 🙏 致谢

本项目受 [Cherry Studio](https://github.com/kangfenmao/cherry-studio) 启发。

## 📞 联系方式

如有问题或建议，请通过 Issue 联系。

---

**开发状态**: ✅ 核心功能完成

**最后更新**: 2024-01-21

**功能模块**:
- ✅ 聊天功能（多模型、流式响应、Markdown/LaTeX 渲染）
- ✅ 会话管理（分组、标签、搜索、置顶）
- ✅ MCP 集成（HTTP 和 Stdio 模式）
- ✅ Agent 系统（工具管理和调用）
- ✅ 提示词模板（分类、标签、收藏）
- ✅ Token 统计（详细记录和成本分析）
- ✅ 数据管理（导入/导出 JSON、Markdown、PDF）
- ✅ 多平台支持（Web、macOS、iOS、Android）

## 📝 更新日志

### v0.3.0 (2024-01-21)

**新增功能**
- ✅ MCP (Model Context Protocol) 集成支持
  - HTTP 模式：支持 RESTful API 通信
  - Stdio 模式：支持 JSON-RPC 2.0 协议
  - 工具调用和上下文管理
  - 连接状态实时监控
  - 自动心跳检测和进程生命周期管理
- ✅ 完整的 MCP 配置界面
  - 支持命令参数和环境变量配置
  - 连接类型选择器
  - 状态指示和控制按钮
- ✅ Agent 系统
  - 支持创建和管理 AI Agent
  - 内置多种工具：搜索、计算器、文件操作、代码执行
  - Agent 启用/禁用控制
- ✅ 提示词模板系统
  - 模板创建、编辑和删除
  - 分类和标签管理
  - 收藏和快速使用
- ✅ Token 使用统计
  - 详细的 Token 使用记录
  - 按会话和模型统计
  - 成本分析

**文档**
- 📝 新增 MCP 集成文档 (docs/mcp-integration.md)
- 📝 更新 README 使用说明

### v0.2.0 (2024-01-20)

**新增功能**
- ✅ 会话分组功能，支持8种颜色标识
- ✅ 标签系统，支持多标签筛选
- ✅ PDF 导出功能
- ✅ Token 计数器
- ✅ 消息编辑和重新生成
- ✅ 上下文管理（分支对话）
- ✅ 对话置顶功能
- ✅ 消息搜索功能
- ✅ iOS 和 Android 平台支持

**优化**
- 🚀 改进侧边栏 UI，增加快捷操作
- 🚀 优化流式响应性能
- 🚀 增强错误处理和提示
- 🚀 移除未使用的 Isar 依赖，减小包体积

**修复**
- 🐛 修复颜色选择器编译错误
- 🐛 修复 settings_screen.dart 类结构问题
- 🐛 修复 PDF 导出时的废弃 API 警告
- 🐛 解决依赖包版本冲突

### v0.1.0 (2024-01-10)

- ✅ 初始版本发布
- ✅ 基础聊天功能
- ✅ Markdown 和 LaTeX 渲染
- ✅ 多 API 配置支持
# Test hook
