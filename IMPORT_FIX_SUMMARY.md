# 导入历史对话立即生效修复

## 问题描述

导入历史对话后，需要重启应用才能看到导入的对话。这是因为 `HomeScreen` 在 `initState()` 时加载数据到本地状态，之后不再更新。

## 根本原因

1. `HomeScreen` 使用本地状态变量 `_conversations` 和 `_groups`
2. 数据只在 `initState()` 时加载一次
3. 导入数据后虽然调用了 `ref.invalidate()`，但 `HomeScreen` 没有监听这些变化

## 解决方案

在 `HomeScreen` 中添加 `didChangeDependencies()` 方法，监听 provider 变化：

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // 监听 providers 变化，确保导入数据后立即刷新
  ref.listen(conversationsProvider, (previous, next) {
    if (next.hasValue) {
      _loadData();
    }
  });
  ref.listen(conversationGroupsProvider, (previous, next) {
    if (next.hasValue) {
      _loadData();
    }
  });
}
```

## 工作原理

1. 用户导入数据
2. `SettingsDataMixin.importData()` 保存数据到存储
3. 调用 `ref.invalidate(conversationsProvider)` 和 `ref.invalidate(conversationGroupsProvider)`
4. Provider 失效触发重新构建
5. `HomeScreen.didChangeDependencies()` 被调用
6. `ref.listen` 监听器检测到 provider 更新
7. 调用 `_loadData()` 重新加载对话列表
8. UI 立即更新显示导入的对话

## 修改文件

- `lib/features/chat/presentation/home_screen.dart`

## 测试验证

运行以下测试确认修复有效：
```bash
flutter analyze lib/features/chat/presentation/home_screen.dart
flutter test test/unit/conversation_creation_test.dart
```

## 注意事项

- 使用 `ref.listen` 而不是 `ref.watch`，避免不必要的重建
- 只在 `hasValue` 时调用 `_loadData()`，避免加载状态时的多次调用
- `didChangeDependencies()` 是合适的生命周期方法，因为它在依赖变化时被调用
