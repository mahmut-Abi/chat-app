# Repository Guidelines

This document provides guidelines for contributors working on the Flutter Chat App project, a cross-platform AI chat application similar to Cherry Studio.

## Project Structure & Module Organization

The project follows a **Feature-First + Clean Architecture** approach. For detailed information about the project structure, please refer to:

**📖 [项目结构说明文档 (docs/project-structure.md)](docs/project-structure.md)**

### Quick Overview

```
lib/
├── core/              # 核心功能层：网络、存储、服务、工具
│   ├── network/       # API 客户端和 HTTP 配置
│   ├── storage/       # 本地数据持久化
│   ├── services/      # 系统级服务
│   ├── utils/         # 通用工具类
│   ├── providers/     # 全局 Provider
│   ├── routing/       # 路由配置
│   ├── constants/     # 应用常量
│   └── error/         # 错误处理
├── features/          # 功能模块层：按业务功能组织
│   └── [feature]/
│       ├── data/      # 数据层：Repository、数据源
│       ├── domain/    # 领域层：数据模型、业务实体
│       └── presentation/ # 表现层：UI、Widgets、状态管理
├── shared/            # 共享组件层：可复用的 UI 组件和主题
│   ├── widgets/       # 通用组件
│   ├── themes/        # 主题配置
│   └── utils/         # 共享工具
└── main.dart          # 应用入口
```

**功能模块**:
- `chat/` - 聊天功能（对话管理、消息发送、流式响应）
- `agent/` - Agent 系统（Agent 管理、工具集成）
- `mcp/` - MCP 集成（服务器管理、工具调用）
- `models/` - 模型管理
- `prompts/` - 提示词模板
- `settings/` - 应用设置
- `token_usage/` - Token 统计
- `logs/` - 日志查看

Tests mirror the `lib/` structure in `test/` directory.

**重要文档**:
- [项目结构详解](docs/project-structure.md) - 完整的目录结构和模块说明
- [架构文档](docs/architecture.md) - 架构设计详细说明
- [MCP 集成指南](docs/mcp-integration.md) - MCP 协议集成说明

## Build, Test, and Development Commands

**Setup and Dependencies**
```bash
flutter pub get                    # Install dependencies
flutter pub run build_runner build # Generate code (freezed, json_serializable)
```

**Running the App**
```bash
flutter run -d chrome              # Run on web
flutter run -d macos               # Run on desktop
flutter run                        # Run on connected device
```

**Testing**
```bash
flutter test                       # Run all unit tests
flutter test --coverage            # Run tests with coverage
```

**Code Quality**
```bash
flutter analyze                    # Run static analysis
flutter format .                   # Format all Dart files
```

## Coding Style & Naming Conventions

**Formatting**
- Use 2-space indentation
- Follow official Dart style guide
- Run `flutter format .` before committing
- Maximum line length: 80 characters

**Naming Patterns**
- Files: `snake_case.dart` (e.g., `chat_message.dart`)
- Classes: `PascalCase` (e.g., `ChatMessage`)
- Variables/functions: `camelCase` (e.g., `sendMessage`)
- Constants: `lowerCamelCase` (e.g., `maxTokens`)
- Private members: prefix with `_` (e.g., `_apiClient`)

**Code Generation**
- Use `freezed` for immutable data classes
- Use `json_serializable` for JSON serialization
- Always run `build_runner` after modifying generated files

## Testing Guidelines

**Framework**: Flutter's built-in testing framework with `mockito` for mocking.

**Test Organization**
- Unit tests: `test/unit/`
- Widget tests: `test/widget/`
- Integration tests: `test/integration/`

**Naming Conventions**
- Test files: `*_test.dart` (e.g., `chat_repository_test.dart`)
- Test groups: Describe the class/function being tested
- Test cases: Use descriptive names starting with "should"

**Example**
```dart
group('ChatRepository', () {
  test('should fetch messages successfully', () {
    // Test implementation
  });
});
```

**Coverage Requirements**
- Aim for 80%+ coverage on business logic
- All API clients and repositories must have tests
- UI tests are optional but encouraged

## Commit & Pull Request Guidelines

**Commit Messages**
Follow conventional commits format:
```
type(scope): subject

Types: feat, fix, docs, style, refactor, test, chore
Example: feat(chat): add streaming response support
```

**Pull Request Requirements**
- Link related issues using `Closes #123` or `Fixes #456`
- Provide clear description of changes
- Include screenshots for UI changes
- Ensure all tests pass and code is formatted
- Request review from at least one maintainer
- Keep PRs focused and reasonably sized

**Git Commit Requirements**
- Every completed task MUST be committed with `git commit`
- Commit messages must be in Chinese (中文)
- Follow conventional commits format with Chinese descriptions
- Example: `feat(聊天): 添加流式响应支持`
- Types remain in English: feat, fix, docs, style, refactor, test, chore

**Branch Naming**
- Feature: `feature/description` (e.g., `feature/add-markdown-support`)
- Bug fix: `fix/description` (e.g., `fix/streaming-error`)
- Documentation: `docs/description`

