# Bug #039: MCP 选择器显示为空

**日期**: 2025-01-18  
**状态**: 🔍 诊断中  
**优先级**: 高  
**影响范围**: 对话界面 - MCP 选择功能

---

## 问题描述

在对话界面点击选择 MCP 时，弹出的选择器显示为空，即使已经在设置中配置了 MCP。

### 用户报告
> "在对话界面，选择mcp的页面一直为空，哪怕已经设置了mcp"

### 复现步骤
1. 在设置中配置 MCP 服务器
2. 返回对话界面
3. 点击功能菜单 → 选择 MCP
4. 弹出的对话框显示"暂无MCP配置"

---

## 代码分析

### 相关文件
1. `lib/features/chat/presentation/widgets/chat_function_menu.dart` - MCP 选择器 UI
2. `lib/features/mcp/data/mcp_repository.dart` - MCP 数据仓库
3. `lib/core/providers/providers.dart` - MCP Provider 定义

### 当前实现

#### MCP 选择器代码（chat_function_menu.dart）
```dart
Future<void> _showMcpSelector() async {
  // 强制刷新 MCP 列表，确保获取最新数据
  if (kDebugMode) {
    print('[ChatFunctionMenu] 开始显示 MCP 选择器');
  }
  ref.invalidate(mcpConfigsProvider);

  // 等待 MCP 列表加载完成
  if (kDebugMode) {
    print('[ChatFunctionMenu] 等待 MCP 列表加载...');
  }
  final mcpsAsync = await ref.read(mcpConfigsProvider.future);
  final mcps = mcpsAsync;
  if (kDebugMode) {
    print('[ChatFunctionMenu] MCP 列表加载完成: ${mcps.length} 个配置');
    for (final mcp in mcps) {
      print('[ChatFunctionMenu]   - ${mcp.name} (enabled: ${mcp.enabled})');
    }
  }
  // ... 显示对话框
}
```

#### MCP Provider 定义（providers.dart）
```dart
final mcpConfigsProvider = FutureProvider.autoDispose<List<McpConfig>>((ref,) async {
  final repository = ref.watch(mcpRepositoryProvider);
  return await repository.getAllConfigs();
});
```

#### MCP Repository（mcp_repository.dart）
```dart
Future<List<McpConfig>> getAllConfigs() async {
  _log.info('开始获取所有 MCP 配置');
  if (kDebugMode) {
    print('[McpRepository] 开始获取所有 MCP 配置');
  }
  try {
    final keys = await _storage.getAllKeys();
    final mcpKeys = keys.where((k) => k.startsWith('mcp_config_')).toList();
    
    final configs = <McpConfig>[];
    for (final key in mcpKeys) {
      final data = _storage.getSetting(key);
      if (data != null) {
        try {
          // 支持两种格式: 字符串(新) 和 Map(旧)
          final Map<String, dynamic> json;
          if (data is String) {
            json = jsonDecode(data) as Map<String, dynamic>;
          } else if (data is Map<String, dynamic>) {
            json = data;
          } else {
            continue;
          }
          configs.add(McpConfig.fromJson(json));
        } catch (e) {
          _log.warning('解析 MCP 配置失败', {'key': key, 'error': e.toString()});
        }
      }
    }
    return configs;
  } catch (e) {
    _log.error('获取 MCP 配置异常: ${e.toString()}', e, StackTrace.current);
    return [];
  }
}
```

---

## 诊断思路

### 1. 检查数据保存
问题可能出现在：
- MCP 配置保存时的键名格式
- 数据序列化/反序列化
- 存储服务的实现

### 2. 检查数据读取
- `getAllKeys()` 是否正确返回所有键
- 键名过滤逻辑是否正确
- 数据格式转换是否正确

### 3. 检查 Provider 刷新
- `ref.invalidate()` 是否正确触发
- Provider 的 autoDispose 是否影响数据获取

---

## 调试建议

### 启用调试日志
代码中已经包含了详细的调试日志，运行时查看控制台输出：

