# 已知问题 (Known Issues)

## Flutter 3.35.6 / Dart 3.9.2 + freezed 3.2.3 编译问题

### 问题描述

在 Flutter 3.35.6 (Dart 3.9.2) 环境下使用 freezed 3.2.3 生成代码时，`flutter analyze` 可以通过，但 `flutter build` 编译时会出现以下错误：

```
Error: The non-abstract class 'XXX' is missing implementations for these members:
 - _$XXX.xxx
 - ...
```

### 原因

Dart 3.9.2 的编译器对 mixin 中的抽象 getter 检查更严格，而 freezed 生成的代码格式不符合新的编译器要求。

这是 freezed 项目的已知问题：https://github.com/rrousselGit/freezed/issues/1141

### 解决方案

#### 方案 1: 使用较旧版本 Flutter

降级到 Flutter 3.24.x 或更早的版本：

```bash
flutter downgrade 3.24.0
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 方案 2: 等待 freezed 更新

等待 freezed 项目修复该问题，预计在 freezed 3.3.x 中修复。

#### 方案 3: 手动修改生成代码（不推荐）

这不是一个好的解决方案，因为每次重新生成代码都需要重新修改。

### 当前状态

- `flutter analyze`: ✅ 通过
- `flutter run`: ❌ 失败
- `flutter build macos`: ❌ 失败
- `flutter build web`: ❌ 失败

### 更新日期

2025-01-12
