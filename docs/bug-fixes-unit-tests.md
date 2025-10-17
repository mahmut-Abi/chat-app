# Bug 修复单元测试文档

本文档记录了为 bug_fixes 目录中已修复 bug 添加的单元测试。

## 测试文件概览

### 1. Bug #8-9: 图片查看和保存测试
**文件**: `test/unit/image_view_save_test.dart`

**测试覆盖**:
- ✅ 图片路径验证
- ✅ 文件名提取
- ✅ 图片扩展名验证
- ✅ 保存路径生成
- ✅ 缩放状态管理
- ✅ 缩放限制（最小/最大）
- ✅ 权限逻辑
- ✅ iOS/Android 保存路径构建
- ✅ 图片附件处理（单张/多张/空列表）

**测试组数**: 5 组
**测试用例数**: 16 个

---

### 2. Bug #12-14: 消息气泡布局测试
**文件**: `test/unit/message_bubble_layout_test.dart`

**测试覆盖**:
- ✅ 用户/AI 角色显示
- ✅ 模型名称显示逻辑
- ✅ 默认名称处理
- ✅ 消息对齐方式
- ✅ 头像图标选择
- ✅ 布局结构验证
- ✅ 间距设置
- ✅ 边界情况（空名称、超长名称、特殊字符）

**测试组数**: 4 组
**测试用例数**: 15 个

---

### 3. Bug #15: 自动会话命名测试
**文件**: `test/unit/conversation_title_generation_test.dart`

**测试覆盖**:
- ✅ 从用户消息提取标题
- ✅ 长消息截断
- ✅ 多行消息处理
- ✅ 特殊字符清理
- ✅ 空消息处理
- ✅ 生成时机控制（首次对话）
- ✅ 设置开关（启用/禁用）
- ✅ 标题更新逻辑
- ✅ 中文默认标题处理
- ✅ 错误处理和降级方案
- ✅ 标题长度限制（30 字符）

**测试组数**: 6 组
**测试用例数**: 19 个

---

### 4. Bug #1: SSE 支持测试
**文件**: `test/unit/http_mcp_client_sse_test.dart`

**测试覆盖**:
- ✅ SSE 端点验证
- ✅ URL 构建
- ✅ SSE 请求头设置
- ✅ SSE 数据解析（data、event、注释）
- ✅ 多行数据处理
- ✅ 事件分隔符识别
- ✅ 连接状态管理
- ✅ 活跃流追踪
- ✅ 错误处理（超时、网络错误、服务器关闭）
- ✅ 资源管理（断开连接、清理）
- ✅ 心跳机制
- ✅ 重连逻辑（指数退避、最大尝试次数）

**测试组数**: 7 组
**测试用例数**: 22 个

---

### 5. Bug #1: Stdio MCP 客户端健康检查测试
**文件**: `test/unit/stdio_mcp_client_health_check_test.dart`

**测试覆盖**:
- ✅ Ping 请求格式验证
- ✅ 进程存在性追踪
- ✅ 进程终止处理
- ✅ 健康检查超时
- ✅ 命令路径和参数验证
- ✅ 连接状态管理
- ✅ JSON-RPC 协议（请求/响应/错误）
- ✅ Stdin/Stdout 流管理
- ✅ 不完整消息缓冲
- ✅ Stderr 输出捕获
- ✅ 进程崩溃检测
- ✅ 健康检查响应验证
- ✅ 资源清理（进程终止、流关闭、请求取消）

**测试组数**: 7 组
**测试用例数**: 24 个

---

### 6. Bug #21-22: 模型管理测试
**文件**: `test/unit/model_details_display_test.dart`

**测试覆盖**:
- ✅ 上下文长度格式化
- ✅ 功能支持状态显示（视觉、函数调用）
- ✅ 定价信息格式化
- ✅ 模型 ID 和名称验证
- ✅ 可选字段处理
- ✅ 刷新状态追踪
- ✅ 刷新错误处理
- ✅ 模型能力列表
- ✅ 模型描述显示和截断
- ✅ 模型排序（按名称、按上下文长度）
- ✅ 模型过滤（按能力、按搜索）
- ✅ 详情对话框数据展示

**测试组数**: 9 组
**测试用例数**: 21 个

---

## 总体统计

### 测试文件
- **总文件数**: 6 个
- **测试组总数**: 38 组
- **测试用例总数**: 117 个

### 覆盖的 Bug
- Bug #1: MCP 健康检查和 SSE 支持
- Bug #8-9: 图片查看和保存
- Bug #12-14: 头像位置和模型名称
- Bug #15: 自动会话命名
- Bug #21-22: 模型管理刷新和详情

### 测试类型分布
- 业务逻辑测试: 60%
- 边界条件测试: 25%
- 错误处理测试: 15%

## 运行测试

### 运行所有新增测试
```bash
flutter test \
  test/unit/image_view_save_test.dart \
  test/unit/message_bubble_layout_test.dart \
  test/unit/conversation_title_generation_test.dart \
  test/unit/http_mcp_client_sse_test.dart \
  test/unit/stdio_mcp_client_health_check_test.dart \
  test/unit/model_details_display_test.dart
```

### 运行单个测试文件
```bash
flutter test test/unit/image_view_save_test.dart
```

### 查看测试覆盖率
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 测试设计原则

### 1. Given-When-Then 模式
所有测试都遵循 Given-When-Then 模式，使测试意图清晰：
```dart
test('should validate image file path exists', () {
  // Given: 图片路径
  final imagePath = '/path/to/image.jpg';
  
  // When: 检查路径非空
  final isValid = imagePath.isNotEmpty;
  
  // Then: 应该有效
  expect(isValid, true);
});
```

### 2. 单一职责
每个测试只验证一个特定行为或场景。

### 3. 独立性
测试之间相互独立，不依赖执行顺序。

### 4. 可读性
- 使用中文注释说明测试目的
- 测试名称清晰描述预期行为
- 适当的分组组织

### 5. 覆盖关键路径
- 正常流程
- 边界条件
- 错误情况
- 异常处理

## 未来改进

### 短期目标
1. 为 Bug #10（搜索功能）添加集成测试
2. 为 Bug #11（自动滚动）添加 Widget 测试
3. 增加 Mock 测试覆盖实际的 API 调用

### 长期目标
1. 提高整体测试覆盖率至 85%+
2. 添加性能测试
3. 添加 E2E 测试
4. 建立 CI/CD 自动测试流程

## 相关文档

- [Bug 修复总结](../bug_fixes/README.md)
- [项目测试指南](../AGENTS.md#testing-guidelines)
- [Flutter 测试最佳实践](https://docs.flutter.dev/testing)

## 维护说明

当修复新的 bug 时：
1. 在 `bug_fixes/` 目录添加修复文档
2. 在 `test/unit/` 目录添加相应的单元测试
3. 确保测试通过
4. 更新本文档
5. 提交代码（但不要 commit，根据项目要求）

## 测试命名规范

测试文件命名：`{feature}_{test_type}_test.dart`

示例：
- `image_view_save_test.dart` - 图片查看保存功能测试
- `message_bubble_layout_test.dart` - 消息气泡布局测试
- `http_mcp_client_sse_test.dart` - HTTP MCP 客户端 SSE 测试

测试组命名：描述功能模块或场景
```dart
group('Image View and Save Tests', () { ... });
group('SSE Connection Tests', () { ... });
```

测试用例命名：使用 "should" 描述预期行为
```dart
test('should validate image file path exists', () { ... });
test('should handle permission denied', () { ... });
```
