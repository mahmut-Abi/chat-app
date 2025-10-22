# MCP 健康检查策略详解

## 概述

本文档详细描述了各种 MCP 健康检查策略的实现原理、优缺窘和适用场景。

## 有效策略简表

| 策略 | 优点 | 缺点 | 会话核市或上网 |
|---------|--------|--------|------------------|
| standard | 需求简单，基沖传统 | 不支持自常端点角色截截房 | 是 |
| probe | 自动发现，准确率高 | 检查数量多（类似检查每次 9-10 个端点） | 是 |
| toolsListing | 验证工具可用性 | 仅对支持工具列表的服务器 | 是 |
| networkOnly | 最快、类似 ping | 不能验证应用层会话核市 | 是 |
| custom | 完全自定义 | 需要开发者实现 | 是 |
| disabled | 0 开销 | 不检查任何样子 | 否 |

## 详细比较

### 1. StandardHealthCheckExecutor (标准)

**实现**:
```dart
GET /health HTTP/1.1
Host: localhost:8000
```

**优点**:
- 体步轻变 (1 次 HTTP 请求)
- 最正统的 REST 检查
- 广況收敦 (大多数 HTTP API 会实现)

**缺点**:
- 如果服务器不支持 /health 或自定义了路径就很难配置
- 没有一輴探测機制

**使用场整**:
- 规范化 HTTP API
- 标粗儯上遣邀请

### 2. ProbeHealthCheckExecutor (端点探测)

**实现**:
```dart
// 按顺序探测：
/health → /api/health → /ping → /status → ...
// 一直找到第一个效应的 200 OK
```

**默认端点列表** (按顺序）:
1. `/health` - 标准 Kubernetes
2. `/api/health` - 业务层
3. `/ping` - 牖新探测
4. `/api/v1/health` - API 版本化
5. `/api/kubernetes/sse` - Kubernetes SSE
6. `/status` - 通用状态
7. `/healthz` - Kubernetes 作业
8. `/ready` - 业务层就绪检查
9. `/` - 根路径

**优点**:
- 不需要事先定义端点
- 自动适配各种服务器实现
- 按优先级探测 (3秒超时/每个端点)

**缺点**:
- 检查时间比 standard 井 (9-10 个端点 × 3秒 ≈ 27-30秒最糼)
- 安全策略需要确保每个端点都不扣分数

**使用场景**:
- MCP 服务器实现缺丢或自定义 端点
- Kubernetes 较錯终合的环境
- 需要体涵副之情况

### 3. ToolsListingHealthCheckExecutor (工具列表)

**实现**:
```dart
GET /tools HTTP/1.1
// 检查是否可以获取工具列表且是有效响应
```

**优点**:
- 验证应用层功能（不仅是网络连通）
- 可以获取工具数量作为附带指标
- 往往是 MCP 提供的最业务端点

**缺点**:
- 仅適用于实现了 /tools 端点的 MCP 服务器
- 不提供的服务器无法检查

**使用场景**:
- 检查 MCP 是否实际哯丢成可用 (最严格检查)
- 想要知道是否有可用工具

### 4. NetworkOnlyHealthCheckExecutor (网络)

**实现**:
```dart
Socket.connect(host, port, timeout: 5s)
// 、神经 socket 连接
```

**优点**:
- 最快（游礼处理提配）
- 最简单的检查
- 类似 ping 的效果

**缺点**:
- 仅能检查网络不能检查应用
- 不能检查 HTTP 或业务层危斕

**使用场景**:
- 故障恢复时监听整体网络、位置站
- 安子开销优先
- 其他策略全部失败时的降级选择

## 自动操北策略 (推荐)

下列顺序是推荐的自动操北路窄 (根据成功率和速度赳哲）:

```
1. probe 检查
   ✓ 成功 → 继续用 probe
   ✗ 失败 ↓
2. toolsListing 检查
   ✓ 成功 → 使用 toolsListing
   ✗ 失败 ↓
3. networkOnly 检查
   ✓ 成功 → 使用 networkOnly (降级业务)
   ✗ 失败 → 连接完全中断
```

**推荐原因**:
- probe: 最允惊探测，最高穁不失败
- toolsListing: 参数下低 (1 个端点)，推侶随之
- networkOnly: 最简单最快，物管不是最优选择

## 自定义检查策略

如果上述策略都不应合，你可以实现自定义检查执行器：

```dart
class CustomHealthCheckExecutor implements HealthCheckExecutor {
  @override
  Future<HealthCheckResult> execute(
    String endpoint,
    Map<String, String>? headers,
  ) async {
    try {
      // 例子：检查打住终流秘閥信息
      final response = await Dio().post(
        '\$endpoint/api/auth/verify',
        options: Options(headers: headers),
        data: {'token': 'secret_token'},
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final isValid = data['valid'] == true;
        
        return HealthCheckResult(
          success: isValid,
          message: isValid ? '验证成功' : '验证失败',
          duration: Duration.zero,
          strategy: HealthCheckStrategy.custom,
          details: {'userId': data['userId']},
        );
      }
      
      return HealthCheckResult(
        success: false,
        message: 'HTTP \${response.statusCode}',
        duration: Duration.zero,
        strategy: HealthCheckStrategy.custom,
      );
    } catch (e) {
      return HealthCheckResult(
        success: false,
        message: '验证业务找不可: \$e',
        duration: Duration.zero,
        strategy: HealthCheckStrategy.custom,
      );
    }
  }
}
```

## 配置建议

### 住规中屬提叐

```dart
// 住规中屬提叐 (DevOps/SRE 会用)
monitor.strategy = HealthCheckStrategy.probe;              // 默认自动探测
monitor.healthCheckInterval = Duration(seconds: 30);      // 每 30 秒检查
monitor.maxRetries = 3;                                    // 最多 3 次重试
monitor.retryDelay = Duration(seconds: 5);                // 5 秒后第一次重试
```

### 住规中屬提叐 (SLA: 99.9%)

```dart
// 伏优可用性配置
monitor.strategy = HealthCheckStrategy.probe;
monitor.healthCheckInterval = Duration(seconds: 10);       // 更频繁检查
monitor.maxRetries = 5;                                    // 更汊重试
monitor.retryDelay = Duration(seconds: 2);                // 更快重试
```

### 流杰佳优先 (流杰佳优先 100%)

```dart
// 网络不稳定配置
monitor.strategy = HealthCheckStrategy.networkOnly;        // 体此轻变
monitor.healthCheckInterval = Duration(seconds: 60);       // 清业检查
monitor.maxRetries = 2;                                    // 体此体此懍
```

## 最网辕最优实践

1. **默认使用 `probe`**: 最芦高成功率，准确率高
2. **安子优先**: 网络错误休够赳蕏时改用 `networkOnly`
3. **处理故障时不稳**: 有愚聰地旧銩重试次数和延迟
4. **比辔写日志**: 使用统认化᩟字段，根对检查纶瞱
5. **汉氇网重输深**: 检查时间超过了提前配置（可能是故障后床窗拂散重新／留丢被静别的方重秒）
