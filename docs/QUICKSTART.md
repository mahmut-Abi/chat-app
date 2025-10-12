# Quick Start Guide

Get the Chat App running in 5 minutes!

## Prerequisites

- Flutter SDK (3.0.0+) installed
- An OpenAI API key (or compatible service)

## Setup Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code Files

⚠️ **REQUIRED** - Run this before first launch:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates necessary Freezed and JSON files.

### 3. Run the App

Choose your platform:

```bash
# Web
flutter run -d chrome

# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux  
flutter run -d linux
```

Or use the helper script:

```bash
./build_and_run.sh
```

## First-Time Configuration

### Add Your API Key

1. Click the **Settings** icon (gear) in the sidebar
2. Click **"Add API Configuration"**
3. Fill in:
   ```
   Name:     My OpenAI
   Provider: OpenAI
   Base URL: https://api.openai.com/v1
   API Key:  sk-your-key-here
   ```
4. Click **"Add"**

### Start Chatting

1. Click **"New Chat"** button
2. Type a message
3. Press Enter or click Send
4. Watch the AI respond in real-time!

## Alternative Providers

### Ollama (Local)

```
Provider: Ollama
Base URL: http://localhost:11434/v1
API Key: (leave empty)
```

### Azure OpenAI

```
Provider: Azure OpenAI
Base URL: https://YOUR-RESOURCE.openai.azure.com
API Key: your-azure-key
```

### Any Custom OpenAI-Compatible API

```
Provider: Custom
Base URL: your-api-url
API Key: your-key
```

## Troubleshooting

### Error: "Cannot find *.freezed.dart"

**Solution:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "Package not found"

**Solution:**
```bash
flutter clean
flutter pub get
```

### Error: "API connection failed"

**Check:**
- API key is correct
- Base URL is correct
- You have internet connection
- You're not rate-limited

## Common Commands

```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run on Web
flutter run -d chrome

# Run on Desktop
flutter run -d macos  # or windows, linux

# Run tests
flutter test

# Format code
flutter format .

# Analyze code
flutter analyze
```

## Features Available

✅ Real-time streaming chat  
✅ Multiple conversations  
✅ Conversation history  
✅ Rename/delete conversations  
✅ Multiple API providers  
✅ Secure API key storage  
✅ Light/dark themes  
✅ Cross-platform (Web/Desktop/Mobile)  

## Need More Help?

- **Detailed setup**: See [SETUP.md](SETUP.md)
- **Features**: See [README.md](README.md)
- **Contributing**: See [AGENTS.md](AGENTS.md)
- **Roadmap**: See [todo.md](todo.md)

## Next Steps

1. Try different models (when implemented)
2. Customize settings
3. Explore the codebase
4. Contribute improvements!

Happy chatting! 🚀
