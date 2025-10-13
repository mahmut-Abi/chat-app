# 平台支持文档

## 概述

本项目现已支持以下平台：

- ✅ **Web** - 完全支持
- ✅ **macOS** - 完全支持
- ✅ **iOS** - 完全支持 (iOS 12.0+)
- ✅ **Android** - 完全支持 (Android 5.0+, API 21+)
- ✅ **Windows** - 桌面支持
- ✅ **Linux** - 桌面支持

## 平台配置历史

### 2024-01-13: 添加 Linux 和 Windows 平台支持

**问题**
- GitHub Actions 在 Linux 和 Windows 平台编译失败
- 错误信息：`No Linux desktop project configured`

**解决方案**
使用 Flutter 命令为项目添加 Linux 和 Windows 桌面平台支持：

```bash
flutter create --org=com.aichat --platforms=linux,windows .
```

**生成的文件**

Linux 平台：
- `linux/CMakeLists.txt` - 主构建配置
- `linux/flutter/CMakeLists.txt` - Flutter 引擎配置
- `linux/flutter/generated_plugin_registrant.cc/h` - 插件注册
- `linux/flutter/generated_plugins.cmake` - 插件列表
- `linux/runner/` - 应用入口和窗口管理

Windows 平台：
- `windows/CMakeLists.txt` - 主构建配置
- `windows/flutter/CMakeLists.txt` - Flutter 引擎配置
- `windows/flutter/generated_plugin_registrant.cc/h` - 插件注册
- `windows/flutter/generated_plugins.cmake` - 插件列表
- `windows/runner/` - 应用入口、窗口管理和资源文件

## 各平台构建命令

### macOS
```bash
flutter build macos --release
```

### iOS
```bash
flutter build ios --release --no-codesign  # CI 环境
flutter build ios --release                # 真机部署
```

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### Windows
```bash
flutter build windows --release
```

### Linux
```bash
flutter build linux --release
```

**Linux 依赖项（Ubuntu/Debian）**
```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
```

### Web
```bash
flutter build web --release
```

## 插件平台支持

项目中使用的主要插件及其平台支持：

| 插件 | Web | macOS | iOS | Android | Windows | Linux |
|-----|-----|-------|-----|---------|---------|-------|
| dio | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| riverpod | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| go_router | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| shared_preferences | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| flutter_secure_storage | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| window_manager | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| tray_manager | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| screen_retriever | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| share_plus | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| url_launcher | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| printing | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## CI/CD 配置

GitHub Actions 工作流配置在 `.github/workflows/flutter_test.yml`：

- **测试作业**：在 Ubuntu、macOS 和 Windows 上运行测试
- **构建作业**：为所有支持的平台构建应用

### Linux 构建配置

```yaml
- name: Install Linux dependencies
  if: matrix.platform == 'linux'
  run: |
    sudo apt-get update
    sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
```

## 注意事项

### Windows
- 需要 Visual Studio 2019 或更高版本（包含 C++ 桌面开发工作负载）
- 某些插件可能需要额外配置

### Linux
- 需要安装 GTK 3 开发库
- 某些发行版可能需要额外的依赖项

### iOS
- 需要 macOS 主机
- 需要 Xcode 和 Apple Developer 账号（真机部署）
- CocoaPods 用于依赖管理

### Android
- minSdkVersion: 21 (Android 5.0)
- targetSdkVersion: 34 (Android 14)
- 需要配置签名密钥用于发布版本

## 故障排除

### 问题：Linux 编译失败，提示缺少依赖
**解决方案**：安装所有必需的开发库
```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

### 问题：Windows 编译失败
**解决方案**：确保安装了 Visual Studio 的 C++ 桌面开发工作负载

### 问题：插件不兼容某个平台
**解决方案**：
1. 检查插件文档了解平台支持情况
2. 使用条件导入或平台检查
3. 考虑使用替代插件或实现平台特定代码

## 参考链接

- [Flutter 桌面支持](https://docs.flutter.dev/desktop)
- [Flutter 移动端支持](https://docs.flutter.dev/get-started/install)
- [Flutter Web 支持](https://docs.flutter.dev/get-started/web)
