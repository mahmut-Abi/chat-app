# CI/CD 故障排查指南

本文档记录了项目 CI/CD 过程中的常见问题和解决方案。

## GitHub Actions 构建失败

### 问题 1: Flutter 版本无法找到 (arm64 架构)

**错误信息:**
```
Unable to determine Flutter version for channel: stable version: 3.35.6 architecture: arm64
Error: Process completed with exit code 1
```

**原因分析:**
- Flutter 某些版本的发布可能只包含特定架构
- 例如 Flutter 3.35.6 只有 x86_64 架构,没有 arm64 架构
- GitHub Actions 的 macOS runner 使用 arm64 (Apple Silicon)
- subosito/flutter-action 无法找到匹配的版本

**解决方案:**

#### 方案 1: 使用支持所有架构的版本

检查 Flutter 发布列表,选择同时支持 x64 和 arm64 的版本:

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.35.5'  # 支持 x86_64 和 arm64
    channel: 'stable'
    cache: true
```

#### 方案 2: 不指定版本,使用最新稳定版 (推荐)

移除 `flutter-version` 参数,让 action 自动使用最新稳定版:

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    channel: 'stable'
    cache: true
```

**优势:**
- 自动获取最新的稳定版本
- 避免架构兼容性问题
- 保持 CI 环境始终使用最新特性和修复

**注意事项:**
- 如果项目依赖特定 Flutter 版本特性,需要在 `pubspec.yaml` 中声明 SDK 版本约束
- 建议在本地使用与 CI 相同的 Flutter 版本进行测试

### 问题 2: Android 构建命令不存在

**错误信息:**
```
Run flutter build android --release
Could not find an option named "--release".
Error: Process completed with exit code 64
```

**原因分析:**
- `flutter build android` 不是有效的构建命令
- Flutter 需要使用具体的构建目标,如 `apk`、`appbundle` 或 `aar`

**解决方案:**

使用正确的 Android 构建命令:

```yaml
# 构建 APK 文件
- name: Build Android APK
  run: flutter build apk --release

# 或构建 App Bundle (推荐用于 Play Store)
- name: Build Android App Bundle
  run: flutter build appbundle --release
```

**可用的 Android 构建选项:**
- `flutter build apk` - 构建 APK 文件
- `flutter build appbundle` - 构建 App Bundle
- `flutter build aar` - 构建 Android 库

**最佳实践:**
- 对于 Google Play Store 发布,使用 `appbundle`
- 对于直接分发,使用 `apk`
- 使用 `--split-per-abi` 可以减小 APK 大小

### 问题 3: 代码格式检查失败

**错误信息:**
```
The following files need to be formatted:
  - lib/features/chat/presentation/chat_screen.dart
```

**解决方案:**

在提交前运行格式化:
```bash
flutter format .
```

或在 Git hooks 中自动格式化:
```bash
# .git/hooks/pre-commit
#!/bin/sh
flutter format .
```

### 问题 4: 构建超时

**症状:**
- GitHub Actions 运行时间过长
- 构建任务长时间无响应

**常见原因和解决方案:**

1. **依赖下载失败**
   - 检查网络连接
   - 使用 `cache: true` 缓存 Flutter SDK
   - 考虑使用依赖镜像源

2. **代码生成死锁**
   - 检查 `build_runner` 配置
   - 使用 `--delete-conflicting-outputs` 参数

3. **测试死锁**
   - 为测试添加超时限制
   - 检查异步代码是否正确处理

## 最佳实践

### 1. 本地验证

在提交前运行完整的 CI 检查:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter format --set-exit-if-changed .
flutter test --coverage
```

### 2. 缓存策略

- 启用 Flutter SDK 缓存
- 启用依赖包缓存
- 定期清理过期缓存

### 3. 并行执行

- 使用 matrix 策略并行运行多个平台的测试
- 设置 `fail-fast: false` 查看所有平台的结果

### 4. 监控和告警

- 配置 GitHub Actions 通知
- 监控构建时间趋势
- 及时处理失败的构建

## Flutter 构建命令参考

### 移动平台

```bash
# Android
flutter build apk --release                    # 构建 APK
flutter build appbundle --release              # 构建 App Bundle
flutter build apk --split-per-abi              # 按 ABI 分割 APK

# iOS
flutter build ios --release                    # 构建 iOS 应用
flutter build ipa --release                    # 构建 IPA 文件
flutter build ios --release --no-codesign      # 构建但不签名
```

### 桌面平台

```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

### Web

```bash
flutter build web --release
flutter build web --release --web-renderer canvaskit  # 使用 CanvasKit
flutter build web --release --web-renderer html       # 使用 HTML
```

## 相关资源

- [Flutter 官方发布列表](https://flutter.dev/docs/development/tools/sdk/releases)
- [Flutter 构建命令文档](https://docs.flutter.dev/deployment/android)
- [subosito/flutter-action 文档](https://github.com/subosito/flutter-action)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

## 更新日志

- 2025-01-XX: 修复 Flutter 3.35.6 arm64 架构兼容性问题
- 2025-01-XX: 修复 Android 构建命令错误 (android -> apk)
- 2025-01-XX: 添加 CI/CD 故障排查文档和构建命令参考
