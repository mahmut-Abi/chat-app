# GitHub Actions 编译产物配置

本文档说明了 GitHub Actions CI/CD 流水线中编译产物的配置方式。

## 概述

为了优化存储空间和下载速度,我们的 GitHub Actions workflow 已配置为仅保留最终的二进制文件或安装包,而不是整个构建目录。

## 产物格式

每个平台的编译产物格式如下:

### Web
- **文件名**: `chat-app-web-wasm.zip`
- **内容**: 完整的 Web 部署文件(HTML、JS、CSS、资源文件)
- **用途**: 可直接解压并部署到 Web 服务器

### macOS
- **文件名**: `chat-app-macos-{arch}.zip` (arch: x64 或 arm64)
- **内容**: `chat_app.app` 应用程序包
- **用途**: 解压后可直接在 macOS 上运行

### Windows
- **文件名**: `chat-app-windows-x64.zip`
- **内容**: 可执行文件及其依赖的 DLL 文件
- **用途**: 解压后运行 `chat_app.exe`

### Linux
- **文件名**: `chat-app-linux-x64.tar.gz`
- **内容**: 完整的应用程序 bundle(可执行文件、库文件、资源)
- **用途**: 解压后运行可执行文件

### Android
- **文件名**: 
  - `chat-app-android-arm64-v8a.apk` (APK 安装包)
  - `chat-app-android-arm64-v8a.aab` (如果生成了 AAB)
- **内容**: 可安装的 Android 应用包
- **用途**: 直接安装到 Android 设备或发布到 Google Play

### iOS
- **文件名**: `chat-app-ios-arm64.zip`
- **内容**: `Runner.app` 应用程序(未签名)
- **用途**: 需要通过 Xcode 签名后才能安装到设备
- **注意**: GitHub Actions 构建的 iOS 应用未签名,仅用于测试验证

## 下载产物

### 从 GitHub Actions

1. 进入项目的 GitHub 页面
2. 点击 "Actions" 标签
3. 选择对应的 workflow 运行
4. 在页面底部的 "Artifacts" 部分下载所需的产物

### 产物命名规则

Artifact 名称格式: `{platform}-{arch}-build`

例如:
- `web-wasm-build`
- `macos-x64-build`
- `macos-arm64-build`
- `windows-x64-build`
- `linux-x64-build`
- `apk-arm64-v8a-build`
- `ios-arm64-build`

## 保留策略

- **保留时间**: 7 天
- **压缩级别**: 0 (已预压缩,无需二次压缩)

## 技术细节

### 产物准备流程

每个平台有独立的 "Prepare artifacts" 步骤:

1. **创建 artifacts 目录**
2. **将构建产物打包**:
   - Web/macOS/iOS: 使用 `zip` 命令
   - Windows: 使用 PowerShell `Compress-Archive`
   - Linux: 使用 `tar -czf` 创建 gzip 压缩包
   - Android: 直接复制 APK/AAB 文件
3. **上传到 GitHub Actions Artifacts**

### 为什么设置 compression-level: 0?

因为我们的产物已经是压缩格式(zip/tar.gz),GitHub Actions 的额外压缩:
- 不会显著减少文件大小
- 会增加上传和下载时间
- 会浪费 CPU 资源

设置为 0 可以跳过二次压缩,直接上传。

## 与之前的区别

### 之前的配置

```yaml
path: |
  build/web/**
  build/macos/**
  build/windows/**
  build/linux/**
  build/app/outputs/**
  build/ios/**
```

**问题**:
- 上传了整个构建目录,包含大量中间文件
- 产物体积大,下载和存储成本高
- 包含不必要的调试文件和符号表

### 当前的配置

```yaml
path: artifacts/*
compression-level: 0
```

**优势**:
- 只保留最终可用的二进制/安装包
- 产物体积小,节省存储空间
- 下载速度快
- 清晰的文件命名,易于识别和使用

## 本地测试

如果需要在本地生成相同格式的产物,可以运行以下命令:

### Web
```bash
flutter build web --release
cd build/web
zip -r ../../chat-app-web-wasm.zip .
```

### macOS
```bash
flutter build macos --release
cd build/macos/Build/Products/Release
zip -r ../../../../chat-app-macos-$(uname -m).zip chat_app.app
```

### Windows (PowerShell)
```powershell
flutter build windows --release
Compress-Archive -Path build/windows/x64/runner/Release/* -DestinationPath chat-app-windows-x64.zip
```

### Linux
```bash
flutter build linux --release
cd build/linux/x64/release/bundle
tar -czf ../../../../chat-app-linux-x64.tar.gz .
```

### Android
```bash
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk chat-app-android-arm64-v8a.apk
```

### iOS
```bash
flutter build ios --release --no-codesign
cd build/ios/Release-iphoneos
zip -r ../../../chat-app-ios-arm64.zip Runner.app
```

## 故障排查

### 产物未生成

检查 workflow 日志中的 "List artifacts" 步骤,确认 artifacts 目录是否创建成功。

### 文件路径错误

不同平台的构建产物路径可能因 Flutter 版本而异。如果遇到路径问题:

1. 在 GitHub Actions 日志中查看构建输出
2. 找到实际的构建产物路径
3. 更新 workflow 文件中的路径

### iOS 应用无法安装

iOS 应用需要签名才能安装。GitHub Actions 构建的 iOS 应用使用了 `--no-codesign` 参数,因此:

- 不能直接安装到物理设备
- 需要使用 Xcode 重新签名
- 或者在本地构建并签名

## 相关资源

- [GitHub Actions Artifacts 文档](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [Flutter 构建文档](https://docs.flutter.dev/deployment)
- [项目 AGENTS.md](../AGENTS.md)
