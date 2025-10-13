# 🎨 应用程序图标设置

## 图标设计

已为你创建了一个简约现代的 AI 聊天应用图标：

**设计特点：**
- 🌈 渐变背景：靛蓝色到紫色 (#6366F1 → #8B5CF6)
- 💬 聊天气泡：两个白色圆角矩形
- ✨ AI 闪电标志：象征 AI 功能
- ••• 输入指示器：代表正在输入

## 快速开始

### 1. 转换 SVG 为 PNG

**方法 A: 使用在线工具（推荐）**

1. 访问 [CloudConvert](https://cloudconvert.com/svg-to-png)
2. 上传 `assets/icons/app_icon.svg`
3. 设置输出大小为 **1024x1024**
4. 下载并保存为 `assets/icons/app_icon.png`
5. 复制一份为 `assets/icons/app_icon_foreground.png`

**方法 B: 使用 HTML 转换器**

```bash
open /tmp/convert_icon.html
# 等待浏览器自动下载 PNG 文件
# 将下载的文件移动到 assets/icons/
```

**方法 C: 使用 macOS 命令行**

```bash
# 安装 librsvg
brew install librsvg

# 转换
rsvg-convert -w 1024 -h 1024 assets/icons/app_icon.svg -o assets/icons/app_icon.png

# 复制为 foreground 图
cp assets/icons/app_icon.png assets/icons/app_icon_foreground.png
```

### 2. 生成所有平台图标

```bash
# 安装依赖
flutter pub get

# 生成图标
flutter pub run flutter_launcher_icons
```

这会自动生成：
- ✅ Android (mipmap-*/ic_launcher.png)
- ✅ iOS (AppIcon.appiconset)
- ✅ Web (web/icons/)
- ✅ macOS (macos/Runner/Assets.xcassets/)
- ✅ Windows (windows/runner/resources/app_icon.ico)

### 3. 验证图标

```bash
# Android
flutter build apk

# iOS  
flutter build ios --no-codesign

# Web
flutter build web

# macOS
flutter build macos

# Windows
flutter build windows
```

## 文件结构

```
assets/icons/
├── app_icon.svg              # 源 SVG 文件
├── app_icon.png              # 1024x1024 PNG (需要生成)
└── app_icon_foreground.png   # Android Adaptive Icon (需要生成)
```

## 注意事项

1. 确保 PNG 文件分辨率为 1024x1024
2. Android Adaptive Icons 需要 foreground 图像
3. 背景色已设置为 `#6366F1`
4. 如果图标未更新，运行 `flutter clean` 后重试

## 详细文档

查看 `docs/app_icon_setup.md` 获取更多信息。

