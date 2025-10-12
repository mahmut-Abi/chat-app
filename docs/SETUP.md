# Setup Guide

This guide will help you set up and run the Chat App on your machine.

## Prerequisites

### Required

1. **Flutter SDK** (version 3.0.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Dart SDK** (version 3.0.0 or higher)
   - Comes bundled with Flutter

3. **Git**
   - For version control

### Platform-Specific Requirements

#### For Web Development
- Chrome browser

#### For macOS Development
- Xcode (latest version)
- CocoaPods: `sudo gem install cocoapods`

#### For Windows Development
- Visual Studio 2022 with C++ development tools

#### For Linux Development
- Development packages:
  ```bash
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
  ```

#### For iOS Development
- macOS with Xcode
- iOS Simulator or physical device

#### For Android Development
- Android Studio
- Android SDK
- Android device or emulator

## Step-by-Step Setup

### 1. Verify Flutter Installation

```bash
flutter doctor
```

This command checks your environment and displays a report. Resolve any issues it identifies.

### 2. Clone the Repository

```bash
git clone <repository-url>
cd chat-app
```

### 3. Install Dependencies

```bash
flutter pub get
```

This will install all the required Flutter packages defined in `pubspec.yaml`.

### 4. Generate Code

The project uses code generation for Freezed and JSON serialization:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This command generates:
- `.freezed.dart` files for immutable data classes
- `.g.dart` files for JSON serialization

**Note**: Run this command whenever you modify files with `@freezed` or `@JsonSerializable` annotations.

### 5. Run the App

#### Option A: Using the Script (Unix/Linux/macOS)

```bash
./build_and_run.sh
```

This interactive script will guide you through building and running on different platforms.

#### Option B: Manual Commands

**Web:**
```bash
flutter run -d chrome
```

**macOS:**
```bash
flutter run -d macos
```

**Windows:**
```bash
flutter run -d windows
```

**Linux:**
```bash
flutter run -d linux
```

**Mobile (connected device):**
```bash
flutter run
```

## First-Time Configuration

### Adding Your First API Configuration

1. **Launch the app**

2. **Navigate to Settings**
   - Click the gear icon in the sidebar

3. **Add API Configuration**
   - Click "Add API Configuration"
   - Fill in the form:
     - **Name**: e.g., "My OpenAI"
     - **Provider**: Select "OpenAI"
     - **Base URL**: `https://api.openai.com/v1`
     - **API Key**: Your OpenAI API key
   - Click "Add"

4. **Start Chatting**
   - Go back to the home screen
   - Click "New Chat"
   - Start your conversation!

### Getting an OpenAI API Key

1. Visit https://platform.openai.com/
2. Sign up or log in
3. Navigate to API keys section
4. Create a new API key
5. Copy and use it in the app

**Important**: Keep your API key secure and never commit it to version control.

## Development Workflow

### Hot Reload

While the app is running, you can make changes to the code and see them instantly:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Code Generation Workflow

1. Make changes to files with `@freezed` or `@JsonSerializable`
2. Run code generation:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
3. Hot reload or restart the app

### Continuous Code Generation (Watch Mode)

For active development, use watch mode:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

This will automatically regenerate code whenever you save changes.

## Testing

### Run All Tests

```bash
flutter test
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

### View Coverage Report

After generating coverage:

```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Code Quality

### Format Code

```bash
flutter format .
```

### Run Static Analysis

```bash
flutter analyze
```

### Fix Common Issues

```bash
dart fix --apply
```

## Troubleshooting

### Issue: "Freezed files not found"

**Solution**: Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: "Package not found" errors

**Solution**: Clean and reinstall dependencies:
```bash
flutter clean
flutter pub get
```

### Issue: Platform-specific build errors

**Solution**: Ensure platform tools are installed:
```bash
flutter doctor
```

Follow the instructions for any missing requirements.

### Issue: "API connection failed"

**Causes**:
1. Invalid API key
2. Wrong base URL
3. Network issues
4. Rate limiting

**Solution**:
- Verify API key in Settings
- Check internet connection
- Ensure base URL is correct
- Wait if rate limited

### Issue: Storage errors

**Solution**: Clear app data:
- The app stores data locally using Hive
- On desktop/web: data is in app documents directory
- Use "Clear All Data" in Settings to reset

## Building for Production

### Web

```bash
flutter build web
```

Output: `build/web/`

### macOS

```bash
flutter build macos
```

Output: `build/macos/Build/Products/Release/`

### Windows

```bash
flutter build windows
```

Output: `build/windows/runner/Release/`

### Linux

```bash
flutter build linux
```

Output: `build/linux/x64/release/bundle/`

### iOS

```bash
flutter build ios
```

### Android

```bash
flutter build apk
# or for app bundle
flutter build appbundle
```

## Next Steps

- Read the [README.md](README.md) for feature overview
- Check [AGENTS.md](AGENTS.md) for contribution guidelines
- Review [todo.md](todo.md) for the project roadmap
- Start coding and have fun!

## Need Help?

- Check the [Flutter documentation](https://flutter.dev/docs)
- Review [Riverpod documentation](https://riverpod.dev)
- Open an issue on GitHub
- Read the troubleshooting section above
