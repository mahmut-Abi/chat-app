# MCP 快速开始指南

本指南帮助你快速上手 Model Context Protocol (MCP) 功能。

## 📋 什么是 MCP？

**Model Context Protocol (MCP)** 是一个开放协议，允许 AI 应用与外部工具和数据源通信。

### MCP 的优势

- 🔌 **标准化接口** - 统一的协议，易于集成
- 🛠️ **丰富工具** - 接入各种外部服务和API
- 🔄 **双向通信** - 支持工具调用和资源访问
- 🎯 **灵活配置** - HTTP 和 Stdio 两种模式

## 🚀 快速开始

### 方式一：使用示例配置（推荐新手）

应用已预置了一个快速开始配置，开箱即用：

1. **打开 MCP 设置**
   ```
   设置 → MCP 服务器
   ```

2. **查看快速开始配置**
   - 配置名称：快速开始 - Echo 服务器
   - 类型：HTTP
   - 端点：http://localhost:3000

3. **启动测试服务器**（参见下方"测试服务器"部分）

4. **启用并连接**
   - 点击配置旁的开关启用
   - 点击"连接"按钮

5. **开始使用**
   - 在聊天中选择支持 MCP 的 Agent
   - AI 将自动调用 MCP 工具

### 方式二：手动添加配置

#### HTTP 模式配置

适用于 RESTful API 服务器：

```yaml
名称: 我的 HTTP 服务器
连接类型: HTTP
端点: https://api.example.com/v1
描述: 自定义 HTTP MCP 服务器
Headers (可选):
  Content-Type: application/json
  Authorization: Bearer YOUR_TOKEN
```

#### Stdio 模式配置

适用于本地进程通信：

```yaml
名称: 我的 Stdio 服务器
连接类型: Stdio
命令: /usr/bin/node
参数: ["server.js"]
工作目录: /path/to/server
环境变量 (可选):
  NODE_ENV: production
```

## 🧪 测试服务器

### Node.js Echo 服务器

创建一个简单的测试服务器验证 MCP 功能：

**1. 创建 `mcp-server.js`:**

```javascript
const express = require('express');
const app = express();
app.use(express.json());

// MCP 初始化
app.post('/initialize', (req, res) => {
  res.json({
    protocolVersion: '1.0',
    serverInfo: {
      name: 'Echo Server',
      version: '1.0.0',
    },
    capabilities: {
      tools: true,
    },
  });
});

// 列出可用工具
app.post('/tools/list', (req, res) => {
  res.json({
    tools: [
      {
        name: 'echo',
        description: 'Echo back the input message',
        inputSchema: {
          type: 'object',
          properties: {
            message: {
              type: 'string',
              description: 'The message to echo',
            },
          },
          required: ['message'],
        },
      },
    ],
  });
});

// 调用工具
app.post('/tools/call', (req, res) => {
  const { name, arguments: args } = req.body;
  
  if (name === 'echo') {
    res.json({
      content: [
        {
          type: 'text',
          text: `Echo: ${args.message}`,
        },
      ],
    });
  } else {
    res.status(404).json({ error: 'Tool not found' });
  }
});

app.listen(3000, () => {
  console.log('MCP Echo Server running on http://localhost:3000');
});
```

**2. 安装依赖并启动:**

```bash
npm install express
node mcp-server.js
```

**3. 测试连接:**

```bash
# 测试初始化
curl -X POST http://localhost:3000/initialize \
  -H "Content-Type: application/json" \
  -d '{}'

# 测试工具列表
curl -X POST http://localhost:3000/tools/list \
  -H "Content-Type: application/json" \
  -d '{}'

# 测试工具调用
curl -X POST http://localhost:3000/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name":"echo","arguments":{"message":"Hello MCP!"}}'
```

### Python Echo 服务器

**创建 `mcp_server.py`:**

```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/initialize', methods=['POST'])
def initialize():
    return jsonify({
        'protocolVersion': '1.0',
        'serverInfo': {
            'name': 'Echo Server',
            'version': '1.0.0',
        },
        'capabilities': {
            'tools': True,
        },
    })

@app.route('/tools/list', methods=['POST'])
def list_tools():
    return jsonify({
        'tools': [
            {
                'name': 'echo',
                'description': 'Echo back the input message',
                'inputSchema': {
                    'type': 'object',
                    'properties': {
                        'message': {
                            'type': 'string',
                            'description': 'The message to echo',
                        },
                    },
                    'required': ['message'],
                },
            },
        ],
    })

@app.route('/tools/call', methods=['POST'])
def call_tool():
    data = request.json
    name = data.get('name')
    args = data.get('arguments', {})
    
    if name == 'echo':
        return jsonify({
            'content': [
                {
                    'type': 'text',
                    'text': f"Echo: {args.get('message', '')}",
                },
            ],
        })
    else:
        return jsonify({'error': 'Tool not found'}), 404

if __name__ == '__main__':
    app.run(port=3000, debug=True)
```