## Security & Configuration

**API Keys**
- Never commit API keys or secrets
- Use `flutter_secure_storage` for sensitive data
- Store configuration in environment-specific files

**Dependencies**
- Review security advisories before adding dependencies
- Keep dependencies up to date
- Use `flutter pub outdated` regularly

## Language and Localization

**Communication Language**
- All agent/AI responses must be in Chinese (中文)
- Documentation files (README, CHANGELOG, etc.) should be written in Chinese
- Code comments should be in Chinese when added
- Commit messages must use Chinese descriptions
- Variable names, function names, and code itself remain in English

**Documentation File Organization**
- `AGENTS.md`, `README.md`, and `todo.md` should be placed in the project root directory
- All other newly generated markdown files must be placed in the `docs/` directory
- Examples of files that belong in `docs/`:
  - Architecture documentation (e.g., `docs/architecture.md`)
  - API documentation (e.g., `docs/api.md`)
  - Deployment guides (e.g., `docs/deployment.md`)
  - Feature specifications (e.g., `docs/features.md`)
- When creating new documentation, always place it in `docs/` unless it's one of the three exceptions above

**Example**:
```dart
// 发送聊天消息到服务器
Future<void> sendMessage(String content) async {
  // 实现代码
}
```

## Architecture Overview

**State Management**: Riverpod 2.x
- Use `Provider` for simple state
- Use `StateNotifierProvider` for complex state with business logic
- Keep providers in `providers/` within each feature module

**Navigation**: go_router
- Define routes in `lib/core/routing/app_router.dart`
- Use type-safe route parameters

**Data Flow**
```
UI → Provider → Repository → Data Source (API/DB) → Repository → Provider → UI
```

Keep business logic in repositories and domain layer, not in widgets.

## Development Environment Setup

**Local Build Requirements**
- Before completing any task, verify the project builds successfully
- Use `brew` to install Flutter and related dependencies on macOS:
  ```bash
  brew install flutter
  brew install cocoapods
  brew install --cask android-studio  # If targeting Android
  ```
- Run `flutter doctor` to verify installation
- For iOS development, install Xcode from App Store
- For Android development, configure Android SDK through Android Studio
- Always test compilation before committing:
  ```bash
  flutter analyze          # Check for errors
  flutter build macos      # Test macOS build
  flutter build web        # Test web build
  flutter build apk        # Test Android build (if targeting Android)
  flutter build ios        # Test iOS build (if targeting iOS)
  ```
- Fix any compilation errors before committing changes
- If tests exist, run `flutter test` to ensure they pass

## Common Issues and Solutions

**颜色值转换**
- 使用 `Color.toARGB32()` 而不是已废弃的 `.value`
- 例：`color.toARGB32().toRadixString(16)`

**类结构**
- 确保所有方法都在类内部
- 检查大括号匹配，避免过早关闭类

**PDF 生成**
- `pw.BorderRadius` 不能使用 `const`
- 使用 `pw.BorderRadius.all(pw.Radius.circular(5))` 而不是 `const pw.BorderRadius.all(...)`

**Trailing Commas**
- 在多行参数列表中始终添加末尾逗号
- 例：`DropdownMenuItem(...),` 而不是 `DropdownMenuItem(...))`

**DropdownButton 参数**
- 必须提供 `value` 参数，不能使用 `.r` 等错误语法
- 正确：`value: _selectedColor`
- 错误：`.r: _selectedColor`

## Mobile Platform Configuration

**Android 配置**
- 应用 ID: `com.aichat.app`
- minSdkVersion: 21 (Android 5.0)
- 必须权限: INTERNET, ACCESS_NETWORK_STATE
- 文件访问: READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE (API 32 及以下)

**iOS 配置**
- Bundle ID: 需要在 Xcode 中配置
- 最低支持: iOS 12.0
- 权限描述: 相册、相机、麦克风（为未来功能预留）

**平台特定注意事项**
- Android 需要配置签名证书用于发布版本
- iOS 需要 Apple Developer 账号用于真机调试和发布
- 所有平台均已配置必要的权限和设置

## Git Hooks

本项目配置了 Git pre-commit hook，会在每次提交前自动运行代码格式和质量检查。

### 安装 Hooks

新克隆项目后，需要运行以下命令安装 hooks：

```bash
./scripts/setup-hooks.sh
```

### Hook 行为

**1. Dart 代码格式检查**
- ✅ **允许提交**: 如果所有暂存的 Dart 文件都已格式化
- ❌ **阻止提交**: 如果有未格式化的 Dart 文件

**2. Flutter Analyze 代码质量检查**
- ✅ **允许提交**: 如果只有 warning 和 info 级别的问题  
- ❌ **阻止提交**: 如果存在 error 级别的问题  

### 跳过 Hook

如需跳过 hook 检查：

```bash
git commit --no-verify -m "commit message"
```

详细信息请查阅 `docs/git-hooks.md`