```dart
// 在 MCP 选择器中
[ChatFunctionMenu] 开始显示 MCP 选择器
[ChatFunctionMenu] 等待 MCP 列表加载...
[ChatFunctionMenu] MCP 列表加载完成: X 个配置

// 在 Repository 中
[McpRepository] 开始获取所有 MCP 配置
[McpRepository] 存储中的所有键: [...]
[McpRepository] MCP 配置键: [...]
[McpRepository] 返回 X 个配置
```

### 手动测试步骤

1. **添加 MCP 配置**
```dart
// 在设置界面保存后，检查日志
[McpRepository] 添加 MCP 配置: TestMCP
[McpRepository]   ID: xxx-xxx-xxx
[McpRepository]   存储键: mcp_config_xxx-xxx-xxx
[McpRepository] MCP 配置已保存到存储
[McpRepository] 验证保存: 成功
```

2. **读取 MCP 配置**
```dart
// 在选择器中，检查读取的配置数量
[McpRepository] 返回 1 个配置  // 应该 > 0
```

3. **检查存储键**
```dart
// 在 StorageService 中添加日志
print('所有存储键: ${await getAllKeys()}');
// 应该包含 mcp_config_xxx 这样的键
```

---

## 可能的原因

### 原因 1: 存储服务实现问题
`StorageService.getAllKeys()` 可能没有正确返回所有键。

**验证方法**:
```dart
final storage = StorageService();
final keys = await storage.getAllKeys();
print('所有键: $keys');
```

### 原因 2: 数据格式不匹配
保存和读取时使用的数据格式不一致。

**验证方法**:
```dart
// 保存后立即读取
final saved = storage.getSetting('mcp_config_xxx');
print('保存的数据类型: ${saved.runtimeType}');
print('保存的数据内容: $saved');
```

### 原因 3: Provider 缓存问题
`autoDispose` Provider 可能在刷新时出现问题。

**验证方法**:
尝试不使用 `autoDispose`:
```dart
final mcpConfigsProvider = FutureProvider<List<McpConfig>>((ref,) async {
  final repository = ref.watch(mcpRepositoryProvider);
  return await repository.getAllConfigs();
});
```

### 原因 4: 异步时序问题
配置保存和读取之间可能存在时序问题。

**验证方法**:
在选择器打开前添加延迟：
```dart
await Future.delayed(Duration(milliseconds: 100));
ref.invalidate(mcpConfigsProvider);
```

---

## 临时解决方案

### 方案 1: 添加刷新按钮
在 MCP 选择对话框中添加手动刷新按钮：

```dart
AlertDialog(
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('选择MCP'),
      IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () async {
          ref.invalidate(mcpConfigsProvider);
          Navigator.pop(context);
          await Future.delayed(Duration(milliseconds: 100));
          _showMcpSelector();
        },
      ),
    ],
  ),
  // ...
)
```

### 方案 2: 直接从 Repository 读取
不使用 Provider，直接从 Repository 读取：

```dart
Future<void> _showMcpSelector() async {
  final repository = ref.read(mcpRepositoryProvider);
  final mcps = await repository.getAllConfigs();
  
  if (!mounted) return;
  // 显示对话框...
}
```

---

## 下一步行动

### 立即执行
1. ✅ 创建此 Bug 报告文档
2. [ ] 运行应用并查看调试日志
3. [ ] 确定具体原因
4. [ ] 实施修复方案

### 需要信息
1. 控制台的完整调试日志
2. 存储服务的实现细节
3. 保存 MCP 配置时的日志

### 测试清单
- [ ] 保存 MCP 配置后能否立即在选择器中看到
- [ ] 重启应用后 MCP 配置是否持久化
- [ ] 多个 MCP 配置是否都能正确显示
- [ ] Agent 选择器是否有相同问题

---

## 相关 Bug

- Bug #036: 配置保存后未立即生效（已修复）
- Bug #037: iOS 端配置持久化问题（已修复）
- Bug #028: MCP Agent 持久化（已修复）

这些问题都与数据持久化和刷新有关，可能有共同的根本原因。

---

**更新时间**: 2025-01-18  
**负责人**: 待分配  
**预计工作量**: 2-4 小时