**启动服务器:**

```bash
pip install flask
python mcp_server.py
```

## 📖 使用 MCP

### 在聊天中使用

1. **选择支持 MCP 的 Agent**（如研究助手、编程助手）
2. **发送需要外部工具的请求**
3. **AI 自动调用 MCP 工具**
4. **获得增强的回答**

### 示例对话

```
你: 使用 echo 工具发送 "Hello World"

AI: 好的，让我调用 echo 工具...
    [调用 MCP 工具: echo]
    结果: Echo: Hello World
```

## 🔧 高级配置

### HTTP Headers

为 HTTP MCP 服务器添加自定义 Headers：

```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer YOUR_API_KEY",
  "X-Custom-Header": "value"
}
```

### 环境变量

为 Stdio MCP 服务器配置环境变量：

```json
{
  "NODE_ENV": "production",
  "API_KEY": "your-key",
  "DEBUG": "true"
}
```

### 工作目录

Stdio 模式可以指定工作目录：

```
工作目录: /path/to/your/server
命令: node
参数: ["index.js"]
```

## 🎯 实际应用场景

### 1. 天气查询

```yaml
名称: 天气 API
类型: HTTP
端点: https://api.weatherapi.com/v1
Headers:
  key: YOUR_API_KEY
```

**工具**:
- `get_weather` - 获取实时天气
- `get_forecast` - 获取天气预报

### 2. 数据库查询

```yaml
名称: 数据库服务器
类型: Stdio
命令: python3
参数: ["db_server.py"]
环境变量:
  DB_HOST: localhost
  DB_PORT: 5432
```

**工具**:
- `query` - 执行 SQL 查询
- `schema` - 获取表结构

### 3. 文件处理

```yaml
名称: 文件处理器
类型: Stdio
命令: node
参数: ["file-processor.js"]
```

**工具**:
- `read_file` - 读取文件
- `write_file` - 写入文件
- `list_dir` - 列出目录

### 4. API 集成

```yaml
名称: GitHub API
类型: HTTP
端点: https://api.github.com
Headers:
  Accept: application/vnd.github.v3+json
  Authorization: token YOUR_GITHUB_TOKEN
```

**工具**:
- `create_issue` - 创建 Issue
- `search_repos` - 搜索仓库
- `get_user` - 获取用户信息

## ❓ 常见问题

### Q1: 连接失败怎么办？

**检查清单**:
- ✅ 服务器是否正在运行
- ✅ 端点 URL 是否正确
- ✅ 网络是否通畅
- ✅ 端口是否被占用
- ✅ 防火墙是否阻止

**解决方案**:
```bash
# 测试服务器
curl http://localhost:3000/initialize

# 查看日志
设置 → 日志 → MCP 日志
```

### Q2: 工具调用失败？

**可能原因**:
- 工具名称不匹配
- 参数格式错误
- 权限不足
- API 限流

**调试方法**:
1. 查看 MCP 日志
2. 测试工具端点
3. 检查参数格式

### Q3: Stdio 模式无法启动？

**检查**:
- 命令路径是否正确
- 文件是否有执行权限
- 依赖是否已安装
- 工作目录是否存在

**示例**:
```bash
# 检查命令
which node  # /usr/bin/node
which python3  # /usr/bin/python3

# 赋予执行权限
chmod +x server.js

# 测试运行
node server.js
```

### Q4: 如何调试 MCP 通信？

**方法**:
1. **启用详细日志**
   ```
   设置 → 日志 → 日志级别 → Debug
   ```

2. **查看网络请求**
   - 浏览器开发者工具
   - Network 标签页

3. **测试端点**
   ```bash
   # 使用 curl 测试
   curl -v http://localhost:3000/tools/list
   ```

## 📚 相关资源

### 官方文档
- [MCP 协议规范](https://modelcontextprotocol.io/)
- [MCP 集成指南](mcp-integration.md)
- [API 文档](api.md)

### 示例项目
- [MCP Server Examples](https://github.com/modelcontextprotocol/servers)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)

### 社区资源
- [MCP Discord](https://discord.gg/mcp)
- [MCP GitHub Discussions](https://github.com/modelcontextprotocol/discussions)

## 🎓 下一步

1. ✅ 完成快速开始
2. 📖 阅读 [MCP 集成指南](mcp-integration.md)
3. 🔧 创建自己的 MCP 服务器
4. 🚀 集成更多外部服务

---

**祝你使用愉快！** 🎉

如有问题，请查看 [故障排查指南](mcp-integration.md#故障排查) 或提交 Issue。
