# MCP 使用示例

## 简介

Model Context Protocol (MCP) 是一种协议，允许 AI 模型通过标准化的接口访问外部资源和服务。

## 快速开始

### 1. 添加 MCP 配置

在应用中点击 **MCP** 标签，然后点击 **添加配置**：

```yaml
名称: GitHub API
类型: HTTP
端点: https://api.github.com
API Key: ghp_your_token_here
描述: 访问 GitHub API 的 MCP 服务
```

### 2. 启用连接

配置保存后，切换 **启用** 开关连接到 MCP 服务。

### 3. 在对话中使用

连接成功后，AI 可以访问 MCP 服务提供的资源。

## 常见示例

### 示例 1: 文件系统访问

```yaml
名称: Local Filesystem
类型: Filesystem
路径: /Users/username/Documents
描述: 访问本地文档目录
```

**使用场景**：
- 让 AI 帮助整理文件
- 搜索和分析文档内容
- 生成文件列表报告

### 示例 2: 数据库访问

```yaml
名称: PostgreSQL Database
类型: Database
连接字符串: postgresql://user:password@localhost:5432/mydb
描述: 项目数据库访问
```

**使用场景**：
- 查询数据库并生成报告
- 分析数据趋势
- 生成 SQL 查询语句

### 示例 3: API 集成

```yaml
名称: Weather API
类型: HTTP
端点: https://api.openweathermap.org/data/2.5
API Key: your_api_key
描述: 获取天气信息
```

**使用场景**：
- 查询当前天气
- 获取未来几天预报
- 分析天气趋势

### 示例 4: 自定义服务

```yaml
名称: Custom Service
类型: Custom
端点: http://localhost:8080/mcp
描述: 自定义 MCP 服务
```

**使用场景**：
- 集成内部服务
- 访问私有 API
- 扩展自定义功能

## 最佳实践

### 安全性

1. **保护 API 密钥**
   - 不要分享包含 API Key 的配置
   - 定期轮换密钥
   - 使用最小权限原则

2. **访问控制**
   - 只启用必要的 MCP 服务
   - 限制文件系统访问范围
   - 定期检查连接状态

### 性能优化

1. **连接管理**
   - 及时断开不用的连接
   - 使用连接池管理多个请求
   - 设置合理的超时时间

2. **错误处理**
   - 实现重试机制
   - 记录错误日志
   - 提供明确的错误提示

## 故障排查

### 连接失败

1. **检查网络连接**
   - 确保可以访问目标端点
   - 检查防火墙设置
   - 验证代理配置

2. **验证凭据**
   - 确认 API Key 正确
   - 检查权限设置
   - 确认服务状态

### 性能问题

1. **请求超时**
   - 增加超时时间
   - 检查网络质量
   - 优化请求大小

2. **响应缓慢**
   - 启用缓存机制
   - 减少请求频率
   - 使用批量操作

## 高级用法

### 多 MCP 服务组合

可以同时启用多个 MCP 服务，让 AI 同时访问多个资源：

```
用户：从我的文档目录找到最新的报告，然后上传到 GitHub

AI 使用：
1. Filesystem MCP - 搜索文件
2. GitHub API MCP - 上传文件
```

### 自定义 MCP 服务开发

如果需要开发自己的 MCP 服务，请参考：
- [MCP 协议规范](https://modelcontextprotocol.org)
- [MCP SDK 文档](https://github.com/modelcontextprotocol)

## 参考资源

- [MCP 集成文档](./mcp-integration.md)
- [Agent 开发指南](./agent-development.md)
- [API 文档](./api.md)
