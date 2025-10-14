# 📚 Flutter Chat App 文档中心

> 最后更新时间: 2024-10-15

## 📌 快速导航

### 🚀 新手入门

如果你是第一次使用本项目，请按以下顺序阅读：

1. **[START_HERE.md](START_HERE.md)** - 项目快速入门指南
2. **[QUICKSTART.md](QUICKSTART.md)** - 5分钟快速启动
3. **[SETUP.md](SETUP.md)** - 详细环境配置指南

### 📖 项目文档

#### 核心文档
- **[../README.md](../README.md)** - 项目总览和功能介绍
- **[FEATURES.md](FEATURES.md)** - 完整功能特性列表
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - 技术架构详解
- **[PROGRESS_SUMMARY.md](PROGRESS_SUMMARY.md)** - 项目进度总结

#### 开发规范
- **[../AGENTS.md](../AGENTS.md)** - 代码规范和贡献指南
- **[../todo.md](../todo.md)** - 开发路线图和任务清单
- **[git-hooks.md](git-hooks.md)** - Git Hooks 使用说明

### 🔧 功能文档

#### MCP 集成
- **[mcp-integration.md](mcp-integration.md)** - Model Context Protocol 集成指南
- **[mcp-agent-features.md](mcp-agent-features.md)** - MCP Agent 功能详解

#### 平台支持
- **[platform_support.md](platform_support.md)** - 平台支持概览
- **[ios_build_notes.md](ios_build_notes.md)** - iOS 构建说明
- **[ios_troubleshooting.md](ios_troubleshooting.md)** - iOS 问题排查
- **[ios-crash-fix.md](ios-crash-fix.md)** - iOS 崩溃修复记录
- **[ios-glass-effect.md](ios-glass-effect.md)** - iOS 毛玻璃效果实现
- **[platform_dialog_usage.md](platform_dialog_usage.md)** - 平台对话框使用指南

#### UI/UX
- **[app-icon-guide.md](app-icon-guide.md)** - 应用图标配置指南
- **[app_icon_setup.md](app_icon_setup.md)** - 应用图标设置
- **[README_ICON.md](README_ICON.md)** - 图标使用说明
- **[sidebar-features.md](sidebar-features.md)** - 侧边栏功能说明

### 🛠️ 开发工具

#### CI/CD
- **[github_actions.md](github_actions.md)** - GitHub Actions 配置
- **[github-actions-artifacts.md](github-actions-artifacts.md)** - 构建产物说明
- **[ci-troubleshooting.md](ci-troubleshooting.md)** - CI 问题排查

#### 部署
- **[docker.md](docker.md)** - Docker 部署指南
- **[http_proxy.md](http_proxy.md)** - HTTP 代理配置

### 🐛 问题排查

- **[KNOWN_ISSUES.md](KNOWN_ISSUES.md)** - 已知问题列表
- **[conversation-fix-summary.md](conversation-fix-summary.md)** - 对话功能修复总结
- **[conversation-issue-diagnosis.md](conversation-issue-diagnosis.md)** - 对话问题诊断
- **[conversation-not-exist-issue.md](conversation-not-exist-issue.md)** - 对话不存在问题修复
- **[settings-fix-summary.md](settings-fix-summary.md)** - 设置功能修复总结

### 📊 项目历史

- **[CHANGELOG.md](CHANGELOG.md)** - 更新日志
- **[COMPLETED_FEATURES.md](COMPLETED_FEATURES.md)** - 已完成功能列表
- **[todo_completed.md](todo_completed.md)** - 已完成任务记录
- **[IMPLEMENTATION_COMPLETE.md](IMPLEMENTATION_COMPLETE.md)** - 实现完成总结
- **[PROJECT_COMPLETION.md](PROJECT_COMPLETION.md)** - 项目完成报告

## 📂 文档组织

### 根目录文档

根目录下只保留三个核心文档：
- `README.md` - 项目说明
- `AGENTS.md` - 开发规范
- `todo.md` - 任务清单

