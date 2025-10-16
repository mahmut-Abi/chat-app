# Flutter Chat App

> 类似 Cherry Studio 的跨平台 AI 聊天应用

一个功能丰富的跨平台 AI 聊天应用，采用 Flutter 开发，支持 Web、Desktop（Windows/macOS/Linux）和 Mobile（iOS/Android）平台。提供流畅的对话体验、强大的会话管理功能、灵活的模型配置以及完整的 MCP 和 Agent 系统集成。

## ✨ 主要功能

### 核心功能
- 🤖 **多模型支持** - 支持 OpenAI、Claude、Azure OpenAI、Ollama 等兼容 OpenAI 格式的 API
- 💬 **流式响应** - 实时流式对话，体验更流畅
- 📝 **Markdown 渲染** - 完整支持 Markdown 格式，包含代码高亮和一键复制
- 🧮 **LaTeX 公式** - 支持行内和块级数学公式渲染
- 🎯 **会话管理** - 创建、编辑、删除和搜索对话
- 🔄 **上下文管理** - 智能管理对话历史，支持消息编辑和重新生成
- 🖼️ **图片支持** - 支持多模态模型的图片输入功能

### 高级功能
- 📁 **会话分组** - 使用颜色标识的分组系统组织对话
- 🏷️ **标签系统** - 为对话添加标签，支持多维度筛选
- 🔢 **Token 计数** - 实时显示和统计 token 使用情况
- 📄 **多格式导出** - 支持导出为 Markdown 和 PDF 格式
- ⚙️ **模型配置** - 灵活配置温度、max tokens 等参数
- 🎨 **主题切换** - 支持亮色/暗色主题
- 🌈 **自定义主题** - 支持自定义主题颜色和背景图片
- 💾 **数据管理** - 导入/导出所有数据，支持数据迁移
- 🔍 **智能搜索** - 快速搜索对话内容和标题
- 📌 **对话置顶** - 重要对话可以置顶显示
- 📱 **响应式设计** - 完美适配桌面和移动端

### MCP 和 Agent 集成
- 🔌 **MCP 协议支持** - 完整实现 Model Context Protocol
  - HTTP 模式：支持 RESTful API 通信
  - Stdio 模式：支持 JSON-RPC 2.0 协议和进程管理
  - 实时连接状态监控和心跳检测
- 🛠️ **工具系统** - 内置多种实用工具
  - 🔍 搜索工具：网络搜索功能
  - 🧮 计算器：数学表达式计算
  - 📁 文件操作：文件读写管理
  - 💻 代码执行：安全的代码运行环境
- 🤖 **Agent 管理** - 创建和配置智能 Agent
  - 自定义系统提示词
  - 选择可用工具集
  - Agent 启用/禁用控制
- 📝 **提示词模板库** - 专业的模板管理系统
  - 分类和标签管理
  - 支持收藏和快速使用
  - 变量占位符支持
- 📊 **Token 使用统计** - 详细的使用分析
  - 按会话统计
  - 按模型分析
  - 成本计算和预估
- 📋 **日志查看** - 完整的系统日志记录


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

## 📚 使用指南

### 1. 配置 API

首次启动应用后：

1. 点击右上角的设置图标 ⚙️
2. 在“API 配置”部分点击“添加 API 配置”
3. 填写配置信息：
   - **配置名称**：如 "OpenAI" 或 "Claude"
   - **提供商**：选择 API 提供商类型
   - **Base URL**：API 基础地址
   - **API Key**：你的 API 密钥
4. 点击保存

### 2. 开始聊天

1. 点击右上角的“+”按钮创建新对话
2. 在输入框中输入你的问题
3. 按 Enter 或点击发送按钮
4. AI 将以流式响应方式回复

### 3. 高级功能

#### 会话管理
- **分组**：右键点击对话，选择“移动到分组”
- **标签**：右键点击对话，选择“管理标签”
- **置顶**：右键点击对话，选择“置顶/取消置顶”
- **搜索**：点击侧边栏的搜索图标

#### MCP 集成
1. 在设置中打开“MCP”页面
2. 点击“添加 MCP 服务器”
3. 配置服务器信息：
   - **名称**：服务器名称
   - **类型**：选择 HTTP 或 Stdio
   - **HTTP 模式**：填写 URL
   - **Stdio 模式**：填写命令和参数
4. 保存并启用服务器

#### Agent 系统
1. 在设置中打开“Agent”页面
2. 点击“创建 Agent”
3. 配置 Agent：
   - **名称**：Agent 名称
   - **描述**：功能描述
   - **系统提示词**：Agent 行为指导
   - **工具**：选择可用工具
4. 启用 Agent

#### 提示词模板
1. 在设置中打开“提示词模板”页面
2. 点击“创建模板”
3. 填写模板内容，支持变量：`{{variable}}`
4. 保存后在聊天中可以快速使用


## 🏗️ 项目架构

### 技术栈

- **框架**: Flutter 3.0+
- **状态管理**: Riverpod 2.x
- **路由**: go_router
- **本地存储**: shared_preferences + flutter_secure_storage
- **网络请求**: dio
- **代码生成**: freezed + json_serializable
- **Markdown 渲染**: flutter_markdown
- **LaTeX 渲染**: flutter_math_fork
- **PDF 导出**: pdf + printing

### 目录结构

