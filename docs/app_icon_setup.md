# 应用程序图标设置指南

## 图标设计

我已为你创建了一个简约现代的 AI 聊天应用图标：

**设计元素：**
- 🌈 渐变背景：从靛蓝色 (#6366F1) 到紫色 (#8B5CF6)
- 💬 气泡对话框：两个白色圆角矩形，代表聊天界面
- ✨ AI 闪电标志：在大气泡中，象征 AI 功能
- ••• 输入指示器：在小气泡中，代表正在输入

## 生成图标步骤

### 步骤 1: 将 SVG 转换为 PNG

SVG 文件位于：`assets/icons/app_icon.svg`

**方法 A: 使用在线工具**
1. 访问 [CloudConvert](https://cloudconvert.com/svg-to-png) 或 [Convertio](https://convertio.co/svg-png/)
2. 上传 `assets/icons/app_icon.svg`
3. 设置宽度/高度为 1024x1024
4. 转换并下载为 `app_icon.png`
5. 将 `app_icon.png` 移动到 `assets/icons/` 目录

**方法 B: 使用 macOS 自带工具**
```bash
qlmanage -t -s 1024 -o assets/icons assets/icons/app_icon.svg
mv assets/icons/app_icon.svg.png assets/icons/app_icon.png
```

**方法 C: 使用 ImageMagick/Inkscape**
```bash
# 安装 ImageMagick
brew install imagemagick

# 转换
convert -background none -size 1024x1024 assets/icons/app_icon.svg assets/icons/app_icon.png
```

### 步骤 2: 生成 Adaptive Icon Foreground

为 Android Adaptive Icons 创建前景图像：

```bash
# 复制同一图标但去除背景
cp assets/icons/app_icon.png assets/icons/app_icon_foreground.png
```

### 步骤 3: 安装图标生成器

```bash
flutter pub get
```

### 步骤 4: 生成所有平台图标

```bash
flutter pub run flutter_launcher_icons
```

这会自动为以下平台生成图标：
- ✅ Android (mipmap)
- ✅ iOS (AppIcon.appiconset)
- ✅ Web (icons/)
- ✅ macOS (AppIcon.appiconset)
- ✅ Windows (app_icon.ico)

## 验证图标

### Android
```bash
flutter build apk
# 查看 android/app/src/main/res/mipmap-*/ic_launcher.png
```

### iOS
```bash
flutter build ios --no-codesign
# 查看 ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

### Web
```bash
flutter build web
# 查看 web/icons/
```

### macOS
```bash
flutter build macos
# 查看 macos/Runner/Assets.xcassets/AppIcon.appiconset/
```

### Windows
```bash
flutter build windows
# 查看 windows/runner/resources/app_icon.ico
```

## 注意事项

1. **图标尺寸**：源文件应该至少 1024x1024 像素
2. **透明背景**：Android Adaptive Icons 需要带透明背景的前景图
3. **颜色配置**：背景色已设置为 `#6366F1`，与图标渐变色匹配
4. **清理缓存**：如果图标未更新，尝试：
   ```bash
   flutter clean
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

## 图标预览

你可以在以下位置预览 SVG 图标：
- 浏览器中打开 `assets/icons/app_icon.svg`
- 使用 VS Code 的 SVG 预览插件
- 使用在线 SVG 查看器

