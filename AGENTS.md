# Repository Guidelines

This document provides guidelines for contributors working on the Flutter Chat App project, a cross-platform AI chat application similar to Cherry Studio.

## Project Structure & Module Organization

The project follows a feature-first architecture:

```
lib/
├── core/              # Shared utilities, network, storage
│   ├── network/       # API clients and HTTP configuration
│   ├── storage/       # Local database and persistence
│   ├── utils/         # Helper functions and extensions
│   └── constants/     # App-wide constants and enums
├── features/          # Feature modules (chat, settings, models)
│   └── [feature]/
│       ├── data/      # Data sources, repositories
│       ├── domain/    # Business logic, entities
│       └── presentation/ # UI, widgets, state management
├── shared/            # Reusable UI components and themes
│   ├── widgets/       # Common widgets
│   └── themes/        # Theme configuration
└── main.dart          # App entry point
```

Tests mirror the `lib/` structure in `test/` directory.

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
  brew install --cask android-studio  # If targeting Android
  ```
- Run `flutter doctor` to verify installation
- Always test compilation before committing:
  ```bash
  flutter analyze          # Check for errors
  flutter build macos      # Test macOS build
  flutter build web        # Test web build
  ```
- Fix any compilation errors before committing changes
- If tests exist, run `flutter test` to ensure they pass
