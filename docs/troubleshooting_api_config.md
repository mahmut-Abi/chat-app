# API 配置问题诊断指南

## 问题：已配置并激活 API，但仍然提示"未配置 API"

### 诊断步骤

#### 1. 检查调试日志

现在代码中已经添加了详细的调试日志，请按以下步骤检查：

1. 在 Debug 模式下运行应用：
   ```bash
   flutter run -d chrome  # Web
   flutter run -d macos   # macOS
   ```

2. 尝试发送消息时，查看控制台输出，应该看到类似以下日志：

   ```
   StorageService.getAllApiConfigs: 检查所有 keys...
     总 key 数: X
     key: api_config_xxx
       -> 找到 API 配置 key
       -> data: {...}
   StorageService.getAllApiConfigs: 找到 X 个配置
   
   SettingsRepository.getActiveApiConfig: 开始检查...
   SettingsRepository.getActiveApiConfig: 找到 X 个配置
     - 配置名称 (id: xxx, isActive: true/false)
   
   ChatScreen: 检查 API 配置...
   ChatScreen: activeApiConfig = ApiConfig(...)
   ChatScreen: activeApiConfig.isActive = true
   ```

#### 2. 可能的问题和解决方案

##### 问题 A: 没有找到任何 API 配置

**日志表现：**
```
StorageService.getAllApiConfigs: 找到 0 个配置
SettingsRepository.getActiveApiConfig: 找到 0 个配置
```

**原因：** API 配置没有正确保存到存储

**解决方法：**
1. 重新进入设置页面
2. 重新创建一个 API 配置
3. 确保点击"保存"按钮
4. 检查是否有错误提示

##### 问题 B: 找到了配置但都是 isActive: false

**日志表现：**
```
SettingsRepository.getActiveApiConfig: 找到 1 个配置
  - My API (id: xxx, isActive: false)
```

**原因：** API 配置存在但没有被激活

**解决方法：**
1. 进入设置页面
2. 找到你的 API 配置
3. 点击激活按钮（通常是一个开关或单选按钮）
4. 确保配置变为激活状态

##### 问题 C: 配置存在且激活，但仍然报错

**日志表现：**
```
SettingsRepository.getActiveApiConfig: 找到 1 个配置
  - My API (id: xxx, isActive: true)
ChatScreen: activeApiConfig = null
```

**原因：** Provider 缓存或状态管理问题

**解决方法：**
1. 完全关闭应用并重新启动
2. 清除浏览器缓存（如果是 Web）
3. 如果问题持续，可能需要清除应用数据：
   ```bash
   # 删除 Hive 数据库文件
   rm -rf ~/Library/Application\ Support/com.aichat.app/  # macOS
   ```
   然后重新配置 API

##### 问题 D: Storage key 前缀不匹配

**日志表现：**
```
StorageService.getAllApiConfigs: 检查所有 keys...
  总 key 数: 5
  key: some_other_key
  key: another_key
StorageService.getAllApiConfigs: 找到 0 个配置
```

**原因：** 存储的 key 格式可能不正确

**解决方法：**
请将完整的日志发送给开发者，这可能是代码 bug

### 3. 手动验证数据库

如果以上步骤都无法解决，可以检查 Hive 数据库：

```dart
// 在开发模式下，可以在 main.dart 中临时添加这段代码查看所有存储的数据
if (kDebugMode) {
  final storage = StorageService();
  await storage.init();
  final configs = await storage.getAllApiConfigs();
  print("所有 API 配置: $configs");
}
```

### 4. 联系支持

如果问题仍未解决，请提供：
1. 完整的控制台日志（从启动到发送消息）
2. 你的操作步骤
3. 应用运行的平台（Web/macOS/Windows 等）
