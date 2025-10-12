# GitHub Actions CI/CD 配置说明

本文档说明 Chat App 项目的 GitHub Actions 工作流配置。

## 工作流概述

项目使用 GitHub Actions 进行持续集成(CI)和构建,主要包含两个工作流任务:

1. **Test**: 在多个操作系统上运行测试和代码质量检查
2. **Build**: 为不同平台构建应用程序

## 触发条件

工作流在以下情况下自动触发:

- 推送到 `main` 或 `develop` 分支
- 对 `main` 或 `develop` 分支的 Pull Request

## Test 工作流

### 测试矩阵

在以下操作系统上运行测试:
- Ubuntu (latest)
- macOS (latest)
- Windows (latest)

### 执行步骤

1. **检出代码**: 使用 `actions/checkout@v4`
2. **设置 Flutter**: 使用 `subosito/flutter-action@v2`
   - Flutter 版本: 3.24.0
   - 渠道: stable
   - 启用缓存
3. **获取依赖**: `flutter pub get`
4. **运行代码生成**: `flutter pub run build_runner build --delete-conflicting-outputs`
5. **代码分析**: `flutter analyze`
6. **格式检查**: `flutter format --set-exit-if-changed .`
7. **运行测试**: `flutter test --coverage`
8. **上传覆盖率**: 仅在 Ubuntu 上将覆盖率数据上传至 Codecov

### 代码质量要求

- 所有代码必须通过 `flutter analyze` 检查
- 所有代码必须符合 Dart 格式规范
- 所有单元测试必须通过

## Build 工作流

### 构建矩阵

为以下平台构建应用:

| 平台 | 运行环境 | 输出位置 |
|------|----------|----------|
| Web | ubuntu-latest | build/web/** |
| macOS | macos-latest | build/macos/** |
| Windows | windows-latest | build/windows/** |
| Linux | ubuntu-latest | build/linux/** |
| Android | ubuntu-latest | build/app/outputs/** |

## 配置文件位置

工作流配置文件位于: `.github/workflows/flutter_test.yml`

## 相关资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter CI/CD 最佳实践](https://docs.flutter.dev/deployment/cd)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
