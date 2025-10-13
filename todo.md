# Flutter Chat App - 项目任务清单

> 类似 Cherry Studio 的跨平台 AI 聊天应用
> 支持平台:Web、Desktop(Windows/macOS/Linux)、Mobile(iOS/Android)

## 🎯 项目目标

- 创建一个现代化的 AI 聊天界面
- 支持 OpenAI 格式的 API 接口
- 跨平台支持(Web/Desktop/Mobile)
- 后期扩展 MCP(Model Context Protocol)和 Agent 功能

---

## 📋 Phase 1: 项目初始化与基础架构

### 1.1 项目搭建
- [x] 初始化 Flutter 项目,配置多平台支持
- [x] 配置项目结构(features/shared/core 架构)
- [x] 添加必要的依赖包
  - [x] `dio` - HTTP 请求
  - [x] `riverpod` - 状态管理
  - [x] `hive` - 本地数据库
  - [x] `go_router` - 路由管理
  - [x] `freezed` - 数据类生成
  - [x] `json_serializable` - JSON 序列化
- [x] 配置代码生成工具(build_runner)
- [x] 设置 lint 规则和代码格式化

### 1.2 项目结构设计
```
lib/
├── core/              # 核心功能
│   ├── network/       # 网络请求封装
│   ├── storage/       # 本地存储
│   ├── utils/         # 工具类
│   └── constants/     # 常量定义
├── features/          # 功能模块
│   ├── chat/          # 聊天功能
│   ├── settings/      # 设置
│   └── models/        # 模型管理
├── shared/            # 共享组件
│   ├── widgets/       # UI 组件
│   └── themes/        # 主题
└── main.dart
```
- [x] 创建基础目录结构
- [x] 设置环境配置(开发/生产)

---

## 📋 Phase 2: 核心功能开发

### 2.1 OpenAI API 集成
- [x] 创建 API 客户端基类
- [x] 实现 OpenAI 格式 API 接口
  - [x] Chat Completions API
  - [x] Streaming 支持(SSE)
  - [x] Token 计数
  - [x] 错误处理和重试机制
- [x] 支持自定义 API 端点和 API Key
- [x] 实现多个 API 提供商配置
  - [x] OpenAI
  - [x] Azure OpenAI
  - [x] 其他兼容 OpenAI 格式的服务(如 Ollama、LocalAI)

### 2.2 数据模型设计
- [x] 定义核心数据模型
  - [x] `Message` - 消息模型
  - [x] `Conversation` - 会话模型
  - [x] `ApiConfig` - API 配置模型
  - [x] `ModelConfig` - 模型配置(temperature, max_tokens 等)
- [x] 使用 Freezed 生成不可变数据类
- [x] 实现 JSON 序列化/反序列化

### 2.3 本地存储
- [x] 设置 Hive 数据库
- [x] 实现会话历史存储
- [x] 实现 API 配置持久化
- [x] 实现用户偏好设置存储
- [x] 添加数据导入/导出功能

---

## 📋 Phase 3: 用户界面开发

### 3.1 主界面布局
- [x] 设计响应式布局(适配不同屏幕尺寸)
- [x] 实现侧边栏(会话列表)
  - [x] 会话创建/删除/重命名
  - [x] 会话搜索
  - [x] 会话分组/标签
- [x] 实现主聊天区域
  - [x] 消息列表显示
  - [x] 消息输入框
  - [x] 消息发送按钮
- [x] 实现设置面板

### 3.2 聊天功能
- [x] 消息渲染
  - [x] 支持 Markdown 格式
  - [x] 代码高亮显示
  - [x] 代码复制功能
  - [x] LaTeX 数学公式支持
- [x] 实时流式响应显示
- [x] 消息编辑/删除/重新生成
  - [x] 消息复制/分享
  - [x] 支持多模态输入(图片上传)

### 3.3 主题与样式
- [x] 实现亮色/暗色主题切换
- [x] 设计现代化 UI(参考 Cherry Studio)
- [x] 添加平滑动画和过渡效果
  - [x] 自定义主题颜色配置

---

## 📋 Phase 4: 高级功能

### 4.1 模型管理
- [x] 模型列表获取(通过 API)
- [x] 模型切换功能
- [x] 模型参数配置界面
  - [x] Temperature
  - [x] Max Tokens
  - [x] Top P
  - [x] Frequency Penalty
  - [x] Presence Penalty
- [x] 预设模板管理(System Prompt)

### 4.2 多会话管理
- [x] 支持多个会话同时存在
- [x] 会话间快速切换
- [x] 会话历史浏览
- [x] 会话导出(Markdown/PDF/JSON)

### 4.3 设置页面
- [x] API 配置管理
  - [x] 添加/编辑/删除 API 配置
  - [x] API Key 安全存储
  - [x] 连接测试功能
- [x] 通用设置
    - [x] 语言选择
    - [x] 主题选择
    - [x] 字体大小调整
  - [x] 快捷键配置(桌面端)

### 4.3 提示词模板管理
  - [x] 模板创建和编辑
  - [x] 模板分类管理
  - [x] 收藏和标签功能
  - [x] 模板搜索和筛选

