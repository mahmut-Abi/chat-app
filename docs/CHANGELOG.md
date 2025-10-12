# 更新日志

## [未发布] - 2024-01-XX

### 新增功能

#### 多模态输入支持
- ✅ 图片上传功能
  - 支持选择多张图片
  - 实时预览已选图片
  - 自动转换为 base64 格式
  - 支持 JPEG、PNG、GIF、WebP 格式

#### 主题系统增强
- ✅ 自定义主题颜色
  - 9种预定义配色方案
  - 颜色选择器界面
  - 动态主题切换
  - 配色方案：indigo、purple、blue、cyan、teal、green、orange、red、pink

#### 提示词模板管理
- ✅ 完整的模板管理系统
  - 创建、编辑、删除模板
  - 分类和标签组织
  - 收藏功能
  - 模板搜索和筛选
  - 快速使用模板

#### 快捷键系统
- ✅ 桌面端快捷键支持
  - Ctrl+N: 新建对话
  - Ctrl+F: 搜索
  - Ctrl+,: 打开设置
  - Ctrl+Enter: 发送消息
  - Ctrl+W: 关闭当前对话

### 改进
- 🔧 修复代码分析警告
  - 更新已弃用的 API 调用
  - 改进类型注解
  - 统一使用 `withValues` 替代 `withOpacity`
  - 修复 SharePlus API 使用

- 🧪 增强测试覆盖
  - 添加 ImageUtils 单元测试
  - 验证图片类型识别
  - 验证 MIME 类型转换
  - 所有测试通过 (16/16)

### 技术细节

#### 数据模型更新
```dart
// Message 模型新增图片支持
class Message {
  ...
  final List<ImageAttachment>? images;
}

// 新增 ImageAttachment 模型
class ImageAttachment {
  final String path;
  final String? base64Data;
  final String? mimeType;
}

// AppSettings 新增主题配置
class AppSettings {
  ...
  final String? themeColor;
  final int? customThemeColor;
}
```

#### 新增仓库
- `PromptsRepository`: 提示词模板管理
- 存储服务扩展: 支持模板持久化

#### 工具类
- `ImageUtils`: 图片处理工具
  - 图片选择
  - Base64 转换
  - MIME 类型识别
  - 文件大小计算

### 构建状态
- ✅ macOS 构建成功
- ✅ 所有单元测试通过
- ✅ 代码分析通过（仅剩 info 级别警告）

### 下一步计划

#### Phase 5: 平台特定优化
- [ ] 桌面端窗口管理
- [ ] 移动端布局适配
- [ ] PWA 支持

#### Phase 6: MCP 支持
- [ ] MCP 协议集成
- [ ] 上下文同步
- [ ] 服务器配置

#### Phase 7: Agent 功能
- [ ] 工具调用机制
- [ ] 插件系统
- [ ] 内置工具集

#### Phase 8: 性能优化
- [ ] 虚拟滚动
- [ ] 内存优化
- [ ] 启动速度优化

---

## 提交历史

### 2024-01-XX
- `9274cb9` chore(ios): 更新 iOS Bundle Identifier
- `9c49b65` feat: 完成核心功能实现
  - 图片上传多模态输入
  - 自定义主题颜色配置
  - 提示词模板管理系统
  - 快捷键系统
  - 代码质量改进
  - 单元测试增强
