# BUG-004: storage_service.dart 未使用的 stack 变量

## 问题描述
`lib/core/storage/storage_service.dart` 中 `clearAll()` 方法捕获了 `stack` 参数但未使用。

## 错误信息
```
warning • The stack trace variable 'stack' isn't used and can be removed • lib/core/storage/storage_service.dart:247:17 • unused_catch_stack
```

## 根本原因
`clearAll()` 方法的错误处理中捕获了 `stack` 但没有使用它。

## 修复方案
保留在 `init()` 方法中需要的 `stack` 参数，从 `clearAll()` 移除不需要的 `stack` 参数。

## 修复内容
- `clearAll()` 方法中：`catch (e, stack)` → `catch (e)`
- 保留 `init()` 方法中的 `catch (e, stack)` 因为它被使用

## 验证
```bash
flutter analyze lib/core/storage/storage_service.dart
```

## 状态
✅ 已修复