---

## 📋 Phase 5: 平台特定优化

### 5.1 桌面端(Windows/macOS/Linux)
- [ ] 窗口管理(最小化到托盘)
- [ ] 原生菜单栏
- [x] 快捷键支持
- [x] 文件拖放支持
- [ ] 自动更新机制(可选)

### 5.2 移动端(iOS/Android)
- [x] 触摸手势优化
- [x] 移动端布局适配
- [ ] 分享扩展(iOS)/ Share Intent(Android)
- [ ] 键盘处理优化

### 5.3 Web 端
- [ ] PWA 支持
- [ ] 响应式设计优化
- [ ] URL 路由和深链接
- [ ] 浏览器存储优化

---

## 📋 Phase 6: MCP(Model Context Protocol)支持

### 6.1 MCP 基础实现
- [ ] 研究 MCP 协议规范
- [ ] 设计 MCP 客户端架构
- [ ] 实现 MCP 连接管理
- [ ] 实现上下文同步机制

### 6.2 MCP 功能集成
- [ ] 与现有聊天功能集成
- [ ] MCP 服务器配置界面
- [ ] 上下文提供者管理
- [ ] 调试和日志工具

---

## 📋 Phase 7: Agent 功能支持

### 7.1 Agent 架构设计
- [ ] 设计 Agent 系统架构
- [ ] 实现工具/函数调用机制
- [ ] 创建插件系统基础框架

### 7.2 内置 Agent 工具
- [ ] 网络搜索工具
- [ ] 代码执行工具(沙盒环境)
- [ ] 文件操作工具
- [ ] 计算器/数据分析工具

### 7.3 自定义 Agent
- [ ] Agent 创建界面
- [ ] 工具配置和管理
- [ ] Agent 模板库
- [ ] Agent 执行流程可视化

---

## 📋 Phase 8: 测试与优化

### 8.1 单元测试
- [ ] API 客户端测试
- [ ] 数据模型测试
- [ ] 业务逻辑测试
- [ ] 存储层测试

### 8.2 集成测试
- [ ] 端到端流程测试
- [ ] 多平台兼容性测试

### 8.3 性能优化
- [ ] 消息列表性能优化(虚拟滚动)
- [ ] 内存使用优化
- [ ] 网络请求优化(缓存、并发控制)
- [ ] 应用启动速度优化

### 8.4 用户体验优化
- [ ] 加载状态优化
- [ ] 错误提示优化
- [ ] 离线功能支持
- [ ] 无障碍功能(Accessibility)

---

## 📋 Phase 9: 文档与发布

### 9.1 文档编写
- [ ] 用户使用文档
- [ ] API 集成指南
- [ ] 开发者文档
- [ ] README 和贡献指南

### 9.2 应用发布
- [ ] 准备应用商店素材(截图、描述)
- [ ] iOS App Store 发布
- [ ] Google Play Store 发布
- [ ] Windows/macOS/Linux 安装包
- [ ] Web 版本部署

### 9.3 持续维护
- [ ] 用户反馈收集机制
- [ ] Bug 追踪系统
- [ ] 版本更新计划
- [ ] 社区建设

---

## 🔧 技术栈建议

### 核心依赖
- **状态管理**: Riverpod 2.x
- **路由**: go_router
- **网络**: dio + retrofit
- **数据库**: isar(高性能)或 hive(简单易用)
- **代码生成**: freezed + json_serializable + build_runner

### UI 组件
- **Markdown**: flutter_markdown
- **代码高亮**: flutter_highlight
- **图标**: flutter_svg
- **动画**: animations package

### 平台特定
- **桌面**: window_manager, tray_manager
- **文件选择**: file_picker
- **安全存储**: flutter_secure_storage
- **分享**: share_plus

---

## 📝 注意事项

1. **安全性**
   - API Key 必须加密存储
   - 考虑实现本地加密聊天历史
   - 添加数据清除功能

2. **用户体验**
   - 保持界面简洁直观
   - 提供详细的错误提示
   - 实现优雅的加载状态

3. **性能**
   - 长对话列表需要优化渲染
   - 大文件/图片上传需要进度提示
   - 考虑实现消息分页加载

4. **扩展性**
   - 保持代码模块化
   - 使用依赖注入便于测试
   - 为 MCP 和 Agent 功能预留接口

---

## 🎯 里程碑

- **M1 (Week 1-2)**: 项目搭建 + 基础 OpenAI API 集成
- **M2 (Week 3-4)**: 基础聊天界面 + 本地存储
- **M3 (Week 5-6)**: 完整聊天功能 + 多平台适配
- **M4 (Week 7-8)**: 高级功能 + 设置页面
- **M5 (Week 9-10)**: MCP 支持(基础)
- **M6 (Week 11-12)**: Agent 功能 + 测试优化
- **M7 (Week 13-14)**: 文档完善 + 发布准备

---

**开始日期**: _待填写_  
**预计完成**: _待填写_  
**当前阶段**: Phase 1 - 项目初始化
