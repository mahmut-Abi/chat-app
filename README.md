# Flutter Chat App

<div align="center">

**🚀 功能强大的跨平台 AI 聊天应用**

一个基于 Flutter 开发的现代化 AI 聊天应用，支持多平台部署，提供流畅的对话体验和丰富的功能特性。

[![Flutter Version](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Web%20%7C%20macOS%20%7C%20iOS%20%7C%20Android-lightgrey.svg)](https://flutter.dev/)

[功能特性](#-功能特性) • [快速开始](#-快速开始) • [使用指南](#-使用指南) • [开发文档](#-开发文档) • [贡献指南](#-贡献指南)

</div>

---

## ✨ 功能特性

### 💬 智能对话
- **多模型支持** - OpenAI、DeepSeek、Claude、Ollama 等兼容 OpenAI API 的服务
- **流式响应** - 实时流式输出，打字机效果
- **多模态输入** - 支持文本和图片输入
- **上下文管理** - 智能管理对话历史，支持消息编辑和重新生成

### 📝 内容渲染
- **Markdown 支持** - 完整的 Markdown 渲染，代码高亮
- **LaTeX 公式** - 支持行内和块级数学公式：$E=mc^2$
- **代码美化** - 语法高亮，一键复制代码块
- **表格支持** - 完美渲染 Markdown 表格

### 🎯 会话管理
- **智能分组** - 8 种颜色标识的分组系统
- **标签系统** - 多维度标签，灵活筛选
- **对话置顶** - 重要对话快速访问
- **搜索功能** - 全文搜索对话内容
- **批量操作** - 支持批量导出、删除

### 🤖 Agent & MCP
- **Agent 系统** - 创建自定义 AI Agent，配置专属工具
- **MCP 协议** - 完整支持 Model Context Protocol
  - HTTP 模式 - RESTful API 通信
  - Stdio 模式 - JSON-RPC 2.0 进程通信
- **内置工具** - 搜索、计算器、文件操作、代码执行
- **提示词库** - 丰富的模板库，支持变量占位符

### 📊 数据分析
- **Token 统计** - 实时显示和统计 Token 使用
- **成本分析** - 按会话、按模型分析成本
- **使用报告** - 详细的使用记录和可视化图表
- **数据导出** - 支持 JSON、Markdown、PDF 格式

### 🎨 个性化
- **主题切换** - 亮色/暗色/跟随系统
- **颜色定制** - 6 种主题颜色可选
- **背景设置** - 支持纯色、渐变、图片背景
- **毛玻璃效果** - 现代化的 UI 设计
- **响应式布局** - 完美适配桌面和移动端

---

## 🚀 快速开始

### 环境要求

```bash
Flutter SDK ≥ 3.0.0
Dart SDK ≥ 3.0.0
```

**推荐使用 Homebrew 安装** (macOS):
```bash
brew install flutter
brew install cocoapods
```

### 平台支持

| 平台 | 状态 | 备注 |
|------|------|------|
| 🌐 Web | ✅ 完全支持 | Chrome、Safari、Edge |
| 🖥️ macOS | ✅ 完全支持 | macOS 10.14+ |
| 📱 iOS | ✅ 完全支持 | iOS 12.0+ |
| 🤖 Android | ✅ 完全支持 | Android 5.0+ (API 21+) |
| 🪟 Windows | ⏳ 基础支持 | 开发中 |
| 🐧 Linux | ⏳ 基础支持 | 开发中 |

### 安装和运行

```bash
# 1. 克隆项目
git clone <repository-url>
cd chat-app

# 2. 安装依赖
flutter pub get

# 3. 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 运行应用
flutter run -d chrome        # Web
flutter run -d macos         # macOS
flutter run -d ios           # iOS
flutter run -d android       # Android
```

### 构建发布版本

```bash
flutter build web --release          # Web
flutter build macos --release        # macOS
flutter build ios --release          # iOS
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle
```

---

## 📖 使用指南

### 1. 配置 API

首次使用需要配置 AI 服务的 API：

1. 点击右上角 **⚙️ 设置** 按钮
2. 选择 **API 配置** 标签页
3. 点击 **+ 添加配置** 按钮
4. 填写配置信息：

```yaml
配置名称: OpenAI
提供商: OpenAI
Base URL: https://api.openai.com/v1
API Key: sk-your-api-key-here
代理设置: http://127.0.0.1:7890 (可选)
```

5. 点击 **保存** 并 **激活** 配置

> 💡 **提示**: 支持多个 API 配置，可以随时切换使用

### 2. 开始对话

**创建新对话**:
- 点击左侧边栏 **+ 新建对话** 按钮
- 或使用快捷键 `Cmd/Ctrl + N`

**发送消息**:
- 在输入框输入消息，按 `Enter` 发送
- 按 `Shift + Enter` 换行
- 支持上传图片（多模态模型）

**消息操作**:
- 📋 复制 - 复制 AI 回复内容
- ♻️ 重新生成 - 重新生成 AI 回复
- ✏️ 编辑 - 编辑用户消息
- 🗑️ 删除 - 删除消息

### 3. 高级功能

#### 会话管理

**创建分组**:
```
右键对话 → 移动到分组 → 新建分组
设置: 分组名称 + 颜色标识
```

**添加标签**:
```
右键对话 → 管理标签 → 选择或新建标签
支持: 多标签筛选和搜索
```

**对话操作**:
- 📌 置顶 - 固定在列表顶部
- ✏️ 重命名 - 修改对话标题
- 📤 导出 - 导出为 Markdown/PDF
- 🗑️ 删除 - 删除对话

#### MCP 集成

**添加 MCP 服务器**:
```
设置 → MCP → + 添加服务器

HTTP 模式:
- 服务器名称: Weather Server
- URL: https://api.weather.com
- API Key: (可选)

Stdio 模式:
- 命令: /usr/bin/node
- 参数: server.js
- 工作目录: /path/to/server
```

**使用 MCP 工具**:
- 在聊天输入框点击 🔧 工具按钮
- 选择已启用的 MCP 服务器
- AI 将自动调用相关工具

#### Agent 系统

**创建 Agent**:
```yaml
设置 → Agent → + 创建 Agent

名称: 研究助手
描述: 专注于学术研究和文献分析
系统提示词: |
  你是一个专业的研究助手，擅长：
  1. 文献检索和分析
  2. 数据整理和总结
  3. 学术写作建议
可用工具:
  ☑ 搜索工具
  ☑ 文件操作
```

**使用 Agent**:
- 在聊天输入框点击 🤖 按钮
- 选择要使用的 Agent
- AI 将按 Agent 配置执行任务

#### 提示词模板

**创建模板**:
```
设置 → 提示词 → + 创建模板

标题: 代码审查
分类: 编程
标签: 代码, 审查, 质量
内容:
请审查以下代码：

{{code}}

重点关注：
1. 代码质量和可读性
2. 性能优化建议
3. 安全问题
```

**使用模板**:
- 点击模板的 **使用** 按钮
- 填写变量占位符（如 `{{code}}`）
- 自动填充到输入框

---

## 🏗️ 项目架构

### 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.0+ |
| 状态管理 | Riverpod 2.x |
| 路由 | go_router |
| 网络请求 | dio |
| 本地存储 | shared_preferences + flutter_secure_storage |
| 代码生成 | freezed + json_serializable |
| Markdown | flutter_markdown |
| LaTeX | flutter_math_fork |
| PDF | pdf + printing |

### 目录结构

```
lib/
├── core/                   # 核心功能层
│   ├── constants/          # 常量定义
│   ├── error/              # 错误处理
│   ├── network/            # 网络层 (Dio、API 客户端)
│   ├── providers/          # 全局 Provider
│   ├── routing/            # 路由配置 (go_router)
│   ├── services/           # 系统服务
│   ├── storage/            # 本地存储
│   └── utils/              # 工具类
├── features/               # 功能模块层
│   ├── chat/               # 聊天功能
│   │   ├── data/           # 数据层 (Repository)
│   │   ├── domain/         # 领域层 (Models)
│   │   └── presentation/   # 表现层 (UI)
│   ├── agent/              # Agent 系统
│   ├── mcp/                # MCP 集成
│   ├── models/             # 模型管理
│   ├── prompts/            # 提示词模板
│   ├── settings/           # 设置页面
│   ├── token_usage/        # Token 统计
│   └── logs/               # 日志查看
├── shared/                 # 共享组件层
│   ├── themes/             # 主题配置
│   ├── utils/              # 工具函数
│   └── widgets/            # 通用组件
└── main.dart               # 应用入口
```

### 架构设计

项目采用 **Feature-First + Clean Architecture** 混合架构：

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (UI, Widgets, State Management)      │
├─────────────────────────────────────────┤
│           Domain Layer                  │
│      (Business Logic, Models)           │
├─────────────────────────────────────────┤
│            Data Layer                   │
│   (Repository, Data Sources, API)       │
└─────────────────────────────────────────┘
```

---

## 📚 开发文档

### 核心文档

| 文档 | 说明 |
|------|------|
| [AGENTS.md](AGENTS.md) | 开发规范和贡献指南 |
| [项目结构](docs/project-structure.md) | 完整的目录结构和模块说明 |
| [UI 界面说明](docs/ui-guide.md) | 所有界面的设计和功能说明 |
| [架构设计](docs/architecture.md) | 架构详细说明 |
| [MCP 集成](docs/mcp-integration.md) | MCP 协议集成指南 |
| [API 文档](docs/api.md) | API 接口文档 |

### 开发规范

**代码风格**:
```bash
# 格式化代码
flutter format .

# 静态分析
flutter analyze

# 运行测试
flutter test

# 测试覆盖率
flutter test --coverage
```

**Git Hooks**:
```bash
# 安装 hooks (自动格式检查和代码分析)
./scripts/setup-hooks.sh
```

**提交规范** (Conventional Commits + 中文):
```
feat(聊天): 添加流式响应支持
fix(设置): 修复 API 配置保存问题
docs(readme): 更新使用说明
style(ui): 调整消息气泡样式
refactor(mcp): 重构 MCP 客户端代码
test(chat): 添加聊天仓库测试
chore(deps): 更新依赖版本
```

### 添加新功能

1. **创建功能模块目录**:
```bash
mkdir -p lib/features/new_feature/{data,domain,presentation}
```

2. **定义数据模型** (使用 freezed):
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

3. **创建 Repository**:
```dart
class MyRepository {
  final StorageService _storage;
  
  Future<List<MyModel>> getAll() async {
    // 实现逻辑
  }
}
```

4. **定义 Provider**:
```dart
final myRepositoryProvider = Provider<MyRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return MyRepository(storage);
});
```

5. **构建 UI**:
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(myRepositoryProvider);
    return Scaffold(/* ... */);
  }
}
```