### docs 目录

所有其他文档都存放在 `docs/` 目录下，按类别组织：

```
docs/
├── README.md                    # 本文档（文档索引）
├── START_HERE.md               # 快速入门
├── QUICKSTART.md               # 快速启动
├── SETUP.md                    # 环境配置
├── FEATURES.md                 # 功能特性
├── PROJECT_SUMMARY.md          # 项目总结
├── PROGRESS_SUMMARY.md         # 进度总结
├── mcp-*.md                    # MCP 相关文档
├── ios-*.md, ios_*.md          # iOS 相关文档
├── platform_*.md               # 平台相关文档
├── github*.md, ci-*.md         # CI/CD 相关文档
├── app-icon-*.md, *_icon*.md   # 图标相关文档
├── conversation-*.md           # 对话功能相关文档
└── KNOWN_ISSUES.md             # 已知问题
```

## 🎯 文档使用场景

### 场景 1: 我想快速运行项目

1. [QUICKSTART.md](QUICKSTART.md) - 5分钟快速启动
2. [START_HERE.md](START_HERE.md) - 完整入门指南

### 场景 2: 我想了解项目功能

1. [../README.md](../README.md) - 查看功能概览
2. [FEATURES.md](FEATURES.md) - 查看详细功能列表
3. [mcp-integration.md](mcp-integration.md) - 了解 MCP 集成

### 场景 3: 我想参与开发

1. [../AGENTS.md](../AGENTS.md) - 阅读开发规范
2. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - 了解技术架构
3. [../todo.md](../todo.md) - 查看待办任务
4. [git-hooks.md](git-hooks.md) - 配置 Git Hooks

### 场景 4: 我想构建和部署

1. [SETUP.md](SETUP.md) - 环境配置
2. [platform_support.md](platform_support.md) - 平台支持说明
3. [docker.md](docker.md) - Docker 部署
4. [github_actions.md](github_actions.md) - CI/CD 配置

### 场景 5: 我遇到了问题

1. [KNOWN_ISSUES.md](KNOWN_ISSUES.md) - 检查已知问题
2. [ios_troubleshooting.md](ios_troubleshooting.md) - iOS 问题排查
3. [ci-troubleshooting.md](ci-troubleshooting.md) - CI 问题排查
4. [conversation-fix-summary.md](conversation-fix-summary.md) - 特定功能问题

## 🔍 搜索技巧

在项目根目录使用以下命令快速搜索文档：

```bash
# 搜索所有文档中包含关键词的内容
rg "关键词" docs/

# 列出所有文档文件
find docs -name "*.md" -type f

# 搜索特定主题的文档
ls docs/*mcp*  # MCP 相关
ls docs/*ios*  # iOS 相关
ls docs/*ci*   # CI/CD 相关
```

## 📝 文档贡献

### 新增文档规范

1. **命名规范**
   - 使用小写字母和连字符：`feature-name.md`
   - 使用下划线的遗留文件保持不变
   - 核心文档使用大写：`FEATURES.md`, `README.md`

2. **存放位置**
   - 根目录文档：只能是 `README.md`, `AGENTS.md`, `todo.md`
   - 其他所有文档：必须放在 `docs/` 目录

3. **文档结构**
   - 必须包含标题和更新时间
   - 使用清晰的章节结构
   - 提供目录导航（长文档）
   - 使用中文编写

4. **文档维护**
   - 及时更新过时内容
   - 修复失效链接
   - 删除重复文档
   - 更新本索引文件

## 📞 获取帮助

如果你在文档中找不到答案：

1. 检查 [KNOWN_ISSUES.md](KNOWN_ISSUES.md)
2. 搜索项目 Issues
3. 查看源码注释
4. 提交新的 Issue

---

**维护者**: Flutter Chat App 开发团队  
**许可证**: MIT  
**项目地址**: [GitHub Repository](https://github.com/your-repo/chat-app)
