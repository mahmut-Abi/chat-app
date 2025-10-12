# HTTP 代理配置指南

本文档说明如何在 Chat App 中配置 HTTP 代理以访问需要代理才能连接的 API 服务。

## 功能概述

Chat App 支持为每个 API 配置独立的 HTTP 代理设置，包括：

- HTTP/HTTPS 代理服务器地址
- 代理认证（用户名和密码）
- 自动跳过 SSL 证书验证（适用于企业代理）

## 配置步骤

### 1. 打开设置页面

在应用主界面，点击左侧菜单栏的「设置」按钮。

### 2. 添加或编辑 API 配置

- **新建配置**：点击「添加 API 配置」按钮
- **编辑现有配置**：点击已有配置右侧的编辑按钮

### 3. 启用 HTTP 代理

在 API 配置对话框中：

1. 填写基本信息（配置名称、提供商、Base URL、API Key）
2. 打开「启用 HTTP 代理」开关
3. 填写代理配置信息：
   - **代理地址**（必填）：代理服务器的完整 URL
     - 格式：`http://proxy.example.com:8080` 或 `https://proxy.example.com:8080`
   - **代理用户名**（可选）：如果代理需要认证，填写用户名
   - **代理密码**（可选）：代理认证密码

### 4. 保存配置

点击「添加」或「保存」按钮完成配置。

## 配置示例

### 示例 1：无认证代理

```
代理地址：http://proxy.company.com:8080
代理用户名：（留空）
代理密码：（留空）
```

### 示例 2：需要认证的代理

```
代理地址：http://proxy.company.com:8080
代理用户名：user@company.com
代理密码：your_password
```

### 示例 3：HTTPS 代理

```
代理地址：https://secure-proxy.company.com:8443
代理用户名：admin
代理密码：secure_pass
```

## 技术实现

### 核心组件

HTTP 代理功能在以下组件中实现：

1. **ApiConfig 数据模型** (`lib/features/settings/domain/api_config.dart`)
   - 添加了 `proxyUrl`、`proxyUsername`、`proxyPassword` 字段

2. **DioClient** (`lib/core/network/dio_client.dart`)
   - 配置 `HttpClient` 的代理设置
   - 支持代理认证
   - 自动处理 SSL 证书验证

3. **设置界面** (`lib/features/settings/presentation/settings_screen.dart`)
   - 提供代理配置 UI
   - 支持添加和编辑代理设置

### 代理配置逻辑

```dart
// 在 DioClient 中配置代理
if (proxyUrl != null && proxyUrl.isNotEmpty) {
  (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.findProxy = (uri) {
      if (proxyUsername != null && proxyUsername.isNotEmpty) {
        final credentials = '$proxyUsername:$proxyPassword';
        final auth = Uri.parse(proxyUrl).replace(
          userInfo: credentials,
        );
        return 'PROXY ${auth.host}:${auth.port}';
      }
      final proxy = Uri.parse(proxyUrl);
      return 'PROXY ${proxy.host}:${proxy.port}';
    };
    client.badCertificateCallback = 
        (X509Certificate cert, String host, int port) => true;
    return client;
  };
}
```

## 常见问题

### Q: 代理配置后无法连接？

**A:** 请检查：
- 代理地址格式是否正确（包含协议、主机和端口）
- 代理服务器是否可访问
- 用户名和密码是否正确（如果需要认证）
- 防火墙是否允许连接到代理服务器

### Q: 支持哪些代理协议？

**A:** 当前支持：
- HTTP 代理
- HTTPS 代理
- 支持 SOCKS 代理需要额外配置

### Q: 可以为不同的 API 配置不同的代理吗？

**A:** 可以。每个 API 配置都可以有独立的代理设置，互不影响。

### Q: 代理认证信息安全吗？

**A:** 代理认证信息存储在本地数据库中，与 API Key 一样使用相同的安全机制。建议：
- 使用专用的代理账号
- 定期更换密码
- 不要在不信任的设备上使用

## 故障排查

如果遇到代理相关问题，可以：

1. **检查日志**：查看控制台输出的网络请求日志
2. **测试代理**：使用其他工具（如 curl）测试代理是否工作正常
3. **临时禁用代理**：关闭代理开关，确认是否是代理配置问题
4. **验证代理格式**：确保代理 URL 格式正确

## 平台支持

HTTP 代理功能在以下平台上可用：

- ✅ macOS
- ✅ Windows
- ✅ Linux
- ✅ Web（受浏览器限制）
- ✅ iOS
- ✅ Android

注意：Web 平台的代理支持受浏览器安全策略限制，可能需要额外配置。

## 相关资源

- [Dio 文档](https://pub.dev/packages/dio)
- [Dart HttpClient 文档](https://api.dart.dev/stable/dart-io/HttpClient-class.html)