```
lib/
├── core/                    # 核心功能
│   ├── constants/           # 常量定义
│   ├── error/               # 错误处理
│   ├── network/             # 网络层
│   ├── providers/           # 全局 Provider
│   ├── routing/             # 路由配置
│   ├── services/            # 系统服务
│   ├── storage/             # 本地存储
│   └── utils/               # 工具类
├── features/                # 功能模块
│   ├── agent/               # Agent 系统
│   ├── chat/                # 聊天功能
│   ├── logs/                # 日志查看
│   ├── mcp/                 # MCP 集成
│   ├── models/              # 模型管理
│   ├── prompts/             # 提示词模板
│   ├── settings/            # 设置页面
│   └── token_usage/         # Token 统计
├── shared/                  # 共享组件
│   ├── themes/              # 主题配置
│   ├── utils/               # 工具函数
│   └── widgets/             # 通用组件
└── main.dart                # 应用入口
```

每个功能模块采用分层架构：
```
feature/
├── data/                    # 数据层
│   ├── repository.dart      # 数据仓库
│   └── ...                  
├── domain/                  # 领域层
│   ├── models.dart          # 数据模型
│   └── ...
└── presentation/            # 表现层
    ├── screens/             # 页面
    └── widgets/             # 组件
```

## 📱 截图

### 主界面
- 支持桌面和移动端的响应式布局
- 侧边栏展示对话列表，支持分组和标签筛选
- 流式响应实时显示 AI 回复

### 设置页面
- 多标签设计，清晰分类各项设置
- API 配置：支持多个 API 提供商
- 外观设置：主题颜色、背景图片、字体大小
- 高级功能：MCP、Agent、提示词模板
- 数据管理：导入导出、Token 统计

## 🔧 开发指南

### 代码风格

项目遵循 Flutter 官方代码规范：

```bash
# 格式化代码
flutter format .

# 静态分析
flutter analyze

# 运行测试
flutter test
```

### Git Hooks

项目配置了 pre-commit hook，自动进行格式检查和代码分析：

```bash
# 安装 hooks
./scripts/setup-hooks.sh
```

详见 `docs/git-hooks.md`

### 提交规范

采用 Conventional Commits 规范（中文描述）：

```
feat(模块): 添加新功能
fix(模块): 修复问题
docs(模块): 更新文档
style(模块): 代码格式调整
refactor(模块): 代码重构
test(模块): 添加测试
chore(模块): 构建或辅助工具变动
```

示例：
```
feat(聊天): 添加流式响应支持
fix(设置): 修复 API 配置保存问题
docs(readme): 更新使用说明
```

### 添加新功能

1. **创建功能模块**
   ```
   lib/features/new_feature/
   ├── data/
   ├── domain/
   └── presentation/
   ```

2. **定义数据模型**（使用 freezed）
   ```dart
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

3. **创建 Repository**
   ```dart
   class MyRepository {
     Future<List<MyModel>> getAll() async {
       // 实现数据获取逻辑
     }
   }
   ```

4. **创建 Provider**
   ```dart
   final myRepositoryProvider = Provider<MyRepository>((ref) {
     return MyRepository();
   });
   ```

5. **构建 UI**
   ```dart
   class MyScreen extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final repo = ref.watch(myRepositoryProvider);
       // 构建界面
     }
   }
   ```

6. **添加路由**
   ```dart
   GoRoute(
     path: '/my-feature',
     builder: (context, state) => const MyScreen(),
   )
   ```

## 🧪 测试

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行单个测试文件
flutter test test/unit/chat_repository_test.dart

# 生成覆盖率报告
flutter test --coverage
```

### 测试结构

```
test/
├── unit/                    # 单元测试
│   ├── chat_repository_test.dart
│   └── ...
├── widget/                  # Widget 测试
│   ├── message_bubble_test.dart
│   └── ...
└── integration/             # 集成测试
```

### 测试示例

```dart
group('ChatRepository', () {
  test('应该正确创建对话', () async {
    final repo = ChatRepository();
    final conversation = await repo.createConversation(
      title: '测试对话',
    );
    
    expect(conversation.title, '测试对话');
    expect(conversation.messages, isEmpty);
  });
});
```

## 📊 功能完成度

### 聊天功能
- ✅ 多模型支持（OpenAI、Claude、Azure、Ollama）
- ✅ 流式响应
- ✅ Markdown 渲染（代码高亮、表格、列表）
- ✅ LaTeX 公式渲染
- ✅ 图片输入支持
- ✅ 消息编辑和重新生成
- ✅ 上下文管理（分支对话）
- ✅ Token 计数显示

### 会话管理
- ✅ 创建、编辑、删除对话
- ✅ 对话分组（8种颜色标识）
- ✅ 标签系统（多标签筛选）
- ✅ 对话搜索（标题和内容）
- ✅ 对话置顶
- ✅ 临时对话（首次消息后自动保存）

### MCP 集成
- ✅ HTTP 模式支持
- ✅ Stdio 模式支持（进程管理）
- ✅ 工具调用
- ✅ 资源管理
- ✅ 提示词管理
- ✅ 连接状态监控
- ✅ 心跳检测

### Agent 系统
- ✅ Agent 创建和管理
- ✅ 内置工具（搜索、计算器、文件操作）
- ✅ 工具调用集成
- ✅ Agent 启用/禁用
- ✅ 自定义系统提示词

### 提示词模板
- ✅ 模板创建、编辑、删除
- ✅ 分类管理
- ✅ 标签系统
- ✅ 收藏功能
- ✅ 变量占位符支持

### Token 统计
- ✅ 详细使用记录
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
- ✅ 完全清除数据

### 外观定制
- ✅ 亮色/暗色主题
- ✅ 自定义主题颜色
- ✅ 背景图片设置
- ✅ 字体大小调整
- ✅ 响应式布局

