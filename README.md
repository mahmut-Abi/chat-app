# Flutter Chat App

<div align="center">

**🚀 现代化的跨平台 AI 聊天应用**

基于 Flutter 开发，支持多平台部署，提供流畅的对话体验和丰富的 AI 功能。

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Web%20%7C%20iOS%20%7C%20Android%20%7C%20macOS-lightgrey.svg)](https://flutter.dev/)

[English](README_EN.md) | 简体中文

</div>

---

## ✨ 核心特性

### 🤖 智能 Agent 系统
- **5 个内置专业 Agent** - 开箱即用，自动初始化
  - 通用助手、数学专家、研究助手、文件管理员、编程助手
- **工具集成** - 计算器、搜索、文件操作等
- **自定义 Agent** - 创建专属 AI 助手

### 🔌 MCP 协议支持
- **完整实现** Model Context Protocol
- **双模式** - HTTP 和 Stdio 通信
- **示例配置** - 快速开始模板
- **扩展性强** - 接入各类外部服务

### 💬 智能对话
- **多模型** - OpenAI、DeepSeek、Claude、Ollama 等
- **流式响应** - 实时打字机效果
- **多模态** - 支持文本和图片
- **Markdown + LaTeX** - 完整渲染支持

### 🎨 现代化界面
- **毛玻璃效果** - 优雅的视觉设计
- **主题定制** - 亮色/暗色，多种配色
- **响应式** - 完美适配各种屏幕
- **分组管理** - 智能对话组织

### 📊 数据分析
- **Token 统计** - 实时使用追踪
- **成本分析** - 详细开销报告
- **数据导出** - Markdown/PDF/JSON

## 🚀 快速开始

### 环境要求

```bash
Flutter SDK >= 3.0.0
Dart SDK >= 3.0.0
```

### 安装运行

```bash
# 克隆项目
git clone https://github.com/your-username/chat-app.git
cd chat-app

# 安装依赖
flutter pub get

# 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 运行应用
flutter run -d chrome  # Web
flutter run -d macos   # macOS
flutter run -d ios     # iOS
```

### 配置 API

1. 打开应用 → 设置 → API 配置
2. 添加你的 API Key：
   ```
   提供商: OpenAI / DeepSeek / Claude
   Base URL: https://api.openai.com/v1
   API Key: sk-your-api-key
   ```
3. 保存并激活

就这么简单！应用已自动初始化 Agent 和工具。

## 📸 截图

<div align="center">

### 聊天界面
![Chat Interface](docs/screenshots/chat.png)

### Agent 选择
![Agent Selection](docs/screenshots/agent.png)

### MCP 配置
![MCP Config](docs/screenshots/mcp.png)

</div>

## 🎯 使用场景

| 场景 | Agent | 示例 |
|------|-------|------|
| 数学计算 | 🔢 数学专家 | "解方程 2x + 5 = 13" |
| 资料研究 | 🔍 研究助手 | "搜索关于量子计算的资料" |
| 文件操作 | 📁 文件管理员 | "列出桌面上的文件" |
| 代码开发 | 💻 编程助手 | "写一个 Python 排序算法" |
| 日常对话 | 🤖 通用助手 | "今天天气怎么样？" |

## 📚 文档

### 用户文档
- [功能特性详解](docs/FEATURES.md)
- [Agent 使用指南](docs/agent-user-guide.md)
- [MCP 快速开始](docs/mcp-quick-start.md)

### 开发文档
- [项目架构](docs/architecture.md)
- [项目结构](docs/project-structure.md)
- [API 文档](docs/api.md)
- [优化计划](docs/optimization-plan.md) - 详细的优化方案和实施步骤
- [优化检查清单](docs/optimization-checklist.md) - 快速检查项目状态
- [优化总结](docs/OPTIMIZATION_SUMMARY.md) - 项目优化总览

## 🛠️ 技术栈

- **框架**: Flutter 3.0+
- **状态管理**: Riverpod 2.x
- **路由**: go_router
- **网络**: dio
- **存储**: shared_preferences + secure_storage
- **代码生成**: freezed + json_serializable

## 🤝 贡献

欢迎贡献代码、报告问题或提出建议！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: 添加某功能'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

详见 [贡献指南](CONTRIBUTING.md)

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE)

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台框架
- [Riverpod](https://riverpod.dev/) - 状态管理
- [OpenAI](https://openai.com/) - AI 能力
- [Model Context Protocol](https://modelcontextprotocol.io/) - MCP 标准

---

<div align="center">

**⭐ 如果觉得有用，请给个 Star！⭐**

[报告问题](https://github.com/your-username/chat-app/issues) · [功能建议](https://github.com/your-username/chat-app/discussions) · [加入讨论](https://discord.gg/your-discord)

Made with ❤️ by the Community

</div>
