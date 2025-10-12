# iOS 构建说明

## 当前问题

### Xcode 26.0 兼容性问题

在 Xcode 26.0 环境下构建 iOS 应用时，可能遇到以下错误：

```
Uncategorized (Xcode): Unable to find a destination matching the provided destination specifier
{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device, error:iOS 26.0 is not installed. }
```

这是 Xcode 26.0 和 Flutter 之间的一个已知问题。

## 解决方案

### 方案 1: 在 Xcode 中安装 iOS 26.0 模拟器运行时

1. 打开 Xcode
2. 进入 **Xcode > Settings > Components**
3. 找到 **iOS 26.0 Simulator**
4. 点击 **GET** 按钮下载并安装

### 方案 2: 降级 Xcode 版本

如果方案 1 不可行，可以考虑降级到 Xcode 15.x 或 Xcode 16.x：

```bash
# 查看已安装的 Xcode 版本
xcodebuild -version

# 切换到其他 Xcode 版本（如果已安装）
sudo xcode-select -s /Applications/Xcode_15.app/Contents/Developer
```

### 方案 3: 使用物理设备

如果有 iPhone 设备，可以直接连接设备进行调试：

```bash
# 查看连接的设备
flutter devices

# 在物理设备上运行
flutter run -d <device-id>
```

## 项目配置

### iOS 最低版本

项目配置的最低 iOS 版本为 **iOS 13.0**，可以在以下文件中查看：

- `ios/Podfile`: platform :ios, '13.0'
- `ios/Flutter/AppFrameworkInfo.plist`: MinimumOSVersion = 13.0
- `ios/Runner.xcodeproj/project.pbxproj`: IPHONEOS_DEPLOYMENT_TARGET = 13.0

### Bundle ID

当前配置的 Bundle ID: `com.example.chatApp`

如需修改，在 Xcode 中打开 `ios/Runner.xcworkspace` 并在项目设置中修改。

## 构建验证

由于 Xcode 26.0 兼容性问题，目前无法在本地环境上直接构建 iOS 应用。但以下工作已经完成：

- ✅ iOS 项目结构存在
- ✅ CocoaPods 依赖已安装
- ✅ Flutter 插件配置正确
- ✅ 所有 Dart 代码通过编译检查
- ✅ 核心功能（HTTP 代理）已实现

## GitHub Actions CI/CD

GitHub Actions 工作流中不包含 iOS 构建，因为：

1. iOS 构建需要 macOS runner
2. 需要配置签名证书和 Provisioning Profile
3. GitHub Actions 的 macOS runner 有较高的成本

如需添加 iOS CI/CD 支持，可以参考以下配置：

```yaml
ios:
  name: Build iOS
  runs-on: macos-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: |
        flutter pub get
        cd ios && pod install
    
    - name: Build iOS
      run: flutter build ios --release --no-codesign
```

## 相关资源

- [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)
- [Xcode 下载](https://developer.apple.com/xcode/)
- [CocoaPods 文档](https://guides.cocoapods.org/)