6. **添加路由**:
```dart
GoRoute(
  path: '/my-feature',
  builder: (context, state) => const MyScreen(),
)
```

7. **生成代码并测试**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test
```

详细步骤请参考 [项目结构文档](docs/project-structure.md)。

---

## 🧪 测试

### 测试结构

```
test/
├── unit/                   # 单元测试
│   └── features/
│       └── chat/
│           └── chat_repository_test.dart
├── widget/                 # Widget 测试
│   └── message_bubble_test.dart
└── integration/            # 集成测试
    └── chat_flow_test.dart
```

### 测试示例

```dart
group('ChatRepository', () {
  late ChatRepository repository;
  
  setUp(() {
    repository = ChatRepository();
  });
  
  test('应该正确创建对话', () async {
    final conversation = await repository.createConversation(
      title: '测试对话',
    );
    
    expect(conversation.title, '测试对话');
    expect(conversation.messages, isEmpty);
  });
  
  test('应该正确发送消息', () async {
    // 测试实现
  });
});
```

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/unit/chat_repository_test.dart

# 生成覆盖率报告
flutter test --coverage
open coverage/html/index.html
```

---

## 🤝 贡献指南

我们欢迎所有形式的贡献！

### 如何贡献

1. **Fork 项目**
2. **创建特性分支** (`git checkout -b feature/AmazingFeature`)
3. **提交更改** (`git commit -m 'feat(模块): 添加某个功能'`)
4. **推送到分支** (`git push origin feature/AmazingFeature`)
5. **开启 Pull Request**

### 贡献类型

- 🐛 **Bug 修复** - 修复已知问题
- ✨ **新功能** - 添加新特性
- 📝 **文档改进** - 完善文档
- 🎨 **UI 优化** - 改进界面设计
- ⚡ **性能优化** - 提升性能
- 🧪 **测试** - 添加或改进测试

### 代码审查

所有 Pull Request 需要：
- ✅ 通过所有测试
- ✅ 代码格式检查通过
- ✅ 无静态分析警告
- ✅ 至少一位维护者审核通过

详细贡献指南请查看 [AGENTS.md](AGENTS.md)。

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

---

## 📮 联系方式

- 📧 Email: your-email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/your-repo/discussions)

---

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者！

特别感谢：
- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [Riverpod](https://riverpod.dev/) - 状态管理
- [OpenAI](https://openai.com/) - AI 模型
- [Model Context Protocol](https://modelcontextprotocol.io/) - MCP 协议

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给个 Star！⭐**

Made with ❤️ by Flutter Chat App Team

</div>
